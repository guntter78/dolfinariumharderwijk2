### Windows Server Test Script
# Dit script controleert de basisstatus van meerdere Windows Servers.
# Controleert op CPU-gebruik, geheugen, schijfruimte, netwerkconnectiviteit en services.

# Parameters
$ServerNames = @("vm-devops, vm-exchange, guacserver, vm-adserver")  # Voeg hier de namen van de servers toe
$CriticalServices = @("wuauserv", "WinRM", "LanmanServer", "LanmanWorkstation")  # Essentiële services
$AdditionalChecks = @("Windowsadserver", "devopsvm")  # Servers voor DFS, DHCP, DNS checks

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
Function Check-EventLogs {
    param([string]$ServerName)
    Write-Host "`n--- Controleren van Event Logs op $ServerName ---"
    try {
        $logs = Get-WinEvent -ComputerName $ServerName -FilterHashtable @{LogName='System'; Level=1; StartTime=(Get-Date).AddDays(-1)} -ErrorAction Stop
        if ($logs) {
            Write-Warning "Er zijn kritieke fouten gevonden in de Event Logs van $ServerName!"
            $logs | Select-Object -First 5 | ForEach-Object {
                Write-Host "Tijd: $($_.TimeCreated) - Bron: $($_.ProviderName) - Bericht: $($_.Message)"
            }
        } else {
            Write-Host "Geen kritieke fouten gevonden in de Event Logs van $ServerName."
        }
    } catch {
        Write-Warning "Kan de Event Logs niet ophalen van $ServerName. Controleer of de server bereikbaar is."
    }
}
Function Check-PendingUpdates {
    param([string]$ServerName)
    Write-Host "`n--- Controleren van openstaande Windows-updates op $ServerName ---"
    try {
        $updates = Invoke-Command -ComputerName $ServerName -ScriptBlock {
            Get-WindowsUpdate -AcceptAll -IgnoreReboot -ErrorAction SilentlyContinue
        }
        if ($updates) {
            Write-Warning "Er zijn openstaande updates op $ServerName!"
            $updates | ForEach-Object { Write-Host "Update: $($_.Title)" }
        } else {
            Write-Host "Geen openstaande updates gevonden op $ServerName."
        }
    } catch {
        Write-Warning "Kan updates niet controleren op $ServerName. Controleer of de server bereikbaar is."
    }
}
Function Check-UserSessions {
    param([string]$ServerName)
    Write-Host "`n--- Controleren van actieve gebruikerssessies op $ServerName ---"
    try {
        $sessions = Get-CimInstance -ClassName Win32_LogonSession -ComputerName $ServerName | Where-Object {$_.LogonType -eq 2}
        if ($sessions) {
            Write-Host "Actieve gebruikerssessies gevonden op $ServerName :"
            $sessions | ForEach-Object {
                Write-Host "Logon ID: $($_.LogonId) - Logon Time: $($_.StartTime)"
            }
        } else {
            Write-Host "Geen actieve gebruikerssessies gevonden op $ServerName."
        }
    } catch {
        Write-Warning "Kan gebruikerssessies niet ophalen op $ServerName."
    }
}
Function Check-PortStatus {
    param(
        [string]$ServerName,
        [int[]]$Ports = @(80, 443, 3389)
    )
    Write-Host "`n--- Controleren van poortstatus op $ServerName ---"
    foreach ($port in $Ports) {
        try {
            $connection = Test-NetConnection -ComputerName $ServerName -Port $port -WarningAction SilentlyContinue
            if ($connection.TcpTestSucceeded) {
                Write-Host "Poort $port is open op $ServerName."
            } else {
                Write-Warning "Poort $port is niet bereikbaar op $ServerName!"
            }
        } catch {
            Write-Warning "Kan poort $port niet controleren op $ServerName."
        }
    }
}
Function Check-Uptime {
    param([string]$ServerName)
    Write-Host "`n--- Controleren van uptime op $ServerName ---"
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ServerName
        $lastBootTime = $os.LastBootUpTime
        $uptime = (Get-Date) - $lastBootTime
        Write-Host "Server $ServerName is actief sinds: $lastBootTime (Uptime: $([math]::Round($uptime.TotalHours, 2)) uur)"
    } catch {
        Write-Warning "Kan uptime niet controleren op $ServerName."
    }
}
Function Display-Summary {
    foreach ($ServerName in $ServerNames) {
        Write-Host "\n--- Samenvatting van de serverstatus voor $ServerName ---"
        Check-CPUUsage -ServerName $ServerName
        Check-MemoryUsage -ServerName $ServerName
        Check-DiskSpace -ServerName $ServerName
        Check-NetworkConnectivity -ServerName $ServerName
        Check-CriticalServices -ServerName $ServerName
        Check-EventLogs -ServerName $ServerName
        Check-PendingUpdates -ServerName $ServerName
        Check-UserSessions -ServerName $ServerName
        Check-PortStatus -ServerName $ServerName -Ports @(80, 443, 3389)
        Check-Uptime -ServerName $ServerName
        if ($ServerName -in $AdditionalChecks) {
            Check-AdditionalServices -ServerName $ServerName
        }
        Write-Host "\n--- Servercontrole voltooid voor $ServerName ---"
    }
}

# Uitvoeren van de controles
Display-Summary
