# Correct definition of $ServerNames array
$ServerNames = @("vm-devops", "vm-exchange", "vm-adserver")  # Voeg hier de namen van de servers toe
$CriticalServices = @(
    'wuauserv', 'winmgmt', 'rpcss', 'schedule', 'samss', 'LanmanServer',
    'LanmanWorkstation', 'Dnscache', 'Dhcp', 'NlaSvc', 'Netlogon',
    'MpsSvc', 'Spooler',  'w32time', 'NTDS'
)
$AdditionalChecks = @("vm-adserver", "vm-devops")  # Servers voor DFS, DHCP, DNS checks


Function Get-CPUUsage {
    param([string]$ServerName)
    Write-Host "`n--- Controleren van CPU-gebruik op $ServerName ---"
    try {
        # Get CPU usage using Get-Counter
        $cpu = Get-Counter -ComputerName $ServerName -Counter "\Processor(_Total)\% Processor Time" | Select-Object -ExpandProperty CounterSamples
        $cpuUsage = [math]::round($cpu.CookedValue, 2)
        Write-Host "CPU-gebruik: $cpuUsage%"
        if ($cpuUsage -gt 85) {
            Write-Warning "Hoge CPU-belasting gedetecteerd op $ServerName!"
        } else {
            Write-Host "CPU-belasting is normaal op $ServerName."
        }
    } catch {
        Write-Warning "Kon geen CPU-gegevens ophalen van $ServerName. Controleer of de server bereikbaar is."
    }
}
Function Get-MemoryUsage {
    param([string]$ServerName)
    Write-Host "\n--- Controleren van geheugengebruik op $ServerName ---"
    try {
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
    } catch {
        Write-Warning "Kon geen geheugengegevens ophalen van $ServerName. Controleer of de server bereikbaar is."
    }
}
Function Get-DiskSpace {
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
Function Get-NetworkConnectivity {
    param([string]$ServerName)
    Write-Host "\n--- Controleren van netwerkconnectiviteit vanaf $ServerName ---"
    $testURL = "uvh.nl"
    try {
        Test-Connection -ComputerName $testURL -Count 2 -ErrorAction Stop
        Write-Host "Netwerkconnectiviteit vanaf $ServerName naar $testURL is OK."
    } catch {
        Write-Warning "Kan geen verbinding maken met $testURL vanaf $ServerName. Controleer de netwerkverbinding."
    }
}
Function Get-CriticalServices {
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
Function Get-EventLogs {
    param([string]$ServerName)
    Write-Host "`n--- Controleren van Event Logs op $ServerName ---"
    try {
        # Haal de systeemlogboeken op en filter op kritieke fouten
        $logs = Get-WinEvent -ComputerName $ServerName -FilterHashtable @{LogName='System'; Level=1; StartTime=(Get-Date).AddDays(-1)} -ErrorAction Stop

        # Als er logs zijn, geef ze weer, anders toon een bericht dat er geen kritieke fouten zijn
        if ($logs.Count -gt 0) {
            Write-Warning "Er zijn kritieke fouten gevonden in de Event Logs van $ServerName!"
            $logs | Select-Object -First 5 | ForEach-Object {
                Write-Host "Tijd: $($_.TimeCreated) - Bron: $($_.ProviderName) - Bericht: $($_.Message)"
            }
        } else {
            Write-Host "Geen kritieke fouten gevonden in de Event Logs van $ServerName."
        }
    } catch {
        Write-Host "Geen kritieke fouten gevonden in de Event Logs van $ServerName."
    }
}
Function Get-PendingUpdates {
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
Function Get-AdditionalServices {
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
Function Get-UserSessions {
    param([string]$ServerName)
    Write-Host "`n--- Controleren van actieve gebruikerssessies op $ServerName ---"
    try {
        # Haal actieve logon-sessies op
        $sessions = Get-CimInstance -ClassName Win32_LogonSession -ComputerName $ServerName | Where-Object {$_.LogonType -eq 2}
        if ($sessions) {
            Write-Host "Actieve gebruikerssessies gevonden op $ServerName :"
            foreach ($session in $sessions) { 
                # Koppel de sessie aan de gebruiker
                $loggedOnUsers = Get-CimInstance -ClassName Win32_LoggedOnUser -ComputerName $ServerName | Where-Object { $_.Dependent -match $session.LogonId }
                foreach ($loggedOnUser in $loggedOnUsers) {
                    $userPath = ($loggedOnUser.Antecedent -split '"')[1]
                    $user = Get-CimInstance -Query "SELECT * FROM Win32_Account WHERE __RELPATH LIKE '%$userPath%' AND SIDType=1" -ComputerName $ServerName
                    if ($user) {
                        Write-Host "Gebruiker: $($user.Name) - Domein: $($user.Domain) - Logon Time: $($session.StartTime)"
                    }
                }
            }
        } else {
            Write-Host "Geen actieve gebruikerssessies gevonden op $ServerName."
        }
    } catch {
        Write-Warning "Kan gebruikerssessies niet ophalen op $ServerName. Fout: $_"
    }
}
Function Get-PortStatus {
    param(
        [string]$ServerName,
        [int[]]$Ports = @(22, 80, 443, 3389, 8080, 8443, 3306, 5432, 6379, 9090)

    )
    Write-Host "`n--- Controleren van poortstatus op $ServerName ---"
    foreach ($port in $Ports) {
        try {
            $connection = Test-NetConnection -ComputerName $ServerName -Port $port -WarningAction SilentlyContinue
            if ($connection.TcpTestSucceeded) {
                Write-Host "Poort $port is open op $ServerName."
            } else {
                Write-Host "Poort $port is niet bereikbaar op $ServerName!"
            }
        } catch {
            Write-Warning "Kan poort $port niet controleren op $ServerName."
        }
    }
}
Function Get-Uptime {
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
Function Show-Summary {
    foreach ($ServerName in $ServerNames) {
        Write-Host "`n--- Samenvatting van de serverstatus voor $ServerName ---"
        Get-CPUUsage -ServerName $ServerName
        Get-MemoryUsage -ServerName $ServerName
        Get-DiskSpace -ServerName $ServerName
        Get-NetworkConnectivity -ServerName $ServerName
        Get-CriticalServices -ServerName $ServerName
        Get-EventLogs -ServerName $ServerName
        Get-PendingUpdates -ServerName $ServerName
        Get-UserSessions -ServerName $ServerName
        Get-PortStatus -ServerName $ServerName
        Get-Uptime -ServerName $ServerName
        if ($ServerName -in $AdditionalChecks) {
            Get-AdditionalServices -ServerName $ServerName
        }

        Write-Host "`n--- Controles voltooid voor $ServerName ---"
    }
}

# Execute the summary
Show-Summary
