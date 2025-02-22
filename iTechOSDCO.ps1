# OSDCloud Orchestrator Script
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Windows10', 'Windows11')]
    [string]$OSVersion = 'Windows11',
    
    [Parameter()]
    [ValidateSet('Enterprise', 'Pro')]
    [string]$Edition = 'Enterprise',
    
    [Parameter()]
    [string]$Language = 'en-us',
    
    [Parameter()]
    [switch]$ZTI
)

# Phase tracking for resume capability
$PhaseFile = "X:\OSDCloud\CurrentPhase.txt"

function Write-Phase {
    param([string]$Phase)
    $Phase | Out-File -FilePath $PhaseFile -Force
    Write-Host "Current deployment phase: $Phase" -ForegroundColor Cyan
}

function Get-CurrentPhase {
    if (Test-Path $PhaseFile) {
        return Get-Content $PhaseFile
    }
    return "Initialize"
}

# Main deployment orchestration
try {
    $CurrentPhase = Get-CurrentPhase

    switch ($CurrentPhase) {
        "Initialize" {
            Write-Phase "Initialize"
            
            # Run prerequisite checks
            . .\check-autopilotprereq.ps1
            
            # Set up wireless if needed
            . .\set-wifi.ps1
            
            Write-Phase "PrepareSystem"
        }

        "PrepareSystem" {
            Write-Phase "PrepareSystem"
            
            # Check and configure TPM
            . .\tpmAttestation.ps1
            
            # Start OSDCloud deployment
            if ($ZTI) {
                Start-OSDCloud -OSVersion $OSVersion -OSEdition $Edition -OSLanguage $Language -ZTI
            } else {
                Start-OSDCloudGUI
            }
            
            Write-Phase "PostOS"
        }

        "PostOS" {
            Write-Phase "PostOS"
            
            # Run post-deployment cleanup
            . .\cleanup.osdcloud.ps1
            
            # Configure OOBE and Autopilot
            . .\oobetasks.osdcloud.ps1
            
            # Run Windows Updates
            . .\WindowsUpdates.ps1 -IncludeFirmware
            
            Write-Phase "Complete"
        }

        "Complete" {
            Write-Host "OSDCloud deployment completed successfully!" -ForegroundColor Green
            Remove-Item $PhaseFile -Force -ErrorAction SilentlyContinue
        }
    }
}
catch {
    Write-Error "Deployment failed in phase $CurrentPhase : $_"
    exit 1
}

# =============================================================
# Initialize
# =============================================================
# Start a transcript to log all actions
Start-Transcript -Path "C:\OSDCloud\Logs\OSDCloudSetup.log"

# Define paths and variables
$ADKMediaDir            = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Media"
$OSDCloudTemplateDir    = "C:\OSDCloud\Template"
$ADKWinpeWim            = Join-Path $ADKMediaDir "sources\boot.wim"
$BootWim                = Join-Path $OSDCloudTemplateDir "boot.wim"
$MountPath              = "C:\OSDCloud\Mount"

# Cleanup any existing mount points
if (Test-Path $MountPath) {
    $mountedImages = Get-WindowsImage -Mounted | Where-Object { $_.Path -eq $MountPath }
    if ($mountedImages) {
        Write-Warning "Found existing mounted image. Attempting cleanup..."
        try {
            Dismount-WindowsImage -Path $MountPath -Discard -ErrorAction Stop
        } catch {
            Write-Error "Failed to dismount existing image: $_"
            exit 1
        }
    }
    Remove-Item -Path $MountPath -Force -Recurse
}

# Create fresh mount directory
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

# Mount the WinPE registry to extract WinPE Info
Write-Host "Mounting WinPE registry..."
$WinPERegHive = Join-Path $MountPath "Windows\System32\Config\SYSTEM"
reg load HKLM\WinPE $WinPERegHive

# =============================================================
# ADK Packages
# =============================================================
Write-Host "Injecting ADK Packages for PowerShell functionality..."
# Define the folder where your ADK packages (CAB files) reside
$ADKPackagesPath = "C:\ADKPackages"
# Loop through each package and add it to the mounted image
Get-ChildItem -Path $ADKPackagesPath -Filter *.cab or *.msu | ForEach-Object {
    Write-Host "Adding package: $($_.FullName)"
    Add-WindowsPackage -Path $MountPath -PackagePath $_.FullName
}

# Save the Windows Image after package injection
Write-Host "Saving the Windows Image after ADK package injection..."
Dismount-WindowsImage -Path $MountPath -Save -CheckIntegrity

# =============================================================
# Tweaks
# =============================================================
# Remount the image to apply further tweaks
Write-Host "Remounting boot.wim for tweaks..."
Mount-WindowsImage -ImagePath $BootWim -Index 1 -Path $MountPath

# Copy helper files from the running OS (customize source/destination as needed)
Write-Host "Copying helper files from running OS..."
$HelperFilesSource      = "C:\HelperFiles"
$HelperFilesDestination = Join-Path $MountPath "HelperFiles"
if (Test-Path $HelperFilesSource) {
    Copy-Item -Path $HelperFilesSource -Destination $HelperFilesDestination -Recurse -Force
}

# If MDT is installed, add the Dart Configuration
if (Get-Command "mdtcommand" -ErrorAction SilentlyContinue) {
    Write-Host "MDT detected. Adding Dart Configuration..."
    $MDTDartConfig = "C:\MDT\DartConfig.xml"
    if (Test-Path $MDTDartConfig) {
        Copy-Item -Path $MDTDartConfig -Destination (Join-Path $MountPath "Config\DartConfig.xml") -Force
    }
}

# If Microsoft Dart is installed, inject the Tools
if (Test-Path "C:\Program Files\Microsoft Dart") {
    Write-Host "Microsoft Dart detected. Injecting Tools..."
    $DartToolsSource      = "C:\Program Files\Microsoft Dart\Tools"
    $DartToolsDestination = Join-Path $MountPath "DartTools"
    Copy-Item -Path $DartToolsSource -Destination $DartToolsDestination -Recurse -Force
}

# Save the Windows Image after applying tweaks
Write-Host "Saving the Windows Image after tweaks..."
Dismount-WindowsImage -Path $MountPath -Save -CheckIntegrity

# Remount image for configuration changes
Write-Host "Remounting boot.wim for additional configuration..."
Mount-WindowsImage -ImagePath $BootWim -Index 1 -Path $MountPath

# Set the WinPE PowerShell ExecutionPolicy
Write-Host "Setting WinPE PowerShell ExecutionPolicy..."
$RegPath = "HKLM\WinPE\Software\Policies\Microsoft\Windows\PowerShell"
if (-not (Test-Path "Registry::$RegPath")) {
    New-Item -Path "Registry::HKLM\WinPE\Software\Policies\Microsoft\Windows" -Name "PowerShell" -Force
}
Set-ItemProperty -Path "Registry::HKLM\WinPE\Software\Policies\Microsoft\Windows\PowerShell" -Name "ExecutionPolicy" -Value "RemoteSigned"

# Enable PowerShell Gallery support by creating a repository configuration file (placeholder implementation)
Write-Host "Enabling PowerShell Gallery support..."
$PSGalleryRepoDir  = Join-Path $MountPath "ProgramData\Microsoft\PowerShell\PSRepository"
$PSGalleryRepoFile = Join-Path $PSGalleryRepoDir "PSGallery.xml"
if (-not (Test-Path $PSGalleryRepoDir)) {
    New-Item -ItemType Directory -Path $PSGalleryRepoDir -Force
}
@"
<Repository>
    <Name>PSGallery</Name>
    <SourceLocation>https://www.powershellgallery.com/api/v2/</SourceLocation>
    <InstallationPolicy>Trusted</InstallationPolicy>
</Repository>
"@ | Out-File -FilePath $PSGalleryRepoFile -Encoding UTF8

# Remove winpeshl.ini if it exists in the mounted image
$WinpeshlFile = Join-Path $MountPath "winpeshl.ini"
if (Test-Path $WinpeshlFile) {
    Write-Host "Removing winpeshl.ini..."
    Remove-Item $WinpeshlFile -Force
}

# Change settings for a better Command Prompt experience
Write-Host "Tweaking Command Prompt settings..."
$CmdRegPath = "HKLM\WinPE\Software\Microsoft\Command Processor"
if (-not (Test-Path "Registry::$CmdRegPath")) {
    New-Item -Path "Registry::HKLM\WinPE\Software\Microsoft\Command Processor" -Force
}
Set-ItemProperty -Path "Registry::HKLM\WinPE\Software\Microsoft\Command Processor" -Name "AutoRun" -Value "doskey /history"

# =============================================================
# Packages
# =============================================================
Write-Host "Displaying installed Windows Packages..."
$InstalledPackages = Get-WindowsPackage -Path $MountPath
$InstalledPackages | Format-Table -AutoSize

# =============================================================
# Complete
# =============================================================
# Dismount the image after all changes are applied
Write-Host "Dismounting Windows Image..."
Dismount-WindowsImage -Path $MountPath -Save

# Export the boot.wim with maximum compression
Write-Host "Exporting boot.wim to create a compressed image..."
$CompressedBootWim = Join-Path $OSDCloudTemplateDir "boot_compressed.wim"
Export-WindowsImage -SourceImagePath $BootWim -SourceIndex 1 -DestinationImagePath $CompressedBootWim -Compress maximum

# Create empty configuration directories as needed
Write-Host "Creating empty configuration directories..."
New-Item -ItemType Directory -Path (Join-Path $OSDCloudTemplateDir "Config") -Force
New-Item -ItemType Directory -Path (Join-Path $OSDCloudTemplateDir "Logs") -Force

# Create the ISOs (this example assumes oscdimg.exe is in the PATH)
Write-Host "Creating the ISO image..."
$ISOOutput = Join-Path $OSDCloudTemplateDir "OSDCloud.iso"
oscdimg -n -m $OSDCloudTemplateDir $ISOOutput

# Set the OSDCloud Template to the new path (update your configuration as needed)
Write-Host "Updating OSDCloud Template path..."
$NewTemplatePath = "D:\OSDCloud\NewTemplate"
Set-Content -Path (Join-Path $OSDCloudTemplateDir "TemplatePath.txt") -Value $NewTemplatePath

# Stop the transcript logging
Stop-Transcript