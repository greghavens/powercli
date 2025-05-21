#Requires -Modules VMware.PowerCLI

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$CsvPath
)

# Function to handle errors
function Write-Log {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Type] $Message"
}

# Import CSV file
try {
    $vcenters = Import-Csv -Path $CsvPath
    Write-Log "Successfully imported CSV file: $CsvPath"
} catch {
    Write-Log "Failed to import CSV file: $_" -Type "ERROR"
    exit 1
}

# Process each vCenter
foreach ($vc in $vcenters) {
    try {
        Write-Log "Processing vCenter: $($vc.Hostname)"
        
        # Connect to vCenter
        Connect-VIServer -Server $vc.Hostname -ErrorAction Stop
        
        # Get the license manager
        $licenseManager = Get-View LicenseManager
        
        # Add the license
        $licenseManager.AddLicense($vc.LicenseKey, $null)
        
        # Verify the license was added
        $licenses = $licenseManager.Licenses | Where-Object { $_.LicenseKey -eq $vc.LicenseKey }
        if ($licenses) {
            Write-Log "Successfully added license for $($vc.Hostname)"
        } else {
            Write-Log "License was not found after adding for $($vc.Hostname)" -Type "WARNING"
        }
        
        # Disconnect from vCenter
        Disconnect-VIServer -Server $vc.Hostname -Confirm:$false
        
    } catch {
        Write-Log "Error processing $($vc.Hostname): $_" -Type "ERROR"
        continue
    }
}

Write-Log "License assignment process completed" 