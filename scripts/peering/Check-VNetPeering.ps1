[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$VNetName,

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

# ===== Ensure Azure Login =====
function Test-AzureLogin {
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Log "Not logged into Azure. Prompting login..." "WARN"
            Connect-AzAccount | Out-Null
        }
        else {
            Write-Log "Using Azure context: $($context.Account)"
        }
    }
    catch {
        Write-Log "Error checking Azure login: $_" "ERROR"
        exit 1
    }
}

# ===== Get Peerings =====
function Get-Peerings {
    param (
        [string]$VNetName,
        [string]$ResourceGroup
    )

    try {
        Write-Log "Retrieving peerings for VNet: $VNetName"

        $peerings = Get-AzVirtualNetworkPeering -VirtualNetworkName $VNetName -ResourceGroupName $ResourceGroup

        if (-not $peerings) {
            Write-Log "No peerings found" "WARN"
        }

        return $peerings
    }
    catch {
        Write-Log "Failed to retrieve peerings: $_" "ERROR"
        exit 1
    }
}

# ===== Analyse Peerings =====
function Get-PeeringAnalysis {
    param (
        [array]$Peerings
    )

    foreach ($p in $Peerings) {

        $issues = @()

        if ($p.PeeringState -ne "Connected") {
            $issues += "Peering not connected"
        }

        if (-not $p.AllowForwardedTraffic) {
            $issues += "Forwarded traffic disabled"
        }

        if ($p.UseRemoteGateways -and -not $p.AllowGatewayTransit) {
            $issues += "Gateway transit misconfiguration"
        }

        [PSCustomObject]@{
            Name                  = $p.Name
            PeeringState          = $p.PeeringState
            AllowForwardedTraffic = $p.AllowForwardedTraffic
            AllowGatewayTransit   = $p.AllowGatewayTransit
            UseRemoteGateways     = $p.UseRemoteGateways
            Issues                = if ($issues.Count -gt 0) { $issues -join "; " } else { "None" }
        }
    }
}

# ===== Execution =====
Write-Log "Starting VNet peering check"

Test-AzureLogin

$peerings = Get-Peerings -VNetName $VNetName -ResourceGroup $ResourceGroup

$analysis = Get-PeeringAnalysis -Peerings $peerings

Write-Log "Peering analysis complete"

# ===== Output =====
Write-Host ""
Write-Host "VNet Peering Status:" -ForegroundColor Yellow

$analysis | Format-Table -AutoSize

# ===== Highlight issues =====
Write-Host ""
Write-Host "Potential Issues:" -ForegroundColor Red

$analysis | Where-Object { $_.Issues -ne "None" } | Format-Table -AutoSize