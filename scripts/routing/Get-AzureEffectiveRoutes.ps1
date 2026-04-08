[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$NicName,

    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup
)

# ===== Logging =====
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$timestamp [$Level] $Message"
}

Write-Log "Starting effective route check"

# ===== Get NIC =====
try {
    Write-Log "Retrieving NIC: $NicName"

    $nic = Get-AzNetworkInterface -Name $NicName -ResourceGroupName $ResourceGroup

    if (-not $nic) {
        throw "NIC not found"
    }
}
catch {
    Write-Log "Failed to retrieve NIC: $_" "ERROR"
    exit 1
}

# ===== Get Routes =====
try {
    Write-Log "Getting effective routes..."

    $routes = Get-AzEffectiveRouteTable -NetworkInterface $nic
}
catch {
    Write-Log "Failed to retrieve routes: $_" "ERROR"
    exit 1
}

# ===== Output =====
Write-Host ""
Write-Host "Effective Routes:" -ForegroundColor Yellow

$routes.Value | Select-Object AddressPrefix, NextHopType, NextHopIpAddress | Format-Table -AutoSize

# ===== Highlight important routes =====
Write-Host ""
Write-Host "Important Routes (Firewall / Internet):" -ForegroundColor Cyan

$routes.Value |
Where-Object { $_.NextHopType -eq "VirtualAppliance" -or $_.NextHopType -eq "Internet" } |
Select-Object AddressPrefix, NextHopType, NextHopIpAddress |
Format-Table -AutoSize

Write-Log "Route check completed"