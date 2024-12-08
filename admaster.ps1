param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    [Parameter(Mandatory=$true)]
    [string]$NetbiosName,
    [Parameter(Mandatory=$true)]
    [string]$SafeModeAdministratorPassword,
    [Parameter(Mandatory=$true)]
    [string]$AdminPassword,
    [Parameter(Mandatory=$true)]
    [string]$ServiceAccountPassword,
    [Parameter(Mandatory=$true)]
    [string]$GuestPassword
)


# ========================
# 📁 Pad naar bestanden
# ========================C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.17\Downloads\0
$localPath = "C:\Packages\Plugins\Microsoft.Compute.CustomScriptExtension\1.10.17\Downloads\0"
$markerFile = "C:\ADInstallComplete.txt"
$paramFilePath = "C:\ad-params.json"
$logFile = "C:\ConfigLog.txt"

# ========================
# 📝 Functie: Logging
# ========================
function Write-Log {
    param ([string]$message)
    $timeStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timeStamp - $message"
    Write-Output $logMessage | Out-File -FilePath $logFile -Append
}

Write-Log "Start van configuratie admaster.ps1"

# ========================
# 🔍 Parameterpersistentie
# ========================
try {
    $SecureAdminPassword = $AdminPassword | ConvertTo-SecureString -AsPlainText -Force
    $SecureServiceAccountPassword = $ServiceAccountPassword | ConvertTo-SecureString -AsPlainText -Force
    $SecureGuestPassword = $GuestPassword | ConvertTo-SecureString -AsPlainText -Force

    $parameters = @{
        AdminPassword = $SecureAdminPassword | ConvertFrom-SecureString
        ServiceAccountPassword = $SecureServiceAccountPassword | ConvertFrom-SecureString
        GuestPassword = $SecureGuestPassword | ConvertFrom-SecureString
    }

    $parameters | ConvertTo-Json -Depth 10 | Out-File -FilePath $paramFilePath -Force
    Write-Log "Wachtwoorden opgeslagen in: $paramFilePath"
} catch {
    Write-Log "Fout bij het opslaan van de wachtwoorden in JSON-bestand: $($_.Exception.Message)"
    exit 1
}

# ========================
# 🔐 Converteer wachtwoord naar SecureString
# ========================
try {
    $SecurePassword = ConvertTo-SecureString $SafeModeAdministratorPassword -AsPlainText -Force
} catch {
    Write-Log "Fout bij het converteren van het wachtwoord naar SecureString: $($_.Exception.Message)"
    exit 1
}


# ========================
# 🔍 Controleer of AD al is geïnstalleerd
# ========================
if (Test-Path $markerFile) {
    Write-Log "Active Directory is al geïnstalleerd. Sla de AD-configuratie over, maar voer overige taken uit."
} else {
    try {
        Write-Log "Active Directory is nog niet geconfigureerd. Ga door met de configuratie."
        Write-Log "Stap 1: Installeren van Active Directory..."
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
        Write-Log "AD-Domain-Services is succesvol geïnstalleerd."
    } catch {
        Write-Log "Fout bij het installeren van de AD DS-rol: $($_.Exception.Message)"
        exit 1
    }

    try {
        Write-Log "Stap 2: Configureren van een nieuwe Active Directory Forest..."
        Install-ADDSForest `
            -DomainName $DomainName `
            -DomainNetbiosName $NetbiosName `
            -SafeModeAdministratorPassword $SecurePassword `
            -Force
        Write-Log "Active Directory Forest-configuratie voltooid."
        New-Item -ItemType File -Path $markerFile
        Write-Log "Marker-bestand aangemaakt: $markerFile"
    } catch {
        Write-Log "Fout bij het configureren van de AD-forest: $($_.Exception.Message)"
        exit 1
    }
}

# ========================
# 👤 Voeg gebruikers toe
# ========================
try {
    Write-Log "Stap 3: Gebruikers toevoegen..."
    
    # Voer aduser.ps1 uit, zonder wachtwoorden als argumenten
    powershell -ExecutionPolicy Bypass -File "$localPath\aduser.ps1" -ErrorAction Stop

    Write-Log "Gebruikers succesvol toegevoegd."
} catch {
    Write-Log "Fout bij het toevoegen van gebruikers: $($_.Exception.Message)"
    exit 1
}


# ========================
# 🌐 Configureer IIS
# ========================
try {
    Write-Log "Stap 4: IIS configureren..."
    powershell -ExecutionPolicy Bypass -File "$localPath\iis.ps1" -ErrorAction Stop
    Write-Log "IIS-configuratie voltooid."
} catch {
    Write-Log "Fout bij het configureren van IIS: $($_.Exception.Message)"
    exit 1
}

# ========================
# 📡 Configureer DHCP
# ========================
try {
    Write-Log "Stap 5: DHCP configureren..."
    powershell -ExecutionPolicy Bypass -File "$localPath\dhcp.ps1" -ErrorAction Stop
    Write-Log "DHCP-configuratie voltooid."
} catch {
    Write-Log "Fout bij het configureren van DHCP: $($_.Exception.Message)"
    exit 1
}

Write-Log "Alle configuraties zijn succesvol voltooid."
exit 0
