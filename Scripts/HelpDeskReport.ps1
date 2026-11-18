# ==================================================
# Eden Soundworkz Technologies
# Project 04 - MSP PowerShell Automation Lab
# Lab 04 - Help Desk Ticket Reporting
# ==================================================

$ProjectPath = Join-Path $HOME "EDEN-MSP-LAB"
$TicketPath = Join-Path $ProjectPath "HelpDeskTickets.csv"

# Import ticket database
$Tickets = @(Import-Csv -Path $TicketPath -ErrorAction Stop)

# Calculate ticket statistics
$TotalTickets = $Tickets.Count

$OpenTickets = @(
    $Tickets | Where-Object { $_.Status -eq "Open" }
).Count

$InProgressTickets = @(
    $Tickets | Where-Object { $_.Status -eq "In Progress" }
).Count

$ResolvedTickets = @(
    $Tickets | Where-Object { $_.Status -eq "Resolved" }
).Count

$HighPriorityTickets = @(
    $Tickets | Where-Object { $_.Priority -eq "High" }
).Count

$UnresolvedTickets = @(
    $Tickets | Where-Object { $_.Status -ne "Resolved" }
).Count

# Calculate resolution percentage
$ResolutionRate = if ($TotalTickets -gt 0) {
    [math]::Round(($ResolvedTickets / $TotalTickets) * 100, 2)
} else {
    0
}

# Create management summary
$Summary = [PSCustomObject]@{
    ReportDate        = Get-Date
    TotalTickets      = $TotalTickets
    OpenTickets       = $OpenTickets
    InProgressTickets = $InProgressTickets
    ResolvedTickets   = $ResolvedTickets
    UnresolvedTickets = $UnresolvedTickets
    HighPriority      = $HighPriorityTickets
    ResolutionRate    = $ResolutionRate
}

# Analyze technician workloads
$Workload = $Tickets |
    Group-Object AssignedTo |
    ForEach-Object {

        $AssignedTickets = @($_.Group)

        [PSCustomObject]@{
            Technician = $_.Name
            TotalAssigned = $AssignedTickets.Count
            Unresolved = @(
                $AssignedTickets |
                Where-Object { $_.Status -ne "Resolved" }
            ).Count
        }
    }

# Identify unresolved high-priority incidents
$CriticalQueue = $Tickets |
    Where-Object {
        $_.Priority -eq "High" -and
        $_.Status -ne "Resolved"
    }

# Display management summary
Write-Host "`nHELP DESK MANAGEMENT SUMMARY" -ForegroundColor Cyan
$Summary | Format-List

# Display technician workload
Write-Host "`nTECHNICIAN WORKLOAD" -ForegroundColor Yellow
$Workload | Format-Table -AutoSize

# Display high-priority queue
Write-Host "`nHIGH-PRIORITY UNRESOLVED TICKETS" -ForegroundColor Red
$CriticalQueue |
    Format-Table TicketID, Employee, Issue, Status, AssignedTo -AutoSize

# Export reports
$Summary | Export-Csv (
    Join-Path $ProjectPath "HelpDeskSummary.csv"
)

$Workload | Export-Csv (
    Join-Path $ProjectPath "TechnicianWorkload.csv"
)

$CriticalQueue | Export-Csv (
    Join-Path $ProjectPath "HighPriorityTickets.csv"
)

Write-Host "`nReports exported successfully!" -ForegroundColor Green
