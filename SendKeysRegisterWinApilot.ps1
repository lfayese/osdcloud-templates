# Define the script folder path and the path for SendKeys script
$scriptFolderPath = "$env:TEMP\OSDCloud\Scripts"
$ScriptPathSendKeys = Join-Path -Path $scriptFolderPath -ChildPath "SendKeys.ps1"

# Check if the script folder path exists, if not, create it
if (!(Test-Path -Path $scriptFolderPath -PathType Container)) {
    $null = New-Item -Path $scriptFolderPath -ItemType Directory -Force
}

# Define the script block for SendKeys script
$SendKeysScript = @"
`$Global:Transcript = "`$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-SendKeys.log"
Start-Transcript -Path (Join-Path `"$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD`" `$Global:Transcript) -ErrorAction Ignore

Write-Host -ForegroundColor DarkGray "Stop Debug-Mode (SHIFT + F10) with WscriptShell.SendKeys"
`$WscriptShell = New-Object -ComObject WScript.Shell

# ALT + TAB
Write-Host -ForegroundColor DarkGray "SendKeys: ALT + TAB"
`$WscriptShell.SendKeys("%({TAB})")

Start-Sleep -Seconds 1

# Shift + F10
Write-Host -ForegroundColor DarkGray "SendKeys: SHIFT + F10"
`$WscriptShell.SendKeys("+({F10})")

Invoke-Expression (Invoke-RestMethod -Uri 'https://start-winautopilotreg.ps1')

Stop-Transcript -Verbose
"@

# Write the SendKeys script to the file
$SendKeysScript | Set-Content -Path $ScriptPathSendKeys -Encoding ascii

# Start a new PowerShell process and execute SendKeys script
Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-File", `"$ScriptPathSendKeys`" -Wait
