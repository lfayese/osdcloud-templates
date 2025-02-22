<# Gary Blok @gwblok
Generate Generic Computer Name based on Model Name... doesn't work well in Production as it names the machine after the model, so if you have more than one model.. it will get the same name.
This is used in my lab to name the PCs after the model, which makes life easier for me.

It creates randomly generated names for VMs following the the pattern "VM-CompanyName-Random 5 digit Number" - You would need to change how many digits this is if you have a longer company name.

NOTES.. Computer name can NOT be longer than 15 charaters.  There is no checking to ensure the name is under that limit.

#>

# Start logging
$Global:Transcript = "$((Get-Date).ToString('yyyy-MM-dd-HHmmss'))-CreateOSDComputerName.log"
Start-Transcript -Path (Join-Path "$env:ProgramData\Microsoft\IntuneManagementExtension\Logs\OSD\" $Global:Transcript) -ErrorAction Stop

function Get-SystemInfo {
    try {
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
        $bios = Get-WmiObject -Class Win32_BIOS -ErrorAction Stop
        return @{
            Manufacturer = $computerSystem.Manufacturer
            Model = $computerSystem.Model
            Serial = $bios.SerialNumber
        }
    } catch {
        throw "Failed to get system information: $_"
    }
}

function Format-ComputerName {
    param (
        [string]$name
    )
    # Remove invalid characters
    $invalid = '[^a-zA-Z0-9\-]'
    $name = $name -replace $invalid, ''
    
    # Ensure name length is valid (max 15 chars)
    if ($name.Length -gt 15) {
        $name = $name.Substring(0, 15)
    }
    return $name
}

try {
    Write-Host "Starting computer name generation process..."
    
    # Try to get Task Sequence environment
    try {
        $tsenv = New-Object -ComObject Microsoft.SMS.TSEnvironment
        Write-Host "Running in Task Sequence environment"
    } catch {
        Write-Host "Not running in Task Sequence environment"
        $tsenv = $null
    }

    # Get system information
    $sysInfo = Get-SystemInfo
    $Manufacturer = $sysInfo.Manufacturer
    $Model = $sysInfo.Model
    $Serial = $sysInfo.Serial
    $CompanyName = "BAH"

    Write-Host "System Information:"
    Write-Host "- Manufacturer: $Manufacturer"
    Write-Host "- Model: $Model"
    Write-Host "- Serial: $Serial"

    # Generate computer name based on manufacturer
    $ComputerName = switch -Regex ($Manufacturer) {
        "Lenovo" {
            $modelVersion = (Get-CimInstance -ClassName Win32_ComputerSystemProduct).Version
            if ($modelVersion) {
                $modelNumber = $modelVersion.Split(" ")[1]
                Format-ComputerName "$($Manufacturer)-$modelNumber"
            } else {
                throw "Could not determine Lenovo model version"
            }
        }
        "HP|Hewlett-Packard" {
            $Manufacturer = "HP"
            $name = $Model

            # Replace common strings with abbreviations
            $replacements = @{
                " Desktop PC" = ""
                "EliteDesk" = "ED"
                "EliteBook" = "EB"
                "Elite Mini" = "EM"
                "Elite x360" = "EBX"
                "ProDesk" = "PD"
                "ProBook" = "PB"
                "ZBook" = "ZB"
            }

            foreach ($key in $replacements.Keys) {
                $name = $name.Replace($key, $replacements[$key])
            }

            # Special handling for Elite x360
            if ($Model -match "Elite x360") {
                $size = $Model.Split(" ")[2]
                $generation = $Model.Split(" ") | Where-Object { $_ -match "G" }
                $name = "EBX$size$generation"
            }

            $name = $name -replace '\s+', ''
            $name = Format-ComputerName $name

            # Add serial number suffix if name is too short
            if ($name.Length -lt 15) {
                $extraLength = 15 - $name.Length - 1
                $serialSuffix = $Serial.Substring($Serial.Length - $extraLength, $extraLength)
                $name = "$name-$serialSuffix"
            }
            $name
        }
        "Dell" {
            $name = $Model -replace "Latitude", "L" `
                          -replace "OptiPlex", "O" `
                          -replace "Precision", "P" `
                          -replace "Tower", "T" `
                          -replace '\s+', '-'

            if ($name -match "T") {
                $parts = $name.Split("-") | Select-Object -First 3
                Format-ComputerName "Dell-$($parts -join '-')"
            } else {
                $parts = $name.Split("-") | Select-Object -First 2
                Format-ComputerName "Dell-$($parts -join '-')"
            }
        }
        "Microsoft" {
            if ($Model -match "Virtual") {
                $random = Get-Random -Maximum 99999
                Format-ComputerName "VM-$CompanyName-$random"
            } else {
                throw "Unexpected Microsoft model: $Model"
            }
        }
        default {
            # Fallback to serial number
            Format-ComputerName $Serial
        }
    }

    Write-Host "====================================================="
    Write-Host "Generated computer name: $ComputerName"
    Write-Host "====================================================="

    # Set the computer name in the task sequence if available
    if ($tsenv) {
        $tsenv.Value('OSDComputerName') = $ComputerName
        Write-Host "Set OSDComputerName in task sequence"
    }

    # Validate the final computer name
    if ($ComputerName.Length -gt 15) {
        throw "Generated computer name exceeds 15 characters: $ComputerName"
    }
    if ($ComputerName -match '[^a-zA-Z0-9\-]') {
        throw "Generated computer name contains invalid characters: $ComputerName"
    }

} catch {
    Write-Error "Failed to generate computer name: $_"
    exit 1
} finally {
    Stop-Transcript
}