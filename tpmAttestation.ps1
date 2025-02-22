# TPM Attestation and Configuration Script
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Force,
    
    [Parameter()]
    [switch]$Clear
)

# Function to get detailed TPM information
function Get-DetailedTPMStatus {
    $TPM = Get-Tpm
    $WmiTPM = Get-WmiObject -Namespace "root\cimv2\security\microsofttpm" -Class Win32_TPM
    
    return @{
        IsPresent = $TPM.TpmPresent
        IsEnabled = $TPM.TpmEnabled
        IsActivated = $TPM.TpmActivated
        IsReady = $TPM.TpmReady
        SpecVersion = $WmiTPM.SpecVersion
        ManufacturerId = $WmiTPM.ManufacturerId
        PhysicalPresenceVersionInfo = $WmiTPM.PhysicalPresenceVersionInfo
    }
}

# Function to verify TPM meets Windows 11 requirements
function Test-TPMWindows11Compatibility {
    $TPMInfo = Get-DetailedTPMStatus
    
    # Windows 11 requires TPM 2.0
    if ($TPMInfo.SpecVersion -match "2.0") {
        return $true
    }
    return $false
}

# Function to attempt TPM initialization
function Initialize-TPMChip {
    param([switch]$Force)
    
    try {
        if ($Force) {
            Initialize-Tpm -AllowClear -AllowPhysicalPresence
        } else {
            Initialize-Tpm
        }
        return $true
    }
    catch {
        Write-Error "Failed to initialize TPM: $_"
        return $false
    }
}

# Function to clear TPM if requested
function Clear-TPMChip {
    try {
        Clear-Tpm -AllowPhysicalPresence
        return $true
    }
    catch {
        Write-Error "Failed to clear TPM: $_"
        return $false
    }
}

# Function to enable BitLocker with TPM
function Enable-BitLockerWithTPM {
    $SystemDrive = $env:SystemDrive
    
    try {
        # Check if BitLocker is already enabled
        $BitLockerVolume = Get-BitLockerVolume -MountPoint $SystemDrive
        if ($BitLockerVolume.ProtectionStatus -eq "On") {
            Write-Host "BitLocker is already enabled on $SystemDrive" -ForegroundColor Green
            return $true
        }
        
        # Enable BitLocker using TPM
        Enable-BitLocker -MountPoint $SystemDrive -TpmProtector -UsedSpaceOnly
        Enable-BitLocker -MountPoint $SystemDrive -RecoveryPasswordProtector
        
        return $true
    }
    catch {
        Write-Error "Failed to enable BitLocker: $_"
        return $false
    }
}

# Start logging
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Test-Autopilotattestation.log"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD"
if (!(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}
Start-Transcript -Path (Join-Path $LogPath $Global:Transcript) -ErrorAction Stop

try {
    Write-Host "Starting TPM attestation and configuration..." -ForegroundColor Cyan
    
    # Get current TPM status
    $TPMStatus = Get-DetailedTPMStatus
    
    # Display current TPM information
    Write-Host "`nCurrent TPM Status:" -ForegroundColor Cyan
    Write-Host "==================="
    $TPMStatus.GetEnumerator() | ForEach-Object {
        Write-Host "$($_.Key): $($_.Value)"
    }
    
    # Check Windows 11 compatibility
    $Win11Compatible = Test-TPMWindows11Compatibility
    Write-Host "`nWindows 11 TPM Compatibility: " -NoNewline
    if ($Win11Compatible) {
        Write-Host "Compatible" -ForegroundColor Green
    } else {
        Write-Host "Not Compatible" -ForegroundColor Red
    }
    
    # Process TPM operations based on parameters
    if ($Clear) {
        Write-Host "`nClearing TPM..." -ForegroundColor Yellow
        if (Clear-TPMChip) {
            Write-Host "TPM cleared successfully" -ForegroundColor Green
        }
    }
    elseif (-not $TPMStatus.IsReady -or $Force) {
        Write-Host "`nInitializing TPM..." -ForegroundColor Yellow
        if (Initialize-TPMChip -Force:$Force) {
            Write-Host "TPM initialized successfully" -ForegroundColor Green
        }
    }
    
    # Configure BitLocker if TPM is ready
    if ($TPMStatus.IsReady) {
        Write-Host "`nConfiguring BitLocker with TPM..." -ForegroundColor Yellow
        if (Enable-BitLockerWithTPM) {
            Write-Host "BitLocker configured successfully" -ForegroundColor Green
        }
    }
    
    Write-Host "`nTPM attestation and configuration completed!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during TPM attestation: $_"
    exit 1
}
finally {
    Stop-Transcript
}