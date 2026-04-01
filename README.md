# Azure Intent-Based Network Diagnostics

This project demonstrates a simple intent-driven approach to Azure network troubleshooting.

Instead of manually selecting diagnostic scripts, users provide a description of the issue,
and the tool determines which checks to run.

## How it works

The script parses the intent and maps it to relevant diagnostics:

- Connectivity testing
- DNS resolution
- Route analysis
- VNet peering validation

## Usage

```powershell
.\Invoke-IntentDiagnostics.ps1 `
    -Intent "VM cannot reach storage account private endpoint" `
    -TargetIP 10.1.2.4 `
    -Hostname storageaccount.blob.core.windows.net `
    -NicName myNic `
    -VNetName myVnet `
    -ResourceGroup myRG

## Example

Input:
"VM cannot reach storage account private endpoint"

Output:
- Runs connectivity test
- Runs DNS check
- Runs route analysis

## Purpose

This project explores how troubleshooting workflows can be simplified by
mapping user intent to diagnostics, reducing manual steps and improving consistency.

## Related Project

This project builds on the core troubleshooting scripts available here:

👉 https://github.com/vkucukeksi/azure-network-troubleshooting-toolkit

The toolkit provides the underlying diagnostics, while this project focuses on
mapping user intent to those diagnostics.