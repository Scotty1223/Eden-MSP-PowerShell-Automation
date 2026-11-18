# Eden Soundworkz Technologies
# MSP Employee Onboarding Automation
# Lab 03 - Account Provisioning Simulation

$ProjectPath = Join-Path $HOME "EDEN-MSP-LAB"

$Employees = Import-Csv (
    Join-Path $ProjectPath "NewEmployees.csv"
)

$Accounts = foreach ($Employee in $Employees) {

    $FirstName = $Employee.FirstName.Trim()
    $LastName = $Employee.LastName.Trim()
    $Department = $Employee.Department.Trim()

    if (
        [string]::IsNullOrWhiteSpace($FirstName) -or
        [string]::IsNullOrWhiteSpace($LastName) -or
        [string]::IsNullOrWhiteSpace($Department)
    ) {
        Write-Warning "Employee record has missing required information."
        continue
    }

    $Username = (
        $FirstName.Substring(0,1) + $LastName
    ).ToLowerInvariant()

    $SecurityGroup = switch ($Department) {
        "Legal"   { "SG-Legal-Users" }
        "Finance" { "SG-Finance-Users" }
        "IT"      { "SG-IT-Support" }
        default   { $null }
    }

    [PSCustomObject]@{
        FullName      = "$FirstName $LastName"
        Username      = $Username
        Department    = $Department
        JobTitle      = $Employee.JobTitle
        SecurityGroup = $SecurityGroup
        Status        = if ($null -eq $SecurityGroup) {
            "Review Required - Unknown Department"
        } else {
            "Pending Validation"
        }
    }
}

# Detect duplicate usernames
$Duplicates = $Accounts |
    Group-Object Username |
    Where-Object Count -gt 1

foreach ($Duplicate in $Duplicates) {

    Write-Warning "Duplicate username detected: $($Duplicate.Name)"

    foreach ($Account in $Duplicate.Group) {
        $Account.Status = "Review Required - Duplicate Username"
    }
}

# Mark valid records as ready for approval
foreach ($Account in $Accounts) {

    if ($Account.Status -eq "Pending Validation") {
        $Account.Status = "Pending Approval"
    }
}

# Display onboarding results
$Accounts |
    Format-Table FullName, Username, SecurityGroup, Status -AutoSize

# Export onboarding report
$ReportPath = Join-Path $ProjectPath "EmployeeOnboardingReport.csv"

$Accounts | Export-Csv -Path $ReportPath

Write-Host "Onboarding report saved to $ReportPath" -ForegroundColor Green
