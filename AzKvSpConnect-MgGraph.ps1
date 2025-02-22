###############################################################################################################
######                                         Set Variables                                             ######
###############################################################################################################

$tenantid = ""
$appid = ""
$vaultname = ""
$certname = ""

###############################################################################################################
######                                         Install Modules                                           ######
###############################################################################################################
Write-Output "Installing Intune modules if required (current user scope)"
# Get NuGet
$provider = Get-PackageProvider NuGet -ErrorAction Ignore
if (-not $provider) {
    Write-Host "Installing provider NuGet"
    Find-PackageProvider -Name NuGet -ForceBootstrap -IncludeDependencies
}

Write-Output "Installing Microsoft Graph Authentication modules if required (current user scope)"

# Install Graph Groups module if not available
Install-Module -Name Microsoft.Graph.Authentication -Repository PSGallery -Force -AllowClobber -Scope AllUsers

# Install Az.Accounts module if not available
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module -Name Az.Accounts -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -RequiredVersion 2.12.1
}

# Install Az.KeyVault module if not available
if (-not (Get-Module -ListAvailable -Name Az.KeyVault)) {
    Install-Module -Name Az.KeyVault -Scope CurrentUser -Repository PSGallery -Force -AllowClobber -RequiredVersion 4.9.2
}

Import-Module Microsoft.Graph.Authentication
Import-Module Az.KeyVault
Import-Module Az.Accounts

###############################################################################################################
######                                            Connect                                                ######
###############################################################################################################

## Get the certificate from the key vault
Write-Host "Getting certificate from the key vault"
# Connect using a Managed Service Identity
$AzureContext = Invoke-Expression (Invoke-WebRequest -Uri "https://AzSpConnect-AzAccount.ps1" -UseBasicParsing).Content

Set-AzContext -Subscription "4dc12530-2664-4d5a-853b-c32a1c90b2da"

$CertBase64 = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $certName 
$thumbprint = $certbase64.thumbprint

## Connect to Graph
Write-Host "Connecting to Graph"
Connect-MgGraph -TenantId $tenantid -ClientId $appid -CertificateThumbprint $thumbprint -ContextScope Process
Write-Host "Connected to Microsoft Graph!!"