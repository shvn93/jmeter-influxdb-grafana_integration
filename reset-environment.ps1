param([switch]$Confirm)
if (-not $Confirm) {
    Write-Host "This will REMOVE containers and DELETE influxdb_data and secrets.json. Rerun with -Confirm to proceed."
    exit 0
}
$projectDir = Join-Path -Path $PSScriptRoot -ChildPath "jmeter_monitoring"
docker rm -f influxdb grafana 2>$null
$dd = Join-Path $projectDir "influxdb_data"
$sf = Join-Path $projectDir "secrets.json"
if (Test-Path $dd) { Remove-Item -Recurse -Force $dd; Write-Host "Deleted $dd" }
if (Test-Path $sf) { Remove-Item -Force $sf; Write-Host "Deleted $sf" }
Write-Host "Reset complete."
