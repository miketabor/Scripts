# Finds all VM's within the cluster "Cluster1" that don't have "DB" or "SQL" in the name and upgrades
# VMware tools to the latest version and prevents Tools from causing a reboot.

Get-Cluster "Cluster1" | Get-VM | Where-Object {$_.Name -notlike "*DB*" -and $_.Name -notlike "*SQL*"} | Update-Tools -NoReboot
