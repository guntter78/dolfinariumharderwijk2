param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    
    [Parameter(Mandatory=$true)]
    [SecureString]$SafeModeAdministratorPassword,
    
    [Parameter(Mandatory=$true)]
    [string]$AdminUsername,
    
    [Parameter(Mandatory=$true)]
    [SecureString]$AdminPassword,
    
    [Parameter(Mandatory=$true)]
    [string]$SiteName
)

$markerFile = "C:\ADConfig.marker"
$dnsServerIp = "10.10.2.6"
$logFile = "C:\makeaduserlog.txt"

# ========================
# 📝 Functie: Logging
# ========================
function Write-Log {
    param ([string]$message)
    $timeStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timeStamp - $message"
    Write-Output $logMessage | Out-File -FilePath $logFile -Append
}

# ========================
# 🌐 Configureer DNS-servers
# ========================
try {
    Write-Log "Configureren van de DNS-server naar $dnsServerIp..."
    $interfaces = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null }
    Set-DnsClientServerAddress -InterfaceAlias $interfaces.InterfaceAlias -ServerAddresses ($dnsServerIp)
    Write-Log "DNS-serverconfiguratie voltooid. Ingesteld op $dnsServerIp."
} catch {
    Write-Log "Fout bij het configureren van de DNS-server: $($_.Exception.Message)"
    exit 1
}

# ========================
# 🏗️ Installeren en configureren van domeincontroller
# ========================
if (Test-Path $markerFile) {
    Write-Log "Active Directory is al geïnstalleerd. Sla de AD-configuratie over, maar voer overige taken uit."
} else {
    try {
        Write-Log "Active Directory is nog niet geconfigureerd. Ga door met de configuratie."
        
        Write-Log "Stap 1: Installeren van Active Directory Domain Services..."
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
        Write-Log "AD-Domain-Services is succesvol geïnstalleerd."
    } catch {
        Write-Log "Fout bij het installeren van de AD DS-rol: $($_.Exception.Message)"
        exit 1
    }

    try {
        Write-Log "Stap 2: Toevoegen van de server als domeincontroller aan het bestaande domein..."
        
        # Zet de referenties van de domeinbeheerder (AdminUsername en AdminPassword) om naar een PSCredential-object
        $Credential = New-Object System.Management.Automation.PSCredential ($AdminUsername, $AdminPassword)
        
        # Voeg de server toe als domeincontroller in een bestaand domein
        Install-ADDSDomainController `
            -DomainName $DomainName `
            -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
            -Credential $Credential `
            -SiteName $SiteName `
            -Force

        Write-Log "Server succesvol toegevoegd als domeincontroller aan het domein $DomainName."
        
        # Maak een markerbestand aan zodat het script niet nogmaals wordt uitgevoerd
        New-Item -ItemType File -Path $markerFile
        Write-Log "Marker-bestand aangemaakt: $markerFile"
    } catch {
        Write-Log "Fout bij het toevoegen van de server als domeincontroller: $($_.Exception.Message)"
        exit 1
    }
}
