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