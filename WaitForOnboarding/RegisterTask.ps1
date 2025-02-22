# Define log file path
$logFilePath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\DefenderOnboarding.log"

# Function to write to log file
function WriteToLogFile {
    param([string]$message)
    Add-Content -Path $logFilePath -Value "$message - $(Get-Date)"
}

# Ensure log directory exists
$logDirectory = Split-Path $logFilePath -Parent
if (-not (Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}

# Write OSD completion to log file
WriteToLogFile "OSD Complete Registering WaitForOnboarding Task"

# Define URL and target locations
$ps1fileurl = '/WaitforOnboard.ps1'
$targetLocation2 = 'C:\Scripts\WaitforOnboard.ps1'

$XmlFileUrl = '/WaitforOnboarding.xml'
$targetLocation = 'C:\Scripts\WaitforOnboarding.xml'

# Ensure target directory exists
$directory = Split-Path $targetLocation -Parent
if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

# Download XML file and PowerShell script
try {
    Invoke-WebRequest -Uri $XmlFileUrl -OutFile $targetLocation
    Invoke-WebRequest -Uri $ps1fileurl -OutFile $targetLocation2
    Write-Host "Files downloaded successfully."
} catch {
    Write-Host "An error occurred while downloading files: $_"
}

# Register the scheduled task
try {
    $xmlContent = Get-Content $targetLocation -Raw
    Register-ScheduledTask -Xml $xmlContent -TaskName 'WaitforOnboarding'
    Write-Host "Scheduled task registered successfully."
} catch {
    Write-Host "An error occurred while registering the scheduled task: $_"
}