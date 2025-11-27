<#
setup-influx-grafana-autotoken.ps1
Corrected script: Run-Check accepts a named array parameter -DockerArgs to avoid array expansion issues.
Usage: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
       .\setup-influx-grafana-autotoken.ps1 --force
#>

param([switch]$Force)

function Log($m) { Write-Host "$(Get-Date -Format 'HH:mm:ss') - $m" }

$projectDir = Join-Path -Path $PSScriptRoot -ChildPath "jmeter_monitoring"
$grafanaProvisionDir = Join-Path $projectDir "grafana\provisioning"
$datasourceDir = Join-Path $grafanaProvisionDir "datasources"
$dashboardsDir = Join-Path $grafanaProvisionDir "dashboards\dashboards"
$secretsFile = Join-Path $projectDir "secrets.json"

New-Item -ItemType Directory -Force -Path $projectDir | Out-Null
New-Item -ItemType Directory -Force -Path $datasourceDir | Out-Null
New-Item -ItemType Directory -Force -Path $dashboardsDir | Out-Null

if (-Not (Test-Path $secretsFile)) {
    Log "Generating secrets.json with default values..."
    $token = ([guid]::NewGuid()).ToString("N")
    $obj = @{
        influx_token = $token
        influx_user = "jmeter_admin"
        influx_pass = "JMeter@123"
        influx_org  = "jmeter_org"
        influx_bucket = "jmeter_bucket"
        grafana_admin_password = "Grafana@123"
    }
    $obj | ConvertTo-Json | Out-File $secretsFile -Encoding utf8
} else {
    Log "Found existing secrets.json"
}

$obj = Get-Content $secretsFile | ConvertFrom-Json
$token = $obj.influx_token
$user = $obj.influx_user
$pass = $obj.influx_pass
$org  = $obj.influx_org
$bucket = $obj.influx_bucket
$grafPass = $obj.grafana_admin_password

$yml = @"
apiVersion: 1

datasources:
  - name: InfluxDB (jmeter)
    type: influxdb
    access: proxy
    url: http://influxdb:8086
    isDefault: true
    jsonData:
      defaultBucket: $bucket
      organization: $org
      httpMode: POST
      version: Flux
    secureJsonData:
      token: $token
"@

$dst = Join-Path $datasourceDir "influxdb.yml"
$yml | Out-File $dst -Encoding utf8
Log "Wrote datasource provisioning to: $dst"

function Run-Check {
    param(
        [Parameter(Mandatory=$true)]
        [string[]]$DockerArgs,

        [Parameter(Mandatory=$true)]
        [string]$Msg,

        [int]$Retries = 2
    )

    $cmd = "docker " + ($DockerArgs -join " ")
    for ($i=0; $i -le $Retries; $i++) {
        Write-Host "Running: $cmd"
        $output = & docker @DockerArgs 2>&1
        $exit = $LASTEXITCODE
        if ($exit -eq 0) {
            $output | ForEach-Object { Write-Host $_ }
            return $true
        } else {
            Write-Error "Attempt $($i+1) failed: $Msg"
            $output | ForEach-Object { Write-Error $_ }
            if ($i -lt $Retries) { Start-Sleep -Seconds (5 * ($i+1)); Write-Host "Retrying..." }
        }
    }
    throw $Msg
}

try { docker --version | Out-Null } catch { Write-Error "Docker CLI not available. Start Docker Desktop." ; exit 1 }

$net = "jmeter_monitoring_net"
if (-not (docker network ls --format "{{.Name}}" | Select-String $net)) {
    docker network create $net | Out-Null
    Log "Created docker network $net"
} else {
    Log "Docker network $net already exists"
}

if ($Force) {
    Log "Force mode: removing existing containers (if any)"
    docker rm -f influxdb grafana 2>$null | Out-Null
}

Run-Check -DockerArgs @("pull","influxdb:2.6") -Msg "Failed to pull InfluxDB image" -Retries 3
Run-Check -DockerArgs @("pull","grafana/grafana:latest") -Msg "Failed to pull Grafana image" -Retries 3

$dataDir = Join-Path $projectDir "influxdb_data"
New-Item -ItemType Directory -Force -Path $dataDir | Out-Null

if (docker ps -a --format "{{.Names}}" | Select-String -Pattern "^influxdb$") {
    if (-not $Force) { Write-Host "Container 'influxdb' exists; removing it to avoid conflicts"; docker rm -f influxdb | Out-Null }
}
if (docker ps -a --format "{{.Names}}" | Select-String -Pattern "^grafana$") {
    if (-not $Force) { Write-Host "Container 'grafana' exists; removing it to avoid conflicts"; docker rm -f grafana | Out-Null }
}

Run-Check -DockerArgs @(
    "run","-d",
    "--name","influxdb",
    "--network",$net,
    "-p","8086:8086",
    "-v","${dataDir}:/var/lib/influxdb2",
    "-e","DOCKER_INFLUXDB_INIT_MODE=setup",
    "-e","DOCKER_INFLUXDB_INIT_USERNAME=$user",
    "-e","DOCKER_INFLUXDB_INIT_PASSWORD=$pass",
    "-e","DOCKER_INFLUXDB_INIT_ORG=$org",
    "-e","DOCKER_INFLUXDB_INIT_BUCKET=$bucket",
    "-e","DOCKER_INFLUXDB_INIT_ADMIN_TOKEN=$token",
    "influxdb:2.6"
) -Msg "Failed to start InfluxDB container" -Retries 2

Run-Check -DockerArgs @(
    "run","-d",
    "--name","grafana",
    "--network",$net,
    "-p","3000:3000",
    "-v","${grafanaProvisionDir}:/etc/grafana/provisioning",
    "-e","GF_SECURITY_ADMIN_PASSWORD=$grafPass",
    "grafana/grafana:latest"
) -Msg "Failed to start Grafana container" -Retries 2

Log "Setup complete. Grafana: http://localhost:3000 (admin/$grafPass)"
Log "InfluxDB: http://localhost:8086"
