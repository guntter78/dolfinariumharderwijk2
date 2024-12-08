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

# Converteer het wachtwoord naar een SecureString
$SecurePassword = ConvertTo-SecureString $SafeModeAdministratorPassword -AsPlainText -Force

# Controleer of AD al is geconfigureerd
try {
    $domainCheck = Get-ADDomain -ErrorAction Stop
    Write-Host "Active Directory is al geconfigureerd. Sla de installatie over."
    $adExists = $true
} catch {
    Write-Host "Active Directory is nog niet geconfigureerd. Ga door met de configuratie."
    $adExists = $false
}

# Voer AD-installatie alleen uit als het nog niet is geconfigureerd
if (-not $adExists) {
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
}

# **Post-reboot configuratie**
# Wacht tot ADWS (Active Directory Web Services) is gestart
$timeout = 900  # Maximaal 15 minuten
$startTime = Get-Date
do {
    try {
        $adwsStatus = Get-Service -Name "ADWS" -ErrorAction Stop
    } catch {
        Write-Host "$(Get-Date) - Wachten op Active Directory Web Services (ADWS) om te starten..."
    }
    Start-Sleep -Seconds 30
    $currentTime = Get-Date
    $elapsedTime = ($currentTime - $startTime).TotalSeconds
} until ($adwsStatus.Status -eq 'Running' -or $elapsedTime -ge $timeout)

if ($adwsStatus.Status -eq 'Running') {
    Write-Host "Active Directory Web Services (ADWS) is nu beschikbaar."
} else {
    Write-Error "ADWS is na 15 minuten nog niet gestart."
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
