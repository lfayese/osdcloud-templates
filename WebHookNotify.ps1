function Invoke-Webhook {
    $BiosSerialNumber = Get-MyBiosSerialNumber
    $ComputerManufacturer = Get-MyComputerManufacturer
    $ComputerModel = Get-MyComputerModel
    
    $URI = ''
    $JSON = @{
        "@type"    = "MessageCard"
        "@context" = "<http://schema.org/extensions>"
        "title"    = 'OSDCloud Information'
        "text"     = "The following client has been successfully deployed:<br>
                    BIOS Serial Number: **$($BiosSerialNumber)**<br>
                    Computer Manufacturer: **$($ComputerManufacturer)**<br>
                    Computer Model: **$($ComputerModel)**"
        } | ConvertTo-JSON
        
        $Params = @{
        "URI"         = $URI
        "Method"      = 'POST'
        "Body"        = $JSON
        "ContentType" = 'application/json'
        }
        Invoke-RestMethod @Params | Out-Null
}

Invoke-Webhook