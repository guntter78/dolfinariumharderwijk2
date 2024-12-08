param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    [Parameter(Mandatory=$true)]
    [string]$NetbiosName,
    [Parameter(Mandatory=$true)]
    [string]$SafeModeAdministratorPassword
)

# Specificeer de exacte map
$localPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.17\Downloads\0"

# Controleer of de map bestaat
if (!(Test-Path -Path $localPath)) {
    Write-Error "Scripts zijn niet gevonden in de map: $localPath"
    exit 1
}
Write-Host "Scripts gevonden in map: $localPath"

# Check of dit de tweede keer is dat het script wordt uitgevoerd
$flagFile = "C:\post-ad-config-completed.txt"
if (Test-Path $flagFile) {
    Write-Host "Post AD-configuratie is al voltooid. Dit script wordt niet opnieuw uitgevoerd."
    exit 0
}

# Converteer het wachtwoord naar een SecureString
$SecurePassword = ConvertTo-SecureString $SafeModeAdministratorPassword -AsPlainText -Force

# Voeg een RunOnce-opdracht toe voor na de herstart
$runOnceCommand = "powershell.exe -ExecutionPolicy Bypass -File '$localPath\admaster.ps1' -DomainName $DomainName -NetbiosName $NetbiosName -SafeModeAdministratorPassword $SafeModeAdministratorPassword"
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce' `
    -Name 'PostADConfig' `
    -Value $runOnceCommand

# Active Directory configureren
Write-Host "Stap 1: Installeren en configureren van Active Directory..."

# Import the Server Manager module
Import-Module ServerManager

# Install the AD DS role
Write-Host "Installing Active Directory Domain Services (AD DS) role..."
try {
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
    Write-Host "AD DS role installed successfully."
} catch {
    Write-Error "Fout bij het installeren van de AD DS-rol: $($_.Exception.Message)"
    exit 1
}

# Configure a new Active Directory Forest
Write-Host "Configuring a new Active Directory Forest..."
try {
    Install-ADDSForest `
        -DomainName $DomainName `
        -DomainNetbiosName $NetbiosName `
        -SafeModeAdministratorPassword $SecurePassword `
        -Force
    Write-Host "Active Directory configuratie voltooid. De server zal opnieuw opstarten."
} catch {
    Write-Error "Fout bij het configureren van de AD-forest: $($_.Exception.Message)"
    exit 1
}

# De stappen na de herstart worden hieronder uitgevoerd

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

# Markeer het script als voltooid door een bestand aan te maken
New-Item -ItemType File -Path $flagFile

Write-Host "Alle configuraties zijn succesvol voltooid!"
