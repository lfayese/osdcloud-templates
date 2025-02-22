# Start logging
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Start-CloudImage.log"
$LogPath = "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD"
if (!(Test-Path $LogPath)) {
    New-Item -Path $LogPath -ItemType Directory -Force | Out-Null
}
Start-Transcript -Path (Join-Path $LogPath $Global:Transcript) -ErrorAction Stop

function Test-AdminRights {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        throw "This script requires Administrator privileges"
    }
}

function Install-OrUpdateOSDModule {
    param(
        [string]$ModuleName = "OSD"
    )
    try {
        $module = Get-Module -Name $ModuleName -ListAvailable
        if (-not $module) {
            Write-Host "Installing $ModuleName PowerShell Module..." -ForegroundColor Cyan
            Install-Module $ModuleName -Force -Scope AllUsers -ErrorAction Stop
            Write-Host "$ModuleName module installed successfully" -ForegroundColor Green
        } else {
            Write-Host "Updating $ModuleName PowerShell Module..." -ForegroundColor Cyan
            Update-Module $ModuleName -Force -ErrorAction Stop
            Write-Host "$ModuleName module updated successfully" -ForegroundColor Green
        }
        return $true
    } catch {
        Write-Error "Failed to manage $ModuleName module: $_"
        return $false
    }
}

function Show-Menu {
    $header = @"
================ Main Menu ==================
Welcome To Workplace OSDCloud Image
=============================================
=============================================

"@
    $menu = @(
        "1: Start the OSDCloud process with FindImageFile parameter"
        "2: Start the legacy OSDCloud CLI (Start-OSDCloud)"
        "3: Start the graphical OSDCloud (Start-OSDCloudGUI)"
        "0: Exit"
        "99: Reload !!!"
    )
    
    Write-Host $header -ForegroundColor Yellow
    $menu | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
    Write-Host "`n DISCLAIMER: USE AT YOUR OWN RISK - Going further will erase all data on your disk !`n" -ForegroundColor Red -BackgroundColor Black
}

function Start-OSDCloudProcess {
    param(
        [string]$Option
    )
    
    try {
        switch ($Option) {
            '1' {
                Write-Host "Starting OSDCloud with FindImageFile parameter..." -ForegroundColor Cyan
                Start-OSDCloud -FindImageFile -ErrorAction Stop
            }
            '2' {
                Write-Host "Starting legacy OSDCloud CLI..." -ForegroundColor Cyan
                Start-OSDCloud -ErrorAction Stop
            }
            '3' {
                Write-Host "Starting OSDCloud GUI..." -ForegroundColor Cyan
                Start-OSDCloudGUI -ErrorAction Stop
            }
            '99' {
                Write-Host "Reloading from USB drive..." -ForegroundColor Cyan
                $usbScript = 'X:\OSDCloud\Scripts\Start-CloudImage.ps1'
                if (Test-Path $usbScript) {
                    & $usbScript
                } else {
                    throw "USB script not found at: $usbScript"
                }
            }
            default {
                throw "Invalid option: $Option"
            }
        }
        Write-Host "OSDCloud process completed successfully" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to execute OSDCloud process: $_"
        return $false
    }
}

function Restart-WinPE {
    try {
        Write-Host "Initiating WinPE reboot..." -ForegroundColor Cyan
        Stop-Transcript
        Start-Sleep -Seconds 3  # Give time for transcript to complete
        wpeutil reboot
    } catch {
        Write-Error "Failed to reboot WinPE: $_. Please reboot manually."
    }
}

# Main execution block
try {
    # Check admin rights
    Test-AdminRights

    # Install/Update and Import OSD module
    if (-not (Install-OrUpdateOSDModule)) {
        throw "Failed to prepare OSD module"
    }

    try {
        Write-Host "Importing OSDCloud module..." -ForegroundColor Cyan
        Import-Module OSDCloud -Force -ErrorAction Stop
        Write-Host "OSDCloud module imported successfully" -ForegroundColor Green
    } catch {
        throw "Failed to import OSDCloud module: $_"
    }

    # Show menu and get user input
    do {
        Show-Menu
        $userInput = Read-Host "Please make a selection"
        
        if ($userInput -eq '0') {
            Write-Host "Exiting..." -ForegroundColor Yellow
            break
        }
        
        if (Start-OSDCloudProcess -Option $userInput) {
            Restart-WinPE
            break
        }
        
        Write-Host "Press Enter to continue..." -ForegroundColor Yellow
        $null = Read-Host
        Clear-Host
        
    } while ($true)

} catch {
    Write-Error "Script execution failed: $_"
    exit 1
} finally {
    Stop-Transcript
}