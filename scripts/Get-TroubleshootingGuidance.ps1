param (
    [Parameter(Mandatory=$true)]
    [array]$Results
)

function Write-Log {
    param ([string]$Message)
    Write-Host "[Guidance] $Message" -ForegroundColor Cyan
}

Write-Log "Analysing results..."

$guidance = @()
$combinedMatch = $false   # ✅ ADD THIS

# ===== Extract results once =====
$dnsResult  = $Results | Where-Object { $_.Test -eq "DNS" }
$connResult = $Results | Where-Object { $_.Test -eq "Connectivity" }

# ===== Rule 0b: DNS Error + Connectivity Failed =====
if ($dnsResult -and $connResult) {
    if ($dnsResult.Status -eq "Error" -and $connResult.Status -eq "Failed") {
        $guidance += "Connectivity is failing and DNS resolution failed. This may indicate DNS misconfiguration, missing private DNS zone, or network restrictions blocking DNS queries."
        $combinedMatch = $true   # ✅ ADD THIS
    }
}

# ===== Rule 0: DNS Public + Connectivity Failed =====
if ($dnsResult -and $connResult) {
    if ($dnsResult.Status -eq "Public" -and $connResult.Status -eq "Failed") {
        $guidance += "Connectivity is failing and DNS resolves to a public IP. This strongly indicates a Private Endpoint or DNS misconfiguration."
        $combinedMatch = $true   # ✅ ADD THIS
    }
}

# ===== Rule 1: DNS resolves to public IP =====
if (-not $combinedMatch -and $dnsResult) {
    if ($dnsResult.Status -eq "Public") {
        $guidance += "DNS resolves to a public IP. Check Private Endpoint DNS configuration."
    }
}

# ===== Rule 2: DNS resolution error =====
if (-not $combinedMatch -and $dnsResult) {
    if ($dnsResult.Status -eq "Error") {
        $guidance += "DNS resolution failed. Check DNS configuration, private DNS zones, or network connectivity."
    }
}

# ===== Rule 3: Connectivity failed =====
if (-not $combinedMatch -and $connResult) {
    if ($connResult.Status -eq "Failed") {
        $guidance += "Connectivity test failed. Check NSGs, firewall rules, or routing."
    }
}

# ===== Rule 4: Routing issue =====
$route = $Results | Where-Object { $_.Test -eq "Routing" }
if ($route -and $route.Status -eq "IssueDetected") {
    $guidance += "Routing issue detected. Review UDRs and next hop configuration."
}

# ===== Output =====
Write-Host ""
Write-Host "Suggested Guidance:" -ForegroundColor Yellow

if ($guidance.Count -eq 0) {
    Write-Host "No obvious issues detected." -ForegroundColor Green
}
else {
    $guidance | ForEach-Object { Write-Host "- $_" }
}