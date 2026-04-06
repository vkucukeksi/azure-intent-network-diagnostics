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

# ===== Rule 1: DNS resolves to public IP =====
if ($Results.Test -contains "DNS") {
    $dnsResult = $Results | Where-Object { $_.Test -eq "DNS" }

    if ($dnsResult.Status -eq "Public") {
        $guidance += "DNS resolves to a public IP. Check Private Endpoint DNS configuration."
    }
}

# ===== Rule 2: Connectivity failed =====
if ($Results.Test -contains "Connectivity") {
    $conn = $Results | Where-Object { $_.Test -eq "Connectivity" }

    if ($conn.Status -eq "Failed") {
        $guidance += "Connectivity test failed. Check NSGs, firewall rules, or routing."
    }
}

# ===== Rule 3: Routing issue =====
if ($Results.Test -contains "Routing") {
    $route = $Results | Where-Object { $_.Test -eq "Routing" }

    if ($route.Status -eq "IssueDetected") {
        $guidance += "Routing issue detected. Review UDRs and next hop configuration."
    }
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