### Windows Server Test Script
# This script checks the status of various components on a list of Windows workstations.

# Parameters
$WorkstationNames = @("vm-w11pc-001", "testvm", "vm-w11pc-002", "vm-w11pc-003", "vm-w11pc-004", "vm-w11pc-005")

Function Get-AntivirusStatus {
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
Function Get-7ZipInstallation {
    param([string]$WorkstationName)
    Write-Host "`n--- Controleren van 7-Zip-installatie op $WorkstationName ---"
    try {
        # Standaard installatielocaties voor 7-Zip
        $sevenZipPaths = @(
            "C:\Program Files\7-Zip\7z.exe",
            "C:\Program Files (x86)\7-Zip\7z.exe"
        )

        # Controleer of een van de locaties bestaat
        $sevenZipInstalled = $false
        foreach ($path in $sevenZipPaths) {
            $exists = Test-Path -Path "\\$WorkstationName\$($path -replace ':', '$')" -ErrorAction SilentlyContinue
            if ($exists) {
                $sevenZipInstalled = $true
                Write-Host "7-Zip is geïnstalleerd op $WorkstationName (gevonden op $path)."
                break
            }
        }

        # Als geen installatiemap is gevonden, geef een waarschuwing
        if (-not $sevenZipInstalled) {
            Write-Warning "7-Zip is niet geïnstalleerd op $WorkstationName!"
        } else {
            # Controleer of 7-Zip werkt via de opdrachtregel
            $testCommand = Invoke-Command -ComputerName $WorkstationName -ScriptBlock {
                & "C:\Program Files\7-Zip\7z.exe" -version -ErrorAction SilentlyContinue
            }
            if ($testCommand) {
                Write-Host "7-Zip werkt correct op $WorkstationName."
            } else {
                Write-Warning "7-Zip is geïnstalleerd, maar kan niet worden uitgevoerd op $WorkstationName!"
            }
        }
    } catch {
        Write-Warning "Kan 7-Zip-installatie niet controleren op $WorkstationName. Controleer netwerkconnectiviteit en rechten."
    }
}
Function Get-WorkstationUptime {
    param([string]$WorkstationName)
    Write-Host "`n--- Controleren van de uptime van $WorkstationName ---"
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ServerName
        $lastBootTime = $os.LastBootUpTime
        $uptime = (Get-Date) - $lastBootTime
        Write-Host "Server $ServerName is actief sinds: $lastBootTime (Uptime: $([math]::Round($uptime.TotalHours, 2)) uur)"
    } catch {
        Write-Warning "Kan uptime niet controleren op $ServerName."
    }
}
Function Show-WorkstationSummary {
    foreach ($WorkstationName in $WorkstationNames) {
        Write-Host "`n--- Samenvatting van de workstationstatus voor $WorkstationName ---"
        #Get-AntivirusStatus -WorkstationName $WorkstationName
        #Get-7ZipInstallation -WorkstationName $WorkstationName
        Get-WorkstationUptime -WorkstationName $WorkstationName
        Write-Host "`n--- Workstationcontrole voltooid voor $WorkstationName ---"
    }
}

Show-WorkstationSummary
