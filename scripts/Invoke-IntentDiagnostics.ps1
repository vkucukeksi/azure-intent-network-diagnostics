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

$results = @() # This will hold results from each test for guidance generations
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

    $scriptPath = Join-Path $PSScriptRoot "connectivity\Test-VNetConnectivity.ps1"
    $connResult = & $scriptPath -TargetIP $TargetIP

    $status = "Failed"

    if ($connResult.Status -eq "Success") {
        $status = "Success"
    }

    $results += [PSCustomObject]@{
        Test   = "Connectivity"
        Status = $status
    }
}

if ($runDNS -and $Hostname) {
    Write-Section "DNS Test"

    $dnsScript = Join-Path $PSScriptRoot "dns\Test-AzureDNS.ps1"
    $dnsResult = & $dnsScript -Hostname $Hostname

    $status = "Unknown"

    if ($dnsResult -and $dnsResult.Status) {
        $status = $dnsResult.Status
    }

    Write-Host "DNS result: $status" -ForegroundColor DarkGray

    $results += [PSCustomObject]@{
        Test   = "DNS"
        Status = $status
    }
}

if ($runRouting -and $NicName -and $ResourceGroup) {
    Write-Section "Route Analysis"
    $routingScript = Join-Path $PSScriptRoot "routing\Get-AzureEffectiveRoutes.ps1"
    & $routingScript -NicName $NicName -ResourceGroup $ResourceGroup
}

if ($runPeering -and $VNetName -and $ResourceGroup) {
    Write-Section "VNet Peering"
    .\Check-VNetPeering.ps1 -VNetName $VNetName -ResourceGroup $ResourceGroup
}

Write-Host ""
Write-Host "Diagnostics complete." -ForegroundColor Green

# Run guidance engine
$guidanceScript = Join-Path $PSScriptRoot "Get-TroubleshootingGuidance.ps1"
& $guidanceScript -Results $results