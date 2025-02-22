# =============================================================
# Initialize
# =============================================================
$ErrorActionPreference = 'Stop'
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-OSDCloud-Setup.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript)

# Define paths and variables
$ADKMediaDir = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Media"
$OSDCloudTemplateDir = "C:\OSDCloud\Template"
$ADKWinpeWim = Join-Path $ADKMediaDir "sources\boot.wim"
$BootWim = Join-Path $OSDCloudTemplateDir "boot.wim"
$MountPath = "C:\OSDCloud\Mount"

function Initialize-OSDCloudBuild {
    # Create required directories
    @($OSDCloudTemplateDir, $MountPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }

    # Cleanup any existing mount points
    Get-WindowsImage -Mounted | 
        Where-Object { $_.Path -eq $MountPath } | 
        ForEach-Object { 
            Dismount-WindowsImage -Path $MountPath -Discard -ErrorAction Stop 
        }
}

function Add-OSDCloudComponents {
    Write-Host "Adding OSDCloud components..." -ForegroundColor Cyan
    
    # Mirror ADK Media
    Copy-Item -Path $ADKMediaDir -Destination $OSDCloudTemplateDir -Recurse -Force
    Copy-Item -Path $ADKWinpeWim -Destination $BootWim -Force

    # Mount boot.wim
    Mount-WindowsImage -ImagePath $BootWim -Index 1 -Path $MountPath
    
    # Configure PowerShell and registry settings
    $RegPath = "HKLM:\WinPE\Software\Policies\Microsoft\Windows\PowerShell"
    if (-not (Test-Path "Registry::$RegPath")) {
        New-Item -Path "Registry::HKLM\WinPE\Software\Policies\Microsoft\Windows" -Name "PowerShell" -Force
    }
    Set-ItemProperty -Path "Registry::$RegPath" -Name "ExecutionPolicy" -Value "RemoteSigned"

    # Configure PowerShell Gallery
    $PSGalleryDir = Join-Path $MountPath "ProgramData\Microsoft\PowerShell\PSRepository"
    New-Item -ItemType Directory -Path $PSGalleryDir -Force | Out-Null
    $PSGalleryXML = @"
<Repository>
    <Name>PSGallery</Name>
    <SourceLocation>https://www.powershellgallery.com/api/v2/</SourceLocation>
    <InstallationPolicy>Trusted</InstallationPolicy>
</Repository>
"@
    $PSGalleryXML | Out-File -FilePath (Join-Path $PSGalleryDir "PSGallery.xml") -Encoding ASCII
}

function Complete-OSDCloudBuild {
    # Save and dismount the image
    Write-Host "Finalizing image..." -ForegroundColor Cyan
    Dismount-WindowsImage -Path $MountPath -Save
    
    # Export with maximum compression
    Write-Host "Creating compressed image..." -ForegroundColor Cyan
    $CompressedBootWim = Join-Path $OSDCloudTemplateDir "boot_compressed.wim"
    Export-WindowsImage -SourceImagePath $BootWim -SourceIndex 1 -DestinationImagePath $CompressedBootWim -Compress maximum
    
    # Create ISO
    Write-Host "Creating ISO..." -ForegroundColor Cyan
    New-OSDCloudISO
}

try {
    Initialize-OSDCloudBuild
    Add-OSDCloudComponents
    Complete-OSDCloudBuild
    Write-Host "OSDCloud build completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Build failed: $_"
    exit 1
}
finally {
    Stop-Transcript
}