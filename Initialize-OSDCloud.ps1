#Requires -RunAsAdministrator
#Requires -PSEdition Desktop

# Initialize OSDCloud Setup Script
# This script automates the setup of OSDCloud environment

[CmdletBinding()]
param(
    [Parameter()]
    [string]$WorkspacePath = "C:\OSDCloud",
    
    [Parameter()]
    [string[]]$CloudDrivers = @("Dell", "HP", "IntelNet", "LenovoDock", "USB", "WiFi"),
    
    [Parameter()]
    [switch]$UseWinRE = $false,
    
    [Parameter()]
    [string]$CustomBrandName = "BAH OSDCloud",
    
    [Parameter()]
    [string]$CustomBrandColor = "#0066CC"
)

# Function to validate prerequisites
function Test-OSDCloudPrerequisites {
    $Prerequisites = @{
        "ADK Installed" = Test-Path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit"
        "WinPE Addon" = Test-Path "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
        "PowerShell" = $PSVersionTable.PSVersion.Major -ge 5
    }

    $AllPrerequisitesMet = $true
    foreach ($prereq in $Prerequisites.GetEnumerator()) {
        Write-Host "Checking $($prereq.Key): " -NoNewline
        if ($prereq.Value) {
            Write-Host "Passed" -ForegroundColor Green
        } else {
            Write-Host "Failed" -ForegroundColor Red
            $AllPrerequisitesMet = $false
        }
    }
    return $AllPrerequisitesMet
}

# Function to install/update required modules
function Install-RequiredModules {
    Write-Host "Installing/Updating required PowerShell modules..." -ForegroundColor Cyan
    Install-Module OSD -Force
    Import-Module OSD -Force
}

# Function to create workspace and template
function Initialize-OSDCloudWorkspace {
    param (
        [string]$Path,
        [bool]$UseWinRE
    )
    
    Write-Host "Creating OSDCloud workspace at $Path..." -ForegroundColor Cyan
    
    # Create template based on WinRE or standard WinPE
    if ($UseWinRE) {
        Write-Host "Creating OSDCloud template using WinRE..." -ForegroundColor Cyan
        New-OSDCloudTemplate -Name "WinRE Template" -WinRE
    } else {
        Write-Host "Creating OSDCloud template using standard WinPE..." -ForegroundColor Cyan
        New-OSDCloudTemplate -Name "WinPE Template"
    }

    # Create workspace
    New-OSDCloudWorkspace -WorkspacePath $Path

    # Clean up unnecessary language resources
    $KeepTheseDirs = @('boot','efi','en-us','sources','fonts','resources')
    Get-ChildItem "$Path\Media" | Where-Object {$_.PSIsContainer} | Where-Object {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
    Get-ChildItem "$Path\Media\Boot" | Where-Object {$_.PSIsContainer} | Where-Object {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
    Get-ChildItem "$Path\Media\EFI\Microsoft\Boot" | Where-Object {$_.PSIsContainer} | Where-Object {$_.Name -notin $KeepTheseDirs} | Remove-Item -Recurse -Force
}

# Main script execution
try {
    Write-Host "Starting OSDCloud initialization..." -ForegroundColor Cyan
    
    # Check prerequisites
    if (-not (Test-OSDCloudPrerequisites)) {
        throw "Prerequisites not met. Please install Windows ADK and WinPE add-on."
    }

    # Install required modules
    Install-RequiredModules

    # Initialize workspace
    Initialize-OSDCloudWorkspace -Path $WorkspacePath -UseWinRE $UseWinRE

    # Configure WinPE with drivers and branding
    Write-Host "Configuring WinPE with drivers and branding..." -ForegroundColor Cyan
    Edit-OSDCloudWinPE -CloudDriver $CloudDrivers -BrandName $CustomBrandName -BrandColor $CustomBrandColor -StartOSDCloudGUI

    # Create ISO
    Write-Host "Creating OSDCloud ISO..." -ForegroundColor Cyan
    New-OSDCloudISO

    Write-Host "OSDCloud initialization completed successfully!" -ForegroundColor Green
    Write-Host "ISO files can be found in the workspace directory: $WorkspacePath" -ForegroundColor Yellow
}
catch {
    Write-Error "An error occurred during OSDCloud initialization: $_"
    exit 1
}