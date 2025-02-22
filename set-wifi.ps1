param(
    [string]$SSID = "wifi-ssid",
    [string]$PSK = "password"
)
$guid = New-Guid
$HexArray = $ssid.ToCharArray() | foreach-object { [System.String]::Format("{0:X}", [System.Convert]::ToUInt32($_)) }
$HexSSID = $HexArray -join ""
@"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>$($SSID)</name>
	<SSIDConfig>
		<SSID>
			<hex>$($HexSSID)</hex>
			<name>$($SSID)</name>
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
				<keyMaterial>$($PSK)</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
	<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
		<enableRandomization>false</enableRandomization>
		<randomizationSeed>1451755948</randomizationSeed>
	</MacRandomization>
</WLANProfile>
"@ | out-file "$($ENV:TEMP)\$guid.SSID"

netsh wlan add profile filename="$($ENV:TEMP)\$guid.SSID" user=all

remove-item "$($ENV:TEMP)\$guid.SSID" -Force

Get-Service -Name WlanSvc | Start-Service
$WirelessAdapters = Get-NetAdapter | Where-Object {($_.PhysicalMediaType -eq 'Native 802.11') -or ($_.PhysicalMediaType -eq 'Wireless LAN')}
if ($WirelessAdapters){Set-WiFi -SSID $SSID -PSK $PSK}