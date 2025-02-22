# cleanup.osdcloud
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Cleanup-Script.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Stop

Write-Host "Execute OSD Cloud Cleanup Script" -ForegroundColor Green

# Copying the OOBEDeploy and AutopilotOOBE Logs
Get-ChildItem 'C:\Windows\Temp' -Filter '*OOBE*' | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force -ErrorAction Stop

# Copying OSDCloud Logs
If (Test-Path -Path 'C:\OSDCloud\Logs') {
    Move-Item 'C:\OSDCloud\Logs\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force -ErrorAction Stop
}
Move-Item 'C:\ProgramData\OSDeploy\Logs\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force -ErrorAction Stop

# Copying additional logs
Get-ChildItem 'C:\Temp' -Filter '*OOBE*' | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force -ErrorAction SilentlyContinue
Get-ChildItem 'C:\Windows\Temp' -Filter '*Event*' | Copy-Item -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force -ErrorAction SilentlyContinue

# Cleanup directories
If (Test-Path -Path 'C:\OSDCloud') { Remove-Item -Path 'C:\OSDCloud' -Recurse -Force -ErrorAction Stop }
If (Test-Path -Path 'C:\Drivers') { Remove-Item 'C:\Drivers' -Recurse -Force -ErrorAction Stop }
If (Test-Path -Path 'C:\Temp') { Remove-Item 'C:\Temp' -Recurse -Force -ErrorAction SilentlyContinue }
Get-ChildItem 'C:\Windows\Temp' -Filter '*member*' | Remove-Item -Force -ErrorAction SilentlyContinue

Stop-Transcript