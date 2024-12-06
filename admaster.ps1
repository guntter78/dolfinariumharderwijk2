param (
    [string]$DomainName,
    [string]$NetbiosName,
    [SecureString]$SafeModeAdministratorPassword
)

# Download scripts van GitHub
$scriptRepo = "https://raw.githubusercontent.com/guntter78/dolfinariumharderwijk2/main/"
$scripts = @("ad.ps1", "aduser.ps1", "iis.ps1", "dhcp.ps1")
$localPath = "C:\Scripts"

if (!(Test-Path -Path $localPath)) {
    New-Item -ItemType Directory -Path $localPath
}

foreach ($script in $scripts) {
    $url = "$scriptRepo$script"
    $destination = Join-Path -Path $localPath -ChildPath $script
    Write-Host "Downloaden van $url naar $destination..."
    Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing
}

# Active Directory configureren
Write-Host "Stap 1: Configureren van Active Directory..."
powershell -ExecutionPolicy Bypass -File "$localPath\ad.ps1" `
    -DomainName $DomainName `
    -NetbiosName $NetbiosName `
    -SafeModeAdministratorPassword $SafeModeAdministratorPassword

# Gebruikers toevoegen
Write-Host "Stap 2: Gebruikers toevoegen..."
powershell -ExecutionPolicy Bypass -File "$localPath\aduser.ps1"

# IIS configureren
Write-Host "Stap 3: IIS configureren..."
powershell -ExecutionPolicy Bypass -File "$localPath\iis.ps1"

# DHCP configureren
Write-Host "Stap 4: DHCP configureren..."
powershell -ExecutionPolicy Bypass -File "$localPath\dhcp.ps1"

Write-Host "Alle configuraties zijn voltooid!"
