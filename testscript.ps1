### Windows Server Test Script
# Dit script controleert de basisstatus van meerdere Windows Servers.
# Controleert op CPU-gebruik, geheugen, schijfruimte, netwerkconnectiviteit en services.

# Parameters
$ServerNames = @("Windowsadserver", "devopsvm", "exchangeVM", "squidvm")  # Voeg hier de namen van de servers toe
$CriticalServices = @("wuauserv", "WinRM", "LanmanServer", "LanmanWorkstation")  # Essentiële services
$AdditionalChecks = @("Windowsadserver", "devopsvm")  # Servers voor DFS, DHCP, DNS checks

# Functie om CPU-gebruik te controleren
Function Check-CPUUsage {
    param([string]$ServerName)
    Write-Host "\n--- Controleren van CPU-gebruik op $ServerName ---"
    $cpu = Get-Counter -ComputerName $ServerName -Counter "\\Processor(_Total)\\% Processor Time" | Select-Object -ExpandProperty CounterSamples
    $cpuUsage = [math]::round($cpu.CookedValue, 2)
    Write-Host "CPU-gebruik: $cpuUsage%"
    if ($cpuUsage -gt 85) {
        Write-Warning "Hoge CPU-belasting gedetecteerd op $ServerName!"
    } else {
        Write-Host "CPU-belasting is normaal op $ServerName."
    }
}

# Functie om geheugenstatus te controleren
Function Check-MemoryUsage {
    param([string]$ServerName)
    Write-Host "\n--- Controleren van geheugengebruik op $ServerName ---"
    $memory = Get-CimInstance -ComputerName $ServerName -ClassName Win32_OperatingSystem
    $totalMemory = [math]::round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::round($memory.FreePhysicalMemory / 1MB, 2)
    $usedMemory = $totalMemory - $freeMemory
    $usedPercentage = [math]::round(($usedMemory / $totalMemory) * 100, 2)
    Write-Host "Totale geheugen: $totalMemory MB"
    Write-Host "Gebruikt geheugen: $usedMemory MB ($usedPercentage%)"
    if ($usedPercentage -gt 85) {
        Write-Warning "Hoge geheugengebruik gedetecteerd op $ServerName!"
    } else {
        Write-Host "Geheugenverbruik is binnen het normale bereik op $ServerName."
    }
}

# Functie om schijfruimte te controleren
Function Check-DiskSpace {
    param([string]$ServerName)
    Write-Host "\n--- Controleren van schijfruimte op $ServerName ---"
    $disks = Get-WmiObject -ComputerName $ServerName -Class Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($disk in $disks) {
        $freeSpace = [math]::round($disk.FreeSpace / 1GB, 2)
        $totalSpace = [math]::round($disk.Size / 1GB, 2)
        $usedPercentage = [math]::round((($totalSpace - $freeSpace) / $totalSpace) * 100, 2)
        Write-Host "Schijf $($disk.DeviceID): Vrije ruimte: $freeSpace GB / Totale ruimte: $totalSpace GB ($usedPercentage% in gebruik)"
        if ($usedPercentage -gt 85) {
            Write-Warning "Lage schijfruimte gedetecteerd op $($disk.DeviceID) op $ServerName!"
        } else {
            Write-Host "Schijfruimte is voldoende op $($disk.DeviceID) op $ServerName."
        }
    }
}

# Functie om netwerkstatus te controleren
Function Check-NetworkConnectivity {
    param([string]$ServerName)
    Write-Host "\n--- Controleren van netwerkconnectiviteit vanaf $ServerName ---"
    $testURL = "www.google.com"
    try {
        Test-Connection -ComputerName $testURL -Count 2 -ErrorAction Stop
        Write-Host "Netwerkconnectiviteit vanaf $ServerName naar $testURL is OK."
    } catch {
        Write-Warning "Kan geen verbinding maken met $testURL vanaf $ServerName. Controleer de netwerkverbinding."
    }
}

# Functie om essentiële services te controleren
Function Check-CriticalServices {
    param([string]$ServerName)
    Write-Host "\n--- Controleren van essentiële services op $ServerName ---"
    foreach ($service in $CriticalServices) {
        $serviceStatus = Get-Service -ComputerName $ServerName -Name $service -ErrorAction SilentlyContinue
        if ($serviceStatus.Status -eq 'Running') {
            Write-Host "Service $service is actief op $ServerName."
        } else {
            Write-Warning "Service $service is NIET actief op $ServerName!"
        }
    }
}

# Functie om aanvullende checks (DFS, DHCP, DNS) te controleren
Function Check-AdditionalServices {
    param([string]$ServerName)
    Write-Host "\n--- Controleren van aanvullende services (DFS, DHCP, DNS) op $ServerName ---"
    $additionalServices = @("DFS", "DHCPServer", "DNS")
    foreach ($service in $additionalServices) {
        $serviceStatus = Get-Service -ComputerName $ServerName -Name $service -ErrorAction SilentlyContinue
        if ($serviceStatus.Status -eq 'Running') {
            Write-Host "Service $service is actief op $ServerName."
        } else {
            Write-Warning "Service $service is NIET actief op $ServerName!"
        }
    }
}

# Functie om samenvatting te geven
Function Display-Summary {
    foreach ($ServerName in $ServerNames) {
        Write-Host "\n--- Samenvatting van de serverstatus voor $ServerName ---"
        Check-CPUUsage -ServerName $ServerName
        Check-MemoryUsage -ServerName $ServerName
        Check-DiskSpace -ServerName $ServerName
        Check-NetworkConnectivity -ServerName $ServerName
        Check-CriticalServices -ServerName $ServerName
        if ($ServerName -in $AdditionalChecks) {
            Check-AdditionalServices -ServerName $ServerName
        }
        Write-Host "\n--- Servercontrole voltooid voor $ServerName ---"
    }
}

# Uitvoeren van de controles
Display-Summary
