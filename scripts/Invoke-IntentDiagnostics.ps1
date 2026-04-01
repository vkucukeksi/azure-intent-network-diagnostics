[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Intent,

    [string]$TargetIP,
    [string]$Hostname,
    [string]$NicName,
    [string]$VNetName,
    [string]$ResourceGroup
)

function Write-Section {
    param ([string]$Title)

    Write-Host ""
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "===================================="
}

Write-Host "Intent Received: $Intent" -ForegroundColor Yellow

$intentLower = $Intent.ToLower()

# ===== Decision Logic =====

$runConnectivity = $false
$runDNS = $false
$runRouting = $false
$runPeering = $false

if ($intentLower -match "cannot connect|timeout|reach") {
    $runConnectivity = $true
    $runRouting = $true
}

if ($intentLower -match "dns|resolve|hostname|private endpoint") {
    $runDNS = $true
}

if ($intentLower -match "route|udr|firewall") {
    $runRouting = $true
}

if ($intentLower -match "peering|vnet") {
    $runPeering = $true
}

# ===== Execution =====

Write-Section "Selected Diagnostics"

if ($runConnectivity) { Write-Host "- Connectivity Test" }
if ($runDNS)         { Write-Host "- DNS Check" }
if ($runRouting)     { Write-Host "- Route Analysis" }
if ($runPeering)     { Write-Host "- VNet Peering Check" }

# ===== Run Selected Checks =====

if ($runConnectivity -and $TargetIP) {
    Write-Section "Connectivity Test"
    .\Test-VNetConnectivity.ps1 -TargetIP $TargetIP
}

if ($runDNS -and $Hostname) {
    Write-Section "DNS Test"
    .\Test-AzureDNS.ps1 -Hostname $Hostname
}

if ($runRouting -and $NicName -and $ResourceGroup) {
    Write-Section "Route Analysis"
    .\Get-AzureEffectiveRoutes.ps1 -NicName $NicName -ResourceGroup $ResourceGroup
}

if ($runPeering -and $VNetName -and $ResourceGroup) {
    Write-Section "VNet Peering"
    .\Check-VNetPeering.ps1 -VNetName $VNetName -ResourceGroup $ResourceGroup
}

Write-Host ""
Write-Host "Diagnostics complete." -ForegroundColor Green