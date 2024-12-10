param (
    [string]$DomainName,
    [string]$SafeModeAdministratorPassword,
    [string]$AdminUsername,
    [string]$AdminPassword,
    [string]$SiteName
)

# Start PowerShell-transcript (log de volledige uitvoer)
Start-Transcript -Path "C:\install-ad-log.txt"

# Log de ontvangen parameters (inclusief het wachtwoord)
Write-Host "Ontvangen parameters:" | Out-File -FilePath "C:\install-ad-log.txt" -Append
Write-Host "DomainName: $DomainName" | Out-File -FilePath "C:\install-ad-log.txt" -Append
Write-Host "SiteName: $SiteName" | Out-File -FilePath "C:\install-ad-log.txt" -Append
Write-Host "AdminUsername: $AdminUsername" | Out-File -FilePath "C:\install-ad-log.txt" -Append
Write-Host "AdminPassword (plaintext): $AdminPassword" | Out-File -FilePath "C:\install-ad-log.txt" -Append
Write-Host "SafeModeAdministratorPassword (plaintext): $SafeModeAdministratorPassword" | Out-File -FilePath "C:\install-ad-log.txt" -Append

# Zet de wachtwoorden om naar SecureString
$SecureDSRMPassword = ConvertTo-SecureString $SafeModeAdministratorPassword -AsPlainText -Force
$SecureAdminPassword = ConvertTo-SecureString $AdminPassword -AsPlainText -Force

# Controleer het type van de wachtwoordvariabelen
Write-Host "Type van SecureDSRMPassword: $($SecureDSRMPassword.GetType().FullName)" | Out-File -FilePath "C:\install-ad-log.txt" -Append
Write-Host "Type van SecureAdminPassword: $($SecureAdminPassword.GetType().FullName)" | Out-File -FilePath "C:\install-ad-log.txt" -Append

# Maak een PSCredential object voor de Admin
$Credential = New-Object System.Management.Automation.PSCredential ($AdminUsername, $SecureAdminPassword)

# 🛠️ Stap 1: Voeg de server toe aan het domein
try {
    Write-Host "Server toevoegen aan het domein $DomainName met gebruiker $AdminUsername..." | Out-File -FilePath "C:\install-ad-log.txt" -Append
    Add-Computer -DomainName $DomainName -Credential $Credential -Force
    Write-Host "Server succesvol toegevoegd aan het domein $DomainName." | Out-File -FilePath "C:\install-ad-log.txt" -Append
} catch {
    Write-Host "Fout bij het toevoegen aan het domein: $_" | Out-File -FilePath "C:\install-ad-log.txt" -Append
    exit 1
}

# 🛠️ Stap 2: Herstart de server na domeinjoin
try {
    Write-Host "Herstarten van de server na het toevoegen aan het domein..." | Out-File -FilePath "C:\install-ad-log.txt" -Append
    Restart-Computer -Force
} catch {
    Write-Host "Fout bij het herstarten van de server: $_" | Out-File -FilePath "C:\install-ad-log.txt" -Append
    exit 1
}

# 🛠️ Stap 3: Promoveer de server tot domeincontroller
try {
    Write-Host "Server toevoegen als domeincontroller aan het domein $DomainName met site $SiteName..." | Out-File -FilePath "C:\install-ad-log.txt" -Append
    Install-ADDSDomainController `
        -DomainName $DomainName `
        -SafeModeAdministratorPassword $SecureDSRMPassword `
        -Credential $Credential `
        -SiteName $SiteName `
        -Force

    Write-Host "Server succesvol toegevoegd als domeincontroller aan het domein $DomainName." | Out-File -FilePath "C:\install-ad-log.txt" -Append
    
    # Herstart de server na de installatie
    Write-Host "Herstarten van de server om de promotie te voltooien..." | Out-File -FilePath "C:\install-ad-log.txt" -Append
    Restart-Computer -Force
} catch {
    Write-Host "Fout bij het toevoegen als domeincontroller: $_" | Out-File -FilePath "C:\install-ad-log.txt" -Append
    exit 1
}

# Stop PowerShell-transcript
Stop-Transcript