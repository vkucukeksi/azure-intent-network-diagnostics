[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$Hostname
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

# ===== Check if IP is private =====
function Test-PrivateIP {
    param (
        [string]$IP
    )

    return (
        $IP -like "10.*" -or
        $IP -like "172.16.*" -or
        $IP -like "192.168.*"
    )
}

Write-Log "Resolving DNS for $Hostname"

try {
    $results = Resolve-DnsName $Hostname -ErrorAction Stop

    $output = foreach ($entry in $results) {
        if ($entry.IPAddress) {

            $isPrivate = Test-PrivateIP -IP $entry.IPAddress

            [PSCustomObject]@{
                Hostname   = $Hostname
                IPAddress  = $entry.IPAddress
                IPType     = if ($isPrivate) { "Private" } else { "Public" }
            }
        }
    }

    if (-not $output -or $output.Count -eq 0) {
        Write-Log "No IP addresses found" "WARN"

        return [PSCustomObject]@{
            Status = "Unknown"
        }
    }
    else {
        Write-Host ""
        Write-Host "DNS Results:" -ForegroundColor Yellow
        $output
    }

    # ===== Detect potential issue =====
    if ($output.IPType -contains "Public") {
        Write-Host ""
        Write-Host "WARNING: Public IP detected - check Private Endpoint / DNS configuration" -ForegroundColor Red

        return [PSCustomObject]@{
            Status = "Public"
        }
    }
    elseif ($output.IPType -contains "Private") {
        return [PSCustomObject]@{
            Status = "Private"
        }
    }
    else {
        return [PSCustomObject]@{
            Status = "Unknown"
        }
    }
}
catch {
    Write-Log "DNS resolution failed: $_" "ERROR"

    return [PSCustomObject]@{
        Status = "Error"
    }
}