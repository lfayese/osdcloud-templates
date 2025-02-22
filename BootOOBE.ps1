# Set global transcript file name and start transcript logging
$Global:Transcript = "$(Get-Date -Format 'yyyy-MM-dd-HHmmss')-OOBEScripts.log"
$TranscriptPath = Join-Path -Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD" -ChildPath $Global:Transcript
Start-Transcript -Path $TranscriptPath -ErrorAction Stop

# Terminate any running sysprep processes
Get-Process sysprep -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Cleanup actions
Remove-Item -Path "C:\Windows\Panther\unattend.xml" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "C:\Windows\Setup\Scripts\init.ps1" -Recurse -Force -ErrorAction SilentlyContinue # Prevent loop after OOBE

# Copy init.ps1 from USB to Windows
$SourcePath = "X:\OSDCloud\Scripts\init.ps1"
$DestinationFolder = 'C:\Windows\Setup\Scripts'
$DestinationPath = Join-Path -Path $DestinationFolder -ChildPath 'init.ps1'

# Create destination directory if it doesn't exist
if (!(Test-Path -Path $DestinationFolder)) {
    New-Item -Path $DestinationFolder -ItemType Directory -Force | Out-Null
}

# Copy file with error handling
try {
    Copy-Item -Path $SourcePath -Destination $DestinationPath -Force -ErrorAction Stop
    Write-Host "File copied successfully to $DestinationPath"
} catch {
    Write-Error "Failed to copy init.ps1: $_"
    exit 1
}

# Ensure setup scripts directory exists
$setupScriptsDir = 'C:\Windows\Setup\Scripts'
if (!(Test-Path -Path $setupScriptsDir)) {
    New-Item -Path $setupScriptsDir -ItemType Directory -Force | Out-Null
}

# Generate SetupComplete.cmd file
$SetupCompleteCMDContent = @"
powershell.exe -command set-executionpolicy remotedsigned -force
powershell.exe -file "%~dp0init.ps1"
powershell.exe -command "& 'X:\OSDCloud\Scripts\oobetasks.osdcloud.ps1'"
"@

$SetupCompleteCMDPath = Join-Path $setupScriptsDir 'SetupComplete.cmd'

try {
    $SetupCompleteCMDContent | Out-File -FilePath $SetupCompleteCMDPath -Encoding ascii -Force -ErrorAction Stop
    Write-Host "Successfully created SetupComplete.cmd"
} catch {
    Write-Error "Failed to create SetupComplete.cmd: $_"
    exit 1
}

# Copy unattend.xml from USB to sysprep folder
$UnattendSource = 'X:\OSDCloud\Scripts\unattend.xml'
$UnattendDest = 'C:\Windows\system32\sysprep\unattend.xml'

# Ensure sysprep directory exists
$sysprepDir = Split-Path $UnattendDest -Parent
if (!(Test-Path -Path $sysprepDir)) {
    New-Item -Path $sysprepDir -ItemType Directory -Force | Out-Null
}

try {
    Copy-Item -Path $UnattendSource -Destination $UnattendDest -Force -ErrorAction Stop
    Write-Host "Unattend.xml copied successfully"
} catch {
    Write-Error "Failed to copy unattend.xml: $_"
    exit 1
}

# Execute sysprep
Start-Process -FilePath "C:\Windows\System32\Sysprep\sysprep.exe" -ArgumentList "/oobe /quiet /reboot /unattend:$UnattendDest" -Wait 

exit(0)