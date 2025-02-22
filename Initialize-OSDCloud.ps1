#Requires -RunAsAdministrator
#Requires -PSEdition Desktop

[CmdletBinding()]
param(
    [Parameter()]
    [string]$WorkspacePath = "C:\OSDCloud",
    
    [Parameter()]
    [string[]]$CloudDrivers = @("Dell", "HP", "IntelNet", "LenovoDock", "USB", "VMware", "WiFi"),
    
    [Parameter()]
    [switch]$UseWinRE,
    
    [Parameter()]
    [string]$CustomBrandName = "BAH OSDCloud",
    
    [Parameter()]
    [string]$CustomBrandColor = "#0066CC"
)

# Start transcript logging
$transcriptPath = Join-Path $env:ProgramData "Microsoft\IntuneManagementExtension\Logs\OSD"
if (-not (Test-Path $transcriptPath)) {
    New-Item -Path $transcriptPath -ItemType Directory -Force | Out-Null
}
Start-Transcript -Path (Join-Path $transcriptPath "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud-Setup.log")

try {
    Write-Host "Starting OSDCloud initialization..." -ForegroundColor Cyan

    # Ensure proper execution policy
    Set-ExecutionPolicy RemoteSigned -Force -ErrorAction Stop
    
    # Install/Update required modules
    Write-Host "Installing/Updating OSD PowerShell module..." -ForegroundColor Cyan
    Install-Module OSD -Force -AllowClobber -ErrorAction Stop
    Import-Module OSD -Force
    
    # Create new OSDCloud template
    Write-Host "Creating new OSDCloud template..." -ForegroundColor Cyan
    New-OSDCloud.template -Verbose
    
    # Create and configure workspace
    Write-Host "Creating OSDCloud workspace at $WorkspacePath..." -ForegroundColor Cyan
    New-OSDCloud.workspace -WorkspacePath $WorkspacePath
    
    # Configure WinPE with drivers and auto-start GUI
    Write-Host "Configuring WinPE with drivers and auto-start GUI..." -ForegroundColor Cyan
    Edit-OSDCloud.winpe -CloudDriver $CloudDrivers -StartOSDCloudGUI -BrandName $CustomBrandName -BrandColor $CustomBrandColor
    
    # Create ISO
    Write-Host "Creating OSDCloud ISO..." -ForegroundColor Cyan
    New-OSDCloud.iso
    
    Write-Host "OSDCloud initialization completed successfully!" -ForegroundColor Green
    Write-Host "ISO files can be found in: $WorkspacePath" -ForegroundColor Yellow

} catch {
    Write-Error "An error occurred during OSDCloud initialization: $_"
    exit 1
} finally {
    Stop-Transcript
}