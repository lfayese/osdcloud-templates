# =============================================================
# Initialize
# =============================================================
# Start a transcript to log all actions
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud-Setup.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Stop
# Define paths and variables
$ADKMediaDir = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Media"
$OSDCloudTemplateDir = "C:\OSDCloud\Template"
$ADKWinpeWim = Join-Path $ADKMediaDir "sources\boot.wim"
$BootWim = Join-Path $OSDCloudTemplateDir "boot.wim"
$MountPath = "C:\OSDCloud\Mount"
# Create required directories
New-Item -ItemType Directory -Path $OSDCloudTemplateDir -Force | Out-Null
New-Item -ItemType Directory -Path $MountPath -Force | Out-Null
# Mirror the ADK Media directory to the OSDCloud Template
Write-Host "Mirroring ADK Media directory to OSDCloud Template..."
Copy-Item -Path $ADKMediaDir -Destination $OSDCloudTemplateDir -Recurse -Force
# Copy the ADK winpe.wim to the OSDCloud Template as boot.wim
Write-Host "Copying ADK winpe.wim to OSDCloud Template boot.wim..."
Copy-Item -Path $ADKWinpeWim -Destination $BootWim -Force
# Mount the boot.wim image
Write-Host "Mounting boot.wim..."
Mount-WindowsImage -ImagePath $BootWim -Index 1 -Path $MountPath
# =============================================================
# ADK Packages
# =============================================================
Write-Host "Injecting ADK Packages for PowerShell functionality..."
$ADKPackagesPath = "C:\ADKPackages"
if (Test-Path $ADKPackagesPath) {
    $packages = Get-ChildItem -Path $ADKPackagesPath -Filter "*.cab"
    if ($packages.Count -eq 0) {
        Write-Warning "No CAB packages found in $ADKPackagesPath"
    } else {
        foreach ($package in $packages) {
            try {
                Write-Host "Adding package: $($package.FullName)"
                $result = Add-WindowsPackage -Path $MountPath -PackagePath $package.FullName -ErrorAction Stop
                Write-Host "Successfully installed: $($package.Name)"
            } catch {
                Write-Error "Failed to install package $($package.Name): $_"
                continue
            }
        }
    }
} else {
    Write-Warning "ADK Packages path not found: $ADKPackagesPath"
}

# Validate critical packages are installed
$requiredFeatures = @('NetFx', 'PowerShell', 'WinPE-WMI')
$installedPackages = Get-WindowsPackage -Path $MountPath
foreach ($feature in $requiredFeatures) {
    if (-not ($installedPackages | Where-Object { $_.PackageName -like "*$feature*" })) {
        Write-Warning "Critical package missing: $feature"
    }
}

# Save the Windows Image after package injection
Write-Host "Saving the Windows Image after ADK package injection..."
Dismount-WindowsImage -Path $MountPath -Save -CheckIntegrity
# =============================================================
# Helper Files and Scripts
# =============================================================
# Remount the image for file copying
Write-Host "Remounting boot.wim for file additions..."
Mount-WindowsImage -ImagePath $BootWim -Index 1 -Path $MountPath
# Copy Scripts
$ScriptsDestination = Join-Path $MountPath "OSDCloud\Scripts"
New-Item -ItemType Directory -Path $ScriptsDestination -Force | Out-Null
# Copy template scripts
$TemplateScripts = @(
    "Autopilot\start-autopilotoobe.ps1",
    "CreateOSDComputerName.ps1",
    "cleanup.osdcloud.ps1",
    "BootOOBE.ps1",
    "WindowsUpdates.ps1",
    "set-wifi.ps1",
    "oobetasks.osdcloud.ps1"
)
foreach ($script in $TemplateScripts) {
    $sourcePath = Join-Path $PSScriptRoot $script
    if (Test-Path $sourcePath) {
        Copy-Item -Path $sourcePath -Destination (Join-Path $ScriptsDestination (Split-Path $script -Leaf)) -Force
    }
}
# Copy Autopilot configuration
$AutopilotSource = Join-Path $PSScriptRoot "Autopilot"
$AutopilotDest = Join-Path $MountPath "OSDCloud\Autopilot"
if (Test-Path $AutopilotSource) {
    Copy-Item -Path $AutopilotSource -Destination $AutopilotDest -Recurse -Force
}
# =============================================================
# Registry Configuration
# =============================================================
Write-Host "Configuring registry settings..."
$RegPath = "HKLM:\WinPE\Software\Policies\Microsoft\Windows\PowerShell"
if (-not (Test-Path "Registry::$RegPath")) {
    New-Item -Path "Registry::HKLM\WinPE\Software\Policies\Microsoft\Windows" -Name "PowerShell" -Force
}
Set-ItemProperty -Path "Registry::$RegPath" -Name "ExecutionPolicy" -Value "RemoteSigned"
# =============================================================
# PowerShell Gallery Configuration
# =============================================================
Write-Host "Configuring PowerShell Gallery..."
$PSGalleryDir = Join-Path $MountPath "ProgramData\Microsoft\PowerShell\PSRepository"
New-Item -ItemType Directory -Path $PSGalleryDir -Force | Out-Null
@"
<Repository>
    <Name>PSGallery</Name>
    <SourceLocation>https://www.powershellgallery.com/api/v2/</SourceLocation>
    <InstallationPolicy>Trusted</InstallationPolicy>
</Repository>
"@ | Out-File -FilePath (Join-Path $PSGalleryDir "PSGallery.xml") -Encoding UTF8
# =============================================================
# Complete
# =============================================================
# Save and dismount the image
Write-Host "Saving and dismounting Windows Image..."
Dismount-WindowsImage -Path $MountPath -Save
# Create compressed version
Write-Host "Creating compressed boot.wim..."
$CompressedBootWim = Join-Path $OSDCloudTemplateDir "boot_compressed.wim"
Export-WindowsImage -SourceImagePath $BootWim -SourceIndex 1 -DestinationImagePath $CompressedBootWim -Compress maximum
# Create configuration directories
Write-Host "Creating configuration directories..."
New-Item -ItemType Directory -Path (Join-Path $OSDCloudTemplateDir "Config") -Force
New-Item -ItemType Directory -Path (Join-Path $OSDCloudTemplateDir "Logs") -Force
# Create ISO
Write-Host "Creating ISO image..."
$ISOOutput = Join-Path $OSDCloudTemplateDir "OSDCloud.iso"
if (Get-Command "oscdimg.exe" -ErrorAction SilentlyContinue) {
    oscdimg -n -m $OSDCloudTemplateDir $ISOOutput
}
Stop-Transcript