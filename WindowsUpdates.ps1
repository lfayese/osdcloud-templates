# Check if the script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Please run it as an Administrator."
    Exit
}

# Initialize variables for updating Windows and Drivers
$UpdateWindows = $true
$UpdateDrivers = $true

# Check if PSWindowsUpdate module is available, if not try to install
if (!(Get-Module PSWindowsUpdate -ListAvailable)) {
    try {
        Install-Module PSWindowsUpdate -Force
    }
    catch {
        Write-Warning 'Unable to install PSWindowsUpdate PowerShell Module'
        $UpdateWindows = $false
        $UpdateDrivers = $false
    }
}

# Update Windows if the module is available
if ($UpdateWindows) {
    # Add MicrosoftUpdate to WUServiceManager
    Write-Host -ForegroundColor DarkCyan 'Adding MicrosoftUpdate to WUServiceManager'
    Add-WUServiceManager -MicrosoftUpdate -Confirm:$false

    # Install Windows Updates (excluding Malicious and Preview updates)
    Write-Host -ForegroundColor DarkCyan 'Installing Windows Updates (excluding Malicious and Preview updates)'
    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot -NotTitle 'Malicious','Preview'
}

# Update Drivers if the module is available
if ($UpdateDrivers) {
    # Install Driver Updates
    Write-Host -ForegroundColor DarkCyan 'Installing Driver Updates'
    Install-WindowsUpdate -UpdateType Driver -AcceptAll -IgnoreReboot
}

# Function to check and perform a reboot if needed
function Get-CheckReboot {
    if (Get-WURebootStatus -Silent) {
        $RebootWindowTitle = "Reboot Required"
        $Host.UI.RawUI.WindowTitle = $RebootWindowTitle
        Write-Host -ForegroundColor Yellow "Reboot is required to complete the updates. Initiating system restart..."
        shutdown /r /t 0
    }
}

# Check for pending reboots after updates
Get-CheckReboot