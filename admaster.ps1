param (
    [string]$DomainName,
    [string]$NetbiosName,
    [string]$SafeModeAdministratorPassword
)

# Specificeer de exacte map
$localPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.17\Downloads\2"

# Controleer of de map bestaat
if (!(Test-Path -Path $localPath)) {
    Write-Error "Scripts zijn niet gevonden in de map: $localPath"
    exit 1
}

Write-Host "Scripts gevonden in map: $localPath"

# Converteer het wachtwoord naar een SecureString
$SecurePassword = ConvertTo-SecureString $SafeModeAdministratorPassword -AsPlainText -Force

# Active Directory configureren
Write-Host "Stap 1: Configureren van Active Directory..."
try {
    powershell -ExecutionPolicy Bypass -File "$localPath\admake.ps1" `
        -DomainName $DomainName `
        -NetbiosName $NetbiosName `
        -SafeModeAdministratorPassword $SecurePassword -ErrorAction Stop
    Write-Host "Active Directory configuratie voltooid."
} catch {
    Write-Error "Fout bij het configureren van Active Directory: $($_.Exception.Message)"
    exit 1
}

# Gebruikers toevoegen
Write-Host "Stap 2: Gebruikers toevoegen..."
try {
    powershell -ExecutionPolicy Bypass -File "$localPath\aduser.ps1" -ErrorAction Stop
    Write-Host "Gebruikers succesvol toegevoegd."
} catch {
    Write-Error "Fout bij het toevoegen van gebruikers: $($_.Exception.Message)"
    exit 1
}

# IIS configureren
Write-Host "Stap 3: IIS configureren..."
try {
    powershell -ExecutionPolicy Bypass -File "$localPath\iis.ps1" -ErrorAction Stop
    Write-Host "IIS-configuratie voltooid."
} catch {
    Write-Error "Fout bij het configureren van IIS: $($_.Exception.Message)"
    exit 1
}

# DHCP configureren
Write-Host "Stap 4: DHCP configureren..."
try {
    powershell -ExecutionPolicy Bypass -File "$localPath\dhcp.ps1" -ErrorAction Stop
    Write-Host "DHCP-configuratie voltooid."
} catch {
    Write-Error "Fout bij het configureren van DHCP: $($_.Exception.Message)"
    exit 1
}

Write-Host "Alle configuraties zijn succesvol voltooid!"
