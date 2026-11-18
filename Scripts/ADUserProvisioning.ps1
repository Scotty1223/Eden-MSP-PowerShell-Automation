# ==================================================
# Eden Soundworkz Technologies
# MSP PowerShell Automation Lab
# Lab 05 - Active Directory User Provisioning
# Simulation Only - No AD Accounts Created
# ==================================================

$ProjectPath = Join-Path $HOME "EDEN-MSP-LAB"
$EmployeePath = Join-Path $ProjectPath "NewEmployees.csv"

$Domain = "edenlaw.local"
$DomainDN = "DC=edenlaw,DC=local"

# Import employee records
$Employees = @(Import-Csv -Path $EmployeePath -ErrorAction Stop)

# Generate proposed Active Directory accounts
$ADUsers = foreach ($Employee in $Employees) {

    $FirstName = ([string]$Employee.FirstName).Trim()
    $LastName = ([string]$Employee.LastName).Trim()
    $Department = ([string]$Employee.Department).Trim()

    # Validate required employee information
    if (
        [string]::IsNullOrWhiteSpace($FirstName) -or
        [string]::IsNullOrWhiteSpace($LastName) -or
        [string]::IsNullOrWhiteSpace($Department)
    ) {
        Write-Warning "Employee record contains missing required information."
        continue
    }

    # Generate username
    $Username = (
        $FirstName.Substring(0,1) + $LastName
    ).ToLowerInvariant()

    # Map department to OU
    $OU = switch ($Department) {
        "Legal"          { "Legal" }
        "Finance"        { "Finance" }
        "IT"             { "IT" }
        "Administration" { "Administration" }
        default          { $null }
    }

    # Map department to security group
    $SecurityGroup = switch ($Department) {
        "Legal"          { "SG-Legal-Users" }
        "Finance"        { "SG-Finance-Users" }
        "IT"             { "SG-IT-Support" }
        "Administration" { "SG-Administration-Users" }
        default          { $null }
    }

    $OrganizationalUnit = if ($null -ne $OU) {
        "OU=$OU,OU=Employees,$DomainDN"
    } else {
        $null
    }

    # Create proposed account record
    [PSCustomObject]@{
        FullName           = "$FirstName $LastName"
        SamAccountName     = $Username
        UserPrincipalName  = "$Username@$Domain"
        Department         = $Department
        OrganizationalUnit = $OrganizationalUnit
        SecurityGroup      = $SecurityGroup
        Status             = if ($null -eq $OU) {
            "Review Required - Unknown Department"
        } else {
            "Pending Validation"
        }
    }
}

# Detect duplicate usernames
$Duplicates = $ADUsers |
    Group-Object SamAccountName |
    Where-Object Count -gt 1

foreach ($Duplicate in $Duplicates) {

    Write-Warning "Duplicate AD username detected: $($Duplicate.Name)"

    foreach ($User in $Duplicate.Group) {
        $User.Status = "Review Required - Duplicate Username"
    }
}

# Move valid records to approval queue
foreach ($User in $ADUsers) {

    if ($User.Status -eq "Pending Validation") {
        $User.Status = "Pending Approval"
    }
}

# Generate validation summary
$ValidationSummary = [PSCustomObject]@{
    ReportDate      = Get-Date
    TotalAccounts   = @($ADUsers).Count
    PendingApproval = @(
        $ADUsers | Where-Object { $_.Status -eq "Pending Approval" }
    ).Count
    ReviewRequired  = @(
        $ADUsers | Where-Object { $_.Status -like "Review Required*" }
    ).Count
}

# Display results
Write-Host "`nACTIVE DIRECTORY PROVISIONING REPORT" -ForegroundColor Cyan

$ADUsers |
    Format-Table FullName, SamAccountName, Department, Status -AutoSize

Write-Host "`nACCOUNT VALIDATION SUMMARY" -ForegroundColor Yellow

$ValidationSummary | Format-List

# Export reports
$ADUsers |
    Export-Csv (Join-Path $ProjectPath "ADUserProvisioning.csv")

$ValidationSummary |
    Export-Csv (Join-Path $ProjectPath "ADValidationSummary.csv")

Write-Host "`nAD provisioning reports exported successfully!" -ForegroundColor Green
