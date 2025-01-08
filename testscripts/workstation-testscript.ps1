### Windows Server Test Script
# This script checks the status of various components on a list of Windows workstations.

# Parameters
$WorkstationNames = @("vm-w11pc-001, testvm, vm-w11pc-002, vm-w11pc-003, vm-w11pc-004, vm-w11pc-005, vm-w11pc-006")


Function Check-AntivirusStatus {
    param([string]$WorkstationName)
    Write-Host "`n--- Controleren van Antivirusstatus op $WorkstationName ---"
    try {
        $antivirus = Get-CimInstance -Namespace "root\SecurityCenter2" -ClassName "AntiVirusProduct" -ComputerName $WorkstationName -ErrorAction Stop
        foreach ($av in $antivirus) {
            Write-Host "Antivirus op $WorkstationName : $($av.displayName)"
            if ($av.productState -match '^[5-7].*') {  # Controleert of het actief en up-to-date is
                Write-Host "Status: Actief en up-to-date."
            } else {
                Write-Warning "Status: Niet actief of niet up-to-date!"
            }
        }
    } catch {
        Write-Warning "Kan geen antivirusstatus ophalen van $WorkstationName. Controleer of het systeem bereikbaar is."
    }
}

Function Display-WorkstationSummary {
    foreach ($WorkstationName in $WorkstationNames) {
        Write-Host "`n--- Samenvatting van de workstationstatus voor $WorkstationName ---"
        Check-AntivirusStatus -WorkstationName $WorkstationName
        Write-Host "`n--- Workstationcontrole voltooid voor $WorkstationName ---"
    }
}

Display-WorkstationSummary
