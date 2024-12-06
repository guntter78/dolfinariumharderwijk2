param (
    [string]$DomainName,
    [string]$NetbiosName,
    [SecureString]$SafeModeAdministratorPassword,
    [SecureString]$AdminPassword,
    [SecureString]$ServiceAccountPassword,
    [SecureString]$GuestPassword
)

$scriptPath = "C:\Scripts"

# Stap 1: Active Directory configureren
Write-Host "Stap 1: Configureren van Active Directory..."
powershell -ExecutionPolicy Bypass -File "$scriptPath\ad.ps1" `
    -DomainName $DomainName `
    -NetbiosName $NetbiosName `
    -SafeModeAdministratorPassword $SafeModeAdministratorPassword

# Stap 2: Gebruikers toevoegen
Write-Host "Stap 2: Gebruikers toevoegen..."
powershell -ExecutionPolicy Bypass -File "$scriptPath\aduser.ps1" `
    -AdminPassword $AdminPassword `
    -ServiceAccountPassword $ServiceAccountPassword `
    -GuestPassword $GuestPassword

# Stap 3: IIS configureren
Write-Host "Stap 3: IIS configureren..."
powershell -ExecutionPolicy Bypass -File "$scriptPath\iis.ps1"

# Stap 4: DHCP configureren
Write-Host "Stap 4: DHCP configureren..."
powershell -ExecutionPolicy Bypass -File "$scriptPath\dhcp.ps1"

Write-Host "Alle configuraties zijn voltooid."
