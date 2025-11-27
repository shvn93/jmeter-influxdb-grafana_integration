# JMeter → InfluxDB → Grafana Setup Package

**What this repo contains**
- `setup-influx-grafana-autotoken.ps1` : PowerShell script that creates InfluxDB & Grafana Docker containers, generates an Influx token, and provisions Grafana datasource + dashboard.
- `run-setup.bat` : One-click launcher that runs the PowerShell script with temporary execution policy bypass.
- `reset-environment.ps1` : Stops/removes containers and deletes `influxdb_data` and `secrets.json`. Use `-Confirm` to perform deletion.
- `jmeter_monitoring/grafana/provisioning/...` : Grafana provisioning files (datasource & dashboard). The PS script overwrites the datasource token.
- `jmeter_monitoring/secrets.json.example` : Template for credentials/tokens (DO NOT commit real secrets).
- `jmeter_monitoring/influxdb_data/` : (Not committed; created at runtime) InfluxDB data directory.

## Prerequisites
- Windows 10/11 and PowerShell
- Docker Desktop installed and running
- Ports 3000 (Grafana) and 8086 (InfluxDB) must be free

## Quick start (clean install)
1. Clone or download this repo and `cd` into it.
2. (Optional) Reset previous state:
   ```powershell
   .\reset-environment.ps1 -Confirm
3. Run setup (recommended):
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\setup-influx-grafana-autotoken.ps1 --force
Or double-click run-setup.bat
4. Open Grafana at http://localhost:3000 (login admin / Grafana@123).
   The datasource InfluxDB (jmeter) and the JMeter dashboard are auto-provisioned.

