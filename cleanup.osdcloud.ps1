# cleanup.osdcloud
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Cleanup.log"
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

$cleanupPaths = @(
    "$env:windir\Temp\OSDCloud",
    "$env:TEMP\OSDCloud",
    "C:\OSDCloud\Scripts",
    "X:\OSDCloud"  # Only if accessible
)

$cleanupKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\Accounts\*",
    "HKLM:\SOFTWARE\Microsoft\Enrollments\*"
)

foreach ($path in $cleanupPaths) {
    try {
        if (Test-Path $path) {
            Write-Host "Removing $path"
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Host "Successfully removed $path"
        }
    } catch {
        Write-Warning "Failed to remove $path : $_"
    }
}

foreach ($key in $cleanupKeys) {
    try {
        if (Test-Path $key) {
            Write-Host "Removing registry key $key"
            Remove-Item -Path $key -Recurse -Force -ErrorAction Stop
            Write-Host "Successfully removed registry key $key"
        }
    } catch {
        Write-Warning "Failed to remove registry key $key : $_"
    }
}

# Clean up scheduled tasks
$tasksToRemove = @(
    "WaitforOnboarding",
    "Scheduled Task for SendKeys",
    "Scheduled Task for OSDCloud post installation"
)

foreach ($taskName in $tasksToRemove) {
    try {
        if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction Stop
            Write-Host "Successfully removed scheduled task: $taskName"
        }
    } catch {
        Write-Warning "Failed to remove scheduled task $taskName : $_"
    }
}
# Function to clean up OSDCloud deployment files
function Remove-OSDCloudDeploymentFiles {
    $PathsToClean = @(
        "C:\OSDCloud\Logs",
        "C:\OSDCloud\OS",
        "C:\Drivers"
    )
    
    foreach ($Path in $PathsToClean) {
        if (Test-Path $Path) {
            Write-Host "Cleaning up $Path..." -ForegroundColor Cyan
            Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Function to optimize Windows
function Optimize-WindowsInstallation {
    Write-Host "Optimizing Windows installation..." -ForegroundColor Cyan
    
    # Clear temporary files
    Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # Clean up WinSxS folder
    Write-Host "Cleaning up WinSxS folder..." -ForegroundColor Cyan
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
    
    # Clear event logs
    Write-Host "Clearing event logs..." -ForegroundColor Cyan
    wevtutil el | Foreach-Object {wevtutil cl "$_"}
}

# Function to configure Windows Update
function Set-WindowsUpdateConfig {
    Write-Host "Configuring Windows Update settings..." -ForegroundColor Cyan
    
    # Enable Microsoft Update
    $mu = New-Object -ComObject Microsoft.Update.ServiceManager
    $mu.AddService2("7971f918-a847-4430-9279-4a52d1efe18d", 7, "")
    
    # Configure update settings via registry
    $UpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    $AUPath = "$UpdatePath\AU"
    
    if (-not (Test-Path $UpdatePath)) {
        New-Item -Path $UpdatePath -Force | Out-Null
    }
    if (-not (Test-Path $AUPath)) {
        New-Item -Path $AUPath -Force | Out-Null
    }
    
    # Configure auto-update settings
    Set-ItemProperty -Path $AUPath -Name "NoAutoUpdate" -Value 0
    Set-ItemProperty -Path $AUPath -Name "AUOptions" -Value 4
    Set-ItemProperty -Path $AUPath -Name "ScheduledInstallDay" -Value 0
    Set-ItemProperty -Path $AUPath -Name "ScheduledInstallTime" -Value 3
}

try {
    Write-Host "Starting post-deployment cleanup and optimization..." -ForegroundColor Cyan
    
    # Run cleanup tasks
    Remove-OSDCloudDeploymentFiles
    Optimize-WindowsInstallation
    Set-WindowsUpdateConfig
    
    Write-Host "Post-deployment tasks completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during post-deployment tasks: $_"
    exit 1
}

Stop-Transcript