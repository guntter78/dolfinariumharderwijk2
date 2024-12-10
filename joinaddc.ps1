param (
    [string]$DomainName,
    [string]$SafeModeAdministratorPassword,
    [string]$AdminUsername,
    [string]$AdminPassword,
    [string]$SiteName
)

# Log de ontvangen parameters
Write-Host "Ontvangen parameters:"
Write-Host "DomainName: $DomainName"
Write-Host "SiteName: $SiteName"
Write-Host "AdminUsername: $AdminUsername"

# Zet de wachtwoorden om naar SecureString
$SecureDSRMPassword = ConvertTo-SecureString $SafeModeAdministratorPassword -AsPlainText -Force
$SecureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force

# Maak een PSCredential object voor de Admin
$Credential = New-Object System.Management.Automation.PSCredential ($AdminUsername, $SecureAdminPassword)

# Configureer de DNS-server
$dnsServerIp = "10.10.2.6"
Write-Host "Configureren van de DNS-server naar $dnsServerIp..."
try {
    $interfaces = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null }
    Set-DnsClientServerAddress -InterfaceAlias $interfaces.InterfaceAlias -ServerAddresses ($dnsServerIp)
    Write-Host "DNS-serverconfiguratie voltooid. Ingesteld op $dnsServerIp."
} catch {
    Write-Host "Fout bij het configureren van de DNS-server: $_"
    exit 1
}

# Voeg de server toe als domeincontroller
Write-Host "Active Directory configureren als domeincontroller..."
try {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
    Write-Host "AD-Domain-Services is succesvol geïnstalleerd."
} catch {
    Write-Host "Fout bij het installeren van de AD DS-rol: $_"
    exit 1
}

try {
    Write-Host "Server toevoegen als domeincontroller aan het domein $DomainName met site $SiteName..."
    Install-ADDSDomainController `
        -DomainName $DomainName `
        -SafeModeAdministratorPassword $SecureDSRMPassword `
        -Credential $Credential `
        -SiteName $SiteName `
        -Force
    Write-Host "Server succesvol toegevoegd als domeincontroller aan het domein $DomainName."
} catch {
    Write-Host "Fout bij het toevoegen van de server als domeincontroller: $_"
    exit 1
}
