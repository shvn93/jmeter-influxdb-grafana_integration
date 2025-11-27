This package contains a corrected setup script that avoids PowerShell array expansion bugs when calling Docker.
Files:
- setup-influx-grafana-autotoken.ps1  : corrected setup script (Run-Check uses -DockerArgs)
- run-setup.bat                       : one-click launcher
- reset-environment.ps1               : reset script (use -Confirm)
- jmeter_monitoring/grafana/provisioning/...  : provisioning files (datasource/dashboard)
Quick start:
1) Extract ZIP to a folder.
2) (Optional) Delete old influxdb_data and secrets.json for a clean reset.
3) Run (PowerShell):
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\setup-influx-grafana-autotoken.ps1 --force
Or double-click run-setup.bat
