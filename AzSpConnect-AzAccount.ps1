# Check and set the execution policy
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -ne 'RemoteSigned') {
    Write-Host "Setting policy to RemoteSigned."
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
} else {
    Write-Host "RemoteSigned policy already set."
}

# Authenticate to Azure with Service Principal credentials
$ClientId = "" # Replace with your Client ID
$ClientSecret = ConvertTo-SecureString "" -AsPlainText -Force # Replace with your Client Secret
$TenantId = "" # Replace with your Tenant ID
$SecureSecret = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ClientId, $ClientSecret

# Authenticate using Service Principal credentials
try {
    Connect-AzAccount -ServicePrincipal -Credential $SecureSecret -Tenant $TenantId
    Set-AzContext -Subscription ""
    Write-Host "Connected to Azure successfully."
} catch {
    Write-Error "Error connecting to Azure: $_"
}
Chat