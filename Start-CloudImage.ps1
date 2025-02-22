# Check if the script is running in an administrative context
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run this script as an Administrator!" -ForegroundColor Red
    return
}

# Function to install or update the OSD module
function Install-OrUpdateOSDModule {
    $moduleName = "OSD"
    $module = Get-Module -Name $moduleName -ListAvailable

    if (!$module) {
        Write-Host "Installing the $moduleName PowerShell Module" -ForegroundColor Cyan
        Install-Module $moduleName -Force -Scope AllUsers
    }
    else {
        Write-Host "Updating the $moduleName PowerShell Module" -ForegroundColor Cyan
        Update-Module $moduleName -Force
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to $($module ? 'update' : 'install') the $moduleName module. Please check your internet connection and try again."
        return $false
    }

    Write-Host "$moduleName PowerShell Module $($module ? 'updated' : 'installed') successfully" -ForegroundColor Green
    return $true
}

# Check and update/install the OSD module
if (-not (Install-OrUpdateOSDModule)) {
    return
}

# Import OSDCloud Module
try {
    Write-Host "Importing the OSDCloud PowerShell Module" -ForegroundColor Cyan
    Import-Module OSDCloud -ErrorAction Stop
    Write-Host "OSDCloud PowerShell Module imported successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to import OSDCloud module. Please ensure it's available in the WinPE environment."
    return
}

# Main Menu
$menu = @(
    "1: Start the OSDCloud process with the FindImageFile parameter",
    "2: Start the legacy OSDCloud CLI (Start-OSDCloud)",
    "3: Start the graphical OSDCloud (Start-OSDCloudGUI)",
    #"4: Windows Custom WIMs (Azure storage file share)",
    "0: Exit",
    "99: Reload !!!"
)
Write-Host "================ Main Menu ==================" -ForegroundColor Yellow
Write-Host "Welcome To Workplace OSDCloud Image"
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "=============================================`n" -ForegroundColor Yellow
$menu | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
Write-Host "`n DISCLAIMER: USE AT YOUR OWN RISK - Going further will erase all data on your disk ! `n"-ForegroundColor Red

# User Input
$userInput = Read-Host "Please make a selection"

# Switch based on user input
switch ($userInput) {
    '1' {
        try {
            Write-Host "Starting OSDCloud with FindImageFile parameter" -ForegroundColor Cyan
            Start-OSDCloud -FindImageFile -ErrorAction Stop
            Write-Host "OSDCloud process completed successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "An error occurred while executing Start-OSDCloud: $_"
            return
        }
    }
    '2' { Start-OSDCloud } 
    '3' { Start-OSDCloudGUI }
    #'4' {
    #    # Connect Azure Storage file share for custom DELL WIM access
    #    Write-Host -ForegroundColor Yellow "Connect to Azure File Share ..."
    #    $storageAccountName = ""
    #    $storageKey = "" | ConvertTo-SecureString
    #    $storageCredential = New-Object System.Management.Automation.PSCredential -ArgumentList ($storageAccountName, $storageKey)
    #    $storageContext = New-AzStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey
    #    Set-AzStorageAccount -Name $storageAccountName -Context $storageContext
    #    Write-Host -ForegroundColor Yellow "Mounting drive O: ..."
    #    try {
    #        New-PSDrive -Name O -PSProvider FileSystem -Root "\\osdcloud.file.core.windows.net\osdcloud-fs" -Credential $storageCredential -Scope Global
    #        Write-Host -ForegroundColor Green "Drive O: mounted successfully."
    #        Start-OSDCloud -FindImageFile -ZTI -Verbose
    #    } catch {
    #        Write-Host -ForegroundColor Red "Failed to mount drive O:."
    #    }
    #}
    '0' { Exit }
    '99' {
        try {
            Invoke-Expression (Invoke-RestMethod 'URL_TO_SCRIPT_FILE')
        }
        catch {
            Write-Error "Failed to execute the script. Please check the URL and try again."
            return
        }
    }
    default {
        Write-Error "Invalid selection. Please try again."
        return
    }
}

# Reboot WinPE
try {
    wpeutil reboot
}
catch {
    Write-Error "Failed to reboot WinPE. Please reboot manually."
}