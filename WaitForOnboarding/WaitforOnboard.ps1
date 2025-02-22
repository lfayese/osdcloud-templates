# Script to track the process HYbrid Join, MDM enrollment, Defender for endpoint omboarding.

$logfilepath="$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\DefenderOnboarding.log"

function WriteToLogFile ($message)
{
$message +" - "+ (Get-Date).ToString() >> $logfilepath
}

WriteToLogFile "Script started"

do {
    $AADInfo = Get-Item "HKLM:/SYSTEM/CurrentControlSet/Control/CloudDomainJoin/JoinInfo"

$guids = $AADInfo.GetSubKeyNames()
foreach ($guid in $guids) {
    $guidSubKey = $AADinfo.OpenSubKey($guid);
    $DeviceDisplayName = ($Null -ne $guidSubKey.GetValue("DeviceDisplayName")
        )
       Start-Sleep -Seconds 1
    }
} while (
    $DeviceDisplayName -ne "True")
    WriteToLogFile "Hybrid Joined"

do {
    $MDMEnrollment = $Null -ne (Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Provisioning\OMADM\MDMDeviceID).DeviceClientID
    Start-Sleep -Seconds 1
} while (
    $MDMEnrollment -ne "True")
    WriteToLogFile "Enrolled in MDM"

do {
       $MDEState = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows Advanced Threat Protection\Status").onboardingstate -eq "1"
       Start-Sleep -Seconds 1
} while (
    $MDEState -ne "True")
    WriteToLogFile "Onboarded to Defender for endpoint"

Unregister-ScheduledTask -TaskName waitforonboarding -Confirm:$false