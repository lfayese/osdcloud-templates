# Start logging
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-WebHookNotify.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Stop

function Get-MyBiosSerialNumber {
    try {
        return (Get-WmiObject -Class Win32_BIOS).SerialNumber
    } catch {
        Write-Warning "Failed to get BIOS Serial Number: $_"
        return "Unknown"
    }
}

function Get-MyComputerManufacturer {
    try {
        return (Get-WmiObject -Class Win32_ComputerSystem).Manufacturer
    } catch {
        Write-Warning "Failed to get Computer Manufacturer: $_"
        return "Unknown"
    }
}

function Get-MyComputerModel {
    try {
        return (Get-WmiObject -Class Win32_ComputerSystem).Model
    } catch {
        Write-Warning "Failed to get Computer Model: $_"
        return "Unknown"
    }
}

function Invoke-Webhook {
    param(
        [Parameter(Mandatory=$true)]
        [string]$URI
    )
    
    try {
        Write-Host "Gathering system information..."
        $BiosSerialNumber = Get-MyBiosSerialNumber
        $ComputerManufacturer = Get-MyComputerManufacturer
        $ComputerModel = Get-MyComputerModel
        $ComputerName = $env:COMPUTERNAME
        
        Write-Host "Preparing webhook payload..."
        $JSON = @{
            "@type" = "MessageCard"
            "@context" = "http://schema.org/extensions"
            "title" = "OSDCloud Deployment Complete"
            "text" = @"
The following client has been successfully deployed:
- Computer Name: **$($ComputerName)**
- BIOS Serial Number: **$($BiosSerialNumber)**
- Computer Manufacturer: **$($ComputerManufacturer)**
- Computer Model: **$($ComputerModel)**
- Deployment Time: **$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')**
"@
            "themeColor" = "0072C6"
        } | ConvertTo-Json
        
        Write-Host "Sending webhook notification..."
        $Params = @{
            "URI" = $URI
            "Method" = 'POST'
            "Body" = $JSON
            "ContentType" = 'application/json'
        }
        
        $result = Invoke-RestMethod @Params -ErrorAction Stop
        Write-Host "Webhook notification sent successfully"
        return $result
        
    } catch {
        Write-Error "Failed to send webhook notification: $_"
        throw
    }
}

# Main execution
try {
    # The URI should be set in a configuration file or passed as a parameter
    $webhookUri = '' # Set your webhook URI here
    if ([string]::IsNullOrWhiteSpace($webhookUri)) {
        Write-Warning "No webhook URI configured - notification will be skipped"
    } else {
        Invoke-Webhook -URI $webhookUri
    }
} catch {
    Write-Error "Script execution failed: $_"
    exit 1
} finally {
    Stop-Transcript
}