# ==================================================
# Eden Soundworkz Technologies
# MSP PowerShell Automation Lab
# Lab 06 - Microsoft Entra ID Identity Audit
# Read-Only Microsoft Graph Automation
# ==================================================

$ErrorActionPreference = "Stop"

$ProjectPath = Join-Path $HOME "EDEN-MSP-LAB"
$ReportPath = Join-Path $ProjectPath "EntraIdentityAudit.csv"

# Verify Microsoft Graph connection
$Context = Get-MgContext

if ($null -eq $Context) {
    Write-Host "Microsoft Graph is not connected." -ForegroundColor Red
    Write-Host "Run Connect-MgGraph before executing this script."
    return
}

Write-Host "`nMicrosoft Graph connection verified." -ForegroundColor Green

try {

    # Retrieve signed-in user's profile
    $Profile = Invoke-MgGraphRequest `
        -Method GET `
        -Uri "/v1.0/me" `
        -ErrorAction Stop

    # Generate identity audit record
    $IdentityAudit = [PSCustomObject]@{
        DisplayName        = $Profile.displayName
        JobTitle           = $Profile.jobTitle
        Department         = $Profile.department
        UserType           = $Profile.userType
        AuthenticationType = $Context.AuthType
        ContextScope       = $Context.ContextScope
        AuditDate          = Get-Date
        Status             = "Profile Retrieved"
    }

    # Display audit report
    Write-Host "`nMICROSOFT ENTRA ID AUDIT REPORT" -ForegroundColor Cyan

    $IdentityAudit | Format-List

    # Export report
    $IdentityAudit | Export-Csv -Path $ReportPath

    Write-Host "`nIdentity audit report exported successfully!" -ForegroundColor Green
    Write-Host "Report location: $ReportPath"

}
catch {

    Write-Host "`nMicrosoft Graph request failed." -ForegroundColor Red
    Write-Host $_.Exception.Message

}
