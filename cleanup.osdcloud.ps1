# cleanup.osdcloud.ps1
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

function Remove-OSDCloudFiles {
    $KeepTheseDirs = @('boot', 'efi', 'en-us', 'sources', 'fonts', 'resources')
    
    # Clean up OSDCloud workspace
    $paths = @(
        "$env:ProgramData\OSDCloud\Media",
        "$env:ProgramData\OSDCloud\Media\Boot",
        "$env:ProgramData\OSDCloud\Media\EFI\Microsoft\Boot"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Get-ChildItem $path | 
                Where-Object { $_.PSIsContainer } | 
                Where-Object { $_.Name -notin $KeepTheseDirs } | 
                Remove-Item -Recurse -Force
        }
    }

    # Move OSDCloud logs
    if (Test-Path 'C:\OSDCloud\Logs') {
        Move-Item 'C:\OSDCloud\Logs\*.*' -Destination 'C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD' -Force
    }
}

function Optimize-WindowsImage {
    Write-Host "Running system optimization tasks..." -ForegroundColor Cyan
    
    # Clean up WinSxS
    Write-Host "Cleaning up WinSxS folder..." -ForegroundColor Cyan
    Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
    
    # Clean up update cache
    Write-Host "Cleaning up Windows Update cache..." -ForegroundColor Cyan
    Stop-Service -Name wuauserv, bits -Force
    Remove-Item "$env:SystemRoot\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv, bits
    
    # Clear event logs
    Write-Host "Clearing event logs..." -ForegroundColor Cyan
    wevtutil el | ForEach-Object { wevtutil cl "$_" }
}

try {
    Write-Host "Starting OSDCloud cleanup process..." -ForegroundColor Cyan
    Remove-OSDCloudFiles
    Optimize-WindowsImage
    Write-Host "Cleanup completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during cleanup: $_"
    exit 1
}
finally {
    Stop-Transcript
}