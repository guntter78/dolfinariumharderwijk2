# Correct definition of $ServerNames array
$ServerNames = @("vm-devops", "vm-exchange", "vm-adserver")  # Voeg hier de namen van de servers toe
$CriticalServices = @(
    'wuauserv', 'winmgmt', 'rpcss', 'schedule', 'samss', 'LanmanServer',
    'LanmanWorkstation', 'Dnscache', 'Dhcp', 'NlaSvc', 'Netlogon',
    'MpsSvc', 'Spooler',  'w32time', 'NTDS'
)

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
Function Show-Summary {
    foreach ($ServerName in $ServerNames) {
        Write-Host "`n--- Samenvatting van de serverstatus voor $ServerName ---"
        Get-CPUUsage -ServerName $ServerName
        Get-MemoryUsage -ServerName $ServerName
        Get-DiskSpace -ServerName $ServerName
        Get-NetworkConnectivity -ServerName $ServerName
        Get-CriticalServices -ServerName $ServerName
        Write-Host "`n--- Controles voltooid voor $ServerName ---"
    }
}

# Execute the summary
Show-Summary
