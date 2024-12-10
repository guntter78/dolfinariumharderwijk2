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
# 🔄 Laad parameters uit JSON
# ========================

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
        
        # Voeg de server toe als domeincontroller in een bestaand domein
        Install-ADDSDomainController `
            -DomainName $DomainName `
            -SafeModeAdministratorPassword $SecurePassword `
            -Credential $DomainAdminCredential `
            -SiteName $SiteName `
            -Force

        Write-Log "Server succesvol toegevoegd als domeincontroller aan het domein $DomainName."
        
        New-Item -ItemType File -Path $markerFile
        Write-Log "Marker-bestand aangemaakt: $markerFile"
    } catch {
        Write-Log "Fout bij het toevoegen van de server als domeincontroller: $($_.Exception.Message)"
        exit 1
    }
}