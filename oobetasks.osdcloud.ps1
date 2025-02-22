# oobetasks.osdcloud.ch
$scriptFolderPath = "$env:windir\Temp\OSDCloud\Scripts"
$ScriptPathOOBE = $(Join-Path -Path $scriptFolderPath -ChildPath "OOBE.ps1")
$ScriptPathSendKeys = $(Join-Path -Path $scriptFolderPath -ChildPath "SendKeys.ps1")

If(!(Test-Path -Path $scriptFolderPath)) {
    New-Item -Path $scriptFolderPath -ItemType Directory -Force | Out-Null
}

$OOBEScript =@"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OOBEScripts.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Installing AutopilotOOBE PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Install-Module AutopilotOOBE -Force -Verbose" -Wait

Write-Host -ForegroundColor DarkGray "Installing OSD PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Install-Module OSD -Force -Verbose" -Wait

Write-Host -ForegroundColor DarkGray "Import OSD PS Module"
Start-Process PowerShell -ArgumentList "-NoL -C Import-Module OSD -Force -Verbose" -Wait

Write-Host -ForegroundColor DarkGray "Checking Windows Autopilot Prerequisites..."
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript  https://check-autopilotprereq.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing Windows Autopilot Registration Script..."
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript  https://start-winautopilotreg.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing OOBEDeploy Windows Bloatware Remove"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://RemoveDebloat.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Executing TPM Attestation Script..."
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://tpmAttestation.ps1" -Wait

Write-Host -ForegroundColor DarkGray "WaitForOnBoarding Task"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://RegisterTask.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Setup Complete Send Notification"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://WebHookNotify.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Cleanup OSDCloud Files"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://cleanup-osdcloud.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Run Create OSDComputerName Script"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://CreateOSDComputerName.ps1" -Wait

Write-Host -ForegroundColor DarkGray "Run Create OSDComputerName Script"
Start-Process PowerShell -ArgumentList "-NoL -C Invoke-WebPSScript https://Install-LAPSClientX64.ps1" -Wait


# Cleanup scheduled Tasks
Write-Host -ForegroundColor DarkGray "Unregistering Scheduled Tasks"
Unregister-ScheduledTask -TaskName "Scheduled Task for SendKeys" -Confirm:`$false
Unregister-ScheduledTask -TaskName "Scheduled Task for OSDCloud post installation" -Confirm:`$false

Write-Host -ForegroundColor DarkGray "Restarting Computer"
Start-Process PowerShell -ArgumentList "-NoL -C Restart-Computer -Force" -Wait

Stop-Transcript -Verbose | Out-File
"@

Out-File -FilePath $ScriptPathOOBE -InputObject $OOBEScript -Encoding ascii

$SendKeysScript = @"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-SendKeys.log"
Start-Transcript -Path (Join-Path "`$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" `$Global:Transcript) -ErrorAction Ignore | Out-Null

Write-Host -ForegroundColor DarkGray "Stop Debug-Mode (SHIFT + F10) with WscriptShell.SendKeys"
`$WscriptShell = New-Object -com Wscript.Shell

# ALT + TAB
Write-Host -ForegroundColor DarkGray "SendKeys: ALT + TAB"
`$WscriptShell.SendKeys("%({TAB})")

Start-Sleep -Seconds 1

# Shift + F10
Write-Host -ForegroundColor DarkGray "SendKeys: SHIFT + F10"
`$WscriptShell.SendKeys("+({F10})")

Stop-Transcript -Verbose | Out-File
"@

Out-File -FilePath $ScriptPathSendKeys -InputObject $SendKeysScript -Encoding ascii

# Download ServiceUI.exe
Write-Host -ForegroundColor Gray "Download ServiceUI.exe from GitHub Repo"

Invoke-WebRequest https://github.com/AkosBakos/Tools/raw/main/ServiceUI64.exe -OutFile "C:\Windows\Temp\OSDCloud\ServiceUI.exe"

#Create Scheduled Task for SendKeys with 15 seconds delay
$TaskName = "Scheduled Task for SendKeys"

$ShedService = New-Object -comobject 'Schedule.Service'
$ShedService.Connect()

$Task = $ShedService.NewTask(0)
$Task.RegistrationInfo.Description = $taskName
$Task.Settings.Enabled = $true
$Task.Settings.AllowDemandStart = $true

# https://msdn.microsoft.com/en-us/library/windows/desktop/aa383987(v=vs.85).aspx
$trigger = $task.triggers.Create(9) # 0 EventTrigger, 1 TimeTrigger, 2 DailyTrigger, 3 WeeklyTrigger, 4 MonthlyTrigger, 5 MonthlyDOWTrigger, 6 IdleTrigger, 7 RegistrationTrigger, 8 BootTrigger, 9 LogonTrigger
$trigger.Delay = 'PT15S'
$trigger.Enabled = $true

$action = $Task.Actions.Create(0)
$action.Path = 'C:\Windows\Temp\OSDCloud\ServiceUI.exe'
$action.Arguments = '-process:RuntimeBroker.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe ' + $ScriptPathSendKeys + ' -NoExit'

$taskFolder = $ShedService.GetFolder("\")
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa382577(v=vs.85).aspx
$taskFolder.RegisterTaskDefinition($TaskName, $Task , 6, "SYSTEM", $NULL, 5)

# Create Scheduled Task for OSDCloud post installation with 20 seconds delay
$TaskName = "Scheduled Task for OSDCloud post installation"

$ShedService = New-Object -comobject 'Schedule.Service'
$ShedService.Connect()

$Task = $ShedService.NewTask(0)
$Task.RegistrationInfo.Description = $taskName
$Task.Settings.Enabled = $true
$Task.Settings.AllowDemandStart = $true

# https://msdn.microsoft.com/en-us/library/windows/desktop/aa383987(v=vs.85).aspx
$trigger = $task.triggers.Create(9) # 0 EventTrigger, 1 TimeTrigger, 2 DailyTrigger, 3 WeeklyTrigger, 4 MonthlyTrigger, 5 MonthlyDOWTrigger, 6 IdleTrigger, 7 RegistrationTrigger, 8 BootTrigger, 9 LogonTrigger
$trigger.Delay = 'PT20S'
$trigger.Enabled = $true

$action = $Task.Actions.Create(0)
$action.Path = 'C:\Windows\Temp\OSDCloud\ServiceUI.exe'
$action.Arguments = '-process:RuntimeBroker.exe C:\WINDOWS\System32\WindowsPowerShell\v1.0\powershell.exe ' + $ScriptPathOOBE + ' -NoExit'

$taskFolder = $ShedService.GetFolder("\")
# https://msdn.microsoft.com/en-us/library/windows/desktop/aa382577(v=vs.85).aspx
$taskFolder.RegisterTaskDefinition($TaskName, $Task , 6, "SYSTEM", $NULL, 5)
