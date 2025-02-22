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

# Define variables
$directory = "C:\OSDCloud\Scripts"
$targetLocation = Join-Path $directory "WaitforOnboarding.xml"
$targetLocation2 = Join-Path $directory "WaitforOnboard.ps1"

# Create directory if it doesn't exist
if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force | Out-Null
}

# Copy files from USB
$sourceFiles = @{
    "WaitforOnboarding.xml" = $targetLocation
    "WaitforOnboard.ps1" = $targetLocation2
}

foreach ($file in $sourceFiles.GetEnumerator()) {
    $sourcePath = "X:\OSDCloud\Scripts\WaitForOnboarding\$($file.Key)"
    try {
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $file.Value -Force -ErrorAction Stop
            Write-Host "Successfully copied $($file.Key)"
            WriteToLogFile "Successfully copied $($file.Key) to $($file.Value)"
        } else {
            throw "Source file not found: $sourcePath"
        }
    } catch {
        $errorMsg = "Failed to copy $($file.Key): $_"
        Write-Host $errorMsg -ForegroundColor Red
        WriteToLogFile $errorMsg
        exit 1
    }
}

# Register the scheduled task
try {
    if (Test-Path $targetLocation) {
        $xmlContent = Get-Content $targetLocation -Raw -ErrorAction Stop
        $existingTask = Get-ScheduledTask -TaskName 'WaitforOnboarding' -ErrorAction SilentlyContinue
        if ($existingTask) {
            Unregister-ScheduledTask -TaskName 'WaitforOnboarding' -Confirm:$false
        }
        Register-ScheduledTask -Xml $xmlContent -TaskName 'WaitforOnboarding'
        WriteToLogFile "Scheduled task registered successfully"
    } else {
        throw "Task XML file not found at $targetLocation"
    }
} catch {
    $errorMsg = "Failed to register scheduled task: $_"
    Write-Host $errorMsg -ForegroundColor Red
    WriteToLogFile $errorMsg
    exit 1
}