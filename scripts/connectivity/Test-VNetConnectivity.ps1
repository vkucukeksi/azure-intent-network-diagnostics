[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetIP,

    [int]$Port = 443,
    [int]$TimeoutSeconds = 5
)

# ===== Logging Function =====
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$timestamp [$Level] $Message"
}

# ===== Connectivity Test Function =====
function Test-ConnectionAdvanced {
    param (
        [string]$Target,
        [int]$Port
    )

    try {
        Write-Log "Testing connectivity to $Target on port $Port"

        $result = Test-NetConnection -ComputerName $Target -Port $Port -WarningAction SilentlyContinue

        return [PSCustomObject]@{
            Target        = $Target
            Port          = $Port
            Status        = if ($result.TcpTestSucceeded) { "Success" } else { "Failed" }
            RemoteAddress = $result.RemoteAddress
            LatencyMs     = if ($result.PingReplyDetails) { $result.PingReplyDetails.RoundtripTime } else { $null }
        }
    }
    catch {
        Write-Log "Error: $_" "ERROR"

        return [PSCustomObject]@{
            Target        = $Target
            Port          = $Port
            Status        = "Error"
            RemoteAddress = $null
            LatencyMs     = $null
        }
    }
}

# ===== Execution =====
Write-Log "Starting connectivity test"

$result = Test-ConnectionAdvanced -Target $TargetIP -Port $Port

Write-Log "Test completed"

# ===== Output =====
Write-Host ""
Write-Host "Result:" -ForegroundColor Yellow

$result

# ===== Exit Code =====
if ($result.Status -eq "Success") {
    exit 0
}
else {
    exit 1
}

return $result