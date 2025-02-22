# Boot Configuration and WiFi Setup Script
[CmdletBinding()]
param(
    [Parameter()]
    [string]$WifiSSID,
    
    [Parameter()]
    [string]$WifiPassword,
    
    [Parameter()]
    [switch]$PersistentConnection
)

# Function to enable and configure wireless components in WinPE
function Enable-WinPEWireless {
    Write-Host "Enabling wireless components..." -ForegroundColor Cyan
    
    # Start WLAN AutoConfig service
    Start-Service -Name "wlansvc" -ErrorAction SilentlyContinue
    
    # Wait for service to be ready
    $Timeout = 30
    $Timer = 0
    while ((Get-Service -Name "wlansvc").Status -ne 'Running' -and $Timer -lt $Timeout) {
        Start-Sleep -Seconds 1
        $Timer++
    }
    
    if ((Get-Service -Name "wlansvc").Status -ne 'Running') {
        throw "Failed to start WLAN service"
    }
}

# Function to create wireless profile
function New-WirelessProfile {
    param(
        [string]$SSID,
        [string]$Password
    )
    
    $ProfileXML = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
    <name>$SSID</name>
    <SSIDConfig>
        <SSID>
            <name>$SSID</name>
        </SSID>
    </SSIDConfig>
    <connectionType>ESS</connectionType>
    <connectionMode>auto</connectionMode>
    <MSM>
        <security>
            <authEncryption>
                <authentication>WPA2PSK</authentication>
                <encryption>AES</encryption>
                <useOneX>false</useOneX>
            </authEncryption>
            <sharedKey>
                <keyType>passPhrase</keyType>
                <protected>false</protected>
                <keyMaterial>$Password</keyMaterial>
            </sharedKey>
        </security>
    </MSM>
</WLANProfile>
"@
    
    # Save profile to file
    $ProfilePath = "$env:TEMP\WiFiProfile.xml"
    $ProfileXML | Out-File -FilePath $ProfilePath -Encoding ASCII
    
    return $ProfilePath
}

# Function to connect to wireless network
function Connect-WirelessNetwork {
    param(
        [string]$SSID,
        [string]$ProfilePath
    )
    
    try {
        # Add the wireless profile
        $Output = netsh wlan add profile filename="$ProfilePath"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add wireless profile"
        }
        
        # Connect to the network
        $Output = netsh wlan connect name="$SSID"
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to connect to wireless network"
        }
        
        # Wait for connection
        $Timeout = 60
        $Timer = 0
        $Connected = $false
        
        Write-Host "Waiting for wireless connection..." -ForegroundColor Cyan
        while (-not $Connected -and $Timer -lt $Timeout) {
            $Status = netsh wlan show interfaces
            if ($Status -match "State\s+:\s+connected") {
                $Connected = $true
            }
            else {
                Start-Sleep -Seconds 1
                $Timer++
            }
        }
        
        return $Connected
    }
    finally {
        # Cleanup profile file
        if (Test-Path $ProfilePath) {
            Remove-Item -Path $ProfilePath -Force
        }
    }
}

# Function to verify internet connectivity
function Test-InternetConnectivity {
    $TestUrls = @(
        "8.8.8.8",  # Google DNS
        "1.1.1.1"   # Cloudflare DNS
    )
    
    foreach ($Url in $TestUrls) {
        if (Test-Connection -ComputerName $Url -Count 1 -Quiet) {
            return $true
        }
    }
    return $false
}

try {
    Write-Host "Starting wireless network configuration..." -ForegroundColor Cyan
    
    # Check if running in WinPE
    $IsWinPE = Test-Path -Path Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\MiniNT
    if (-not $IsWinPE) {
        Write-Warning "This script is designed to run in WinPE environment"
    }
    
    # Enable wireless components
    Enable-WinPEWireless
    
    # If WiFi credentials are provided, attempt connection
    if ($WifiSSID -and $WifiPassword) {
        $ProfilePath = New-WirelessProfile -SSID $WifiSSID -Password $WifiPassword
        
        if (Connect-WirelessNetwork -SSID $WifiSSID -ProfilePath $ProfilePath) {
            Write-Host "Successfully connected to wireless network" -ForegroundColor Green
            
            # Test internet connectivity
            if (Test-InternetConnectivity) {
                Write-Host "Internet connectivity verified" -ForegroundColor Green
            }
            else {
                Write-Warning "Connected to wireless network but no internet connectivity detected"
            }
        }
        else {
            throw "Failed to connect to wireless network"
        }
    }
    else {
        Write-Host "No wireless credentials provided. Manual configuration required." -ForegroundColor Yellow
    }
    
    Write-Host "Wireless configuration completed!" -ForegroundColor Green
}
catch {
    Write-Error "An error occurred during wireless configuration: $_"
    exit 1
}