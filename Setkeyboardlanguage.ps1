$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-Set-KeyboardLanguage.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Ignore

Write-Host -ForegroundColor Green "Set keyboard language to en-US"
Start-Sleep -Seconds 5

$LanguageList = Get-WinUserLanguageList

$LanguageList.Add("en-US")
Set-WinUserLanguageList $LanguageList -Force

Start-Sleep -Seconds 5

Stop-Transcript