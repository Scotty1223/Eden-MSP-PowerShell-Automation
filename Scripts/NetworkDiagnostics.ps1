# Eden Soundworkz Technologies
# Project 04 - MSP Network Diagnostics
# Technician: Prescott
# Purpose: Automate basic network troubleshooting

$Targets = @(
    "1.1.1.1",
    "microsoft.com",
    "google.com"
)

$Results = foreach ($Target in $Targets) {

    Write-Host "Testing $Target..." -ForegroundColor Cyan

    try {
        # Check DNS resolution
        $IPAddress = [System.Net.Dns]::GetHostAddresses($Target) |
            Select-Object -First 1 -ExpandProperty IPAddressToString

        # Test network connectivity
        $Ping = Test-Connection -TargetName $Target -Count 2 -ErrorAction Stop

        # Create structured result
        [PSCustomObject]@{
            Target       = $Target
            IPAddress    = $IPAddress
            Status       = "Online"
            AverageMs    = [math]::Round(
                ($Ping | Measure-Object -Property Latency -Average).Average,
                2
            )
            Date         = Get-Date
        }
    }
    catch {
        [PSCustomObject]@{
            Target       = $Target
            IPAddress    = "Unavailable"
            Status       = "Failed"
            AverageMs    = $null
            Date         = Get-Date
        }
    }
}

# Display results
$Results | Format-Table -AutoSize

# Export results to CSV
$Results | Export-Csv -Path "$HOME/EDEN-MSP-LAB/NetworkReport.csv"

Write-Host "Network report saved successfully!" -ForegroundColor Green
