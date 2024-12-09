# ========================
# 📁 Pad naar bestanden help
# ========================
$logFile = "C:\makeaduserlog.txt"
$paramFilePath = "C:\ad-params.json"

# ========================
# 📝 Functie: Logging
# ========================
function Write-Log {
    param ([string]$message)
    $timeStamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "$timeStamp - $message"
    Write-Output $logMessage | Out-File -FilePath $logFile -Append
}

# 🔄 **Controleer of de AD-cmdlets echt kunnen verbinden**
$maxWaitTime = 1200 # Wacht maximaal 20 minuten (1200 seconden)
$waitInterval = 30 # Controleer elke 30 seconden
$elapsedTime = 0

Write-Log "Controleer of toegang tot Active Directory beschikbaar is met Test-ADServiceAccess."
while (-not (Test-ADServiceAccess -ErrorAction SilentlyContinue)) {
    if ($elapsedTime -ge $maxWaitTime) {
        Write-Log "❌ Timeout bereikt: Active Directory is nog steeds niet beschikbaar na $maxWaitTime seconden."
        exit 1
    }
    Write-Log "🔄 Active Directory is nog niet beschikbaar. Wachten gedurende $waitInterval seconden..."
    Start-Sleep -Seconds $waitInterval
    $elapsedTime += $waitInterval
}
Write-Log "✅ Active Directory is beschikbaar."

# 🔄 **Wachten tot ADWS actief is**
try {
    $services = @("ADWS", "NTDS")
    $maxWaitTime = 1200 # Wacht maximaal 20 minuten (1200 seconden)
    $waitInterval = 30 # Controleer elke 30 seconden
    $elapsedTime = 0

    Write-Log "Controleer of AD-diensten actief zijn: $($services -join ', ')"
    foreach ($service in $services) {
        while (-not (Get-Service -Name $service -ErrorAction SilentlyContinue).Status -eq "Running") {
            if ($elapsedTime -ge $maxWaitTime) {
                Write-Log "❌ Timeout bereikt: Service '$service' is nog steeds niet actief na $maxWaitTime seconden."
                exit 1
            }
            Write-Log "🔄 Service '$service' is nog niet actief. Wachten gedurende $waitInterval seconden..."
            Start-Sleep -Seconds $waitInterval
            $elapsedTime += $waitInterval
        }
        Write-Log "✅ Service '$service' is actief."
    }
} catch {
    Write-Log "❌ Fout bij het controleren van de status van AD-diensten: $($_.Exception.Message)"
    exit 1
}

Write-Log "Start van aduser.ps1 - Toevoegen van gebruikers aan Active Directory..."

# 🔐 **Laad de wachtwoorden uit het JSON-bestand**
try {
    if (-not (Test-Path $paramFilePath)) {
        Write-Log "Fout: Parameterbestand niet gevonden: $paramFilePath"
        exit 1
    }

    $parameters = Get-Content -Path $paramFilePath | ConvertFrom-Json

    $AdminPassword = $parameters.AdminPassword | ConvertTo-SecureString
    $ServiceAccountPassword = $parameters.ServiceAccountPassword | ConvertTo-SecureString
    $GuestPassword = $parameters.GuestPassword | ConvertTo-SecureString

    Write-Log "Succesvol de wachtwoorden geladen uit $paramFilePath."
} catch {
    Write-Log "Fout bij het lezen van het parameterbestand: $($_.Exception.Message)"
    exit 1
}

# ========================
# 📁 Maak Organizational Units aan
# ========================
try {
    New-ADOrganizationalUnit -Name "Students" -Path "DC=uvh,DC=nl" -ErrorAction SilentlyContinue
    Write-Log "Organizational Unit 'Students' succesvol aangemaakt of bestaat al."
    
    New-ADOrganizationalUnit -Name "Staff" -Path "DC=uvh,DC=nl" -ErrorAction SilentlyContinue
    Write-Log "Organizational Unit 'Staff' succesvol aangemaakt of bestaat al."
    
    New-ADOrganizationalUnit -Name "ICT Support" -Path "DC=uvh,DC=nl" -ErrorAction SilentlyContinue
    Write-Log "Organizational Unit 'ICT Support' succesvol aangemaakt of bestaat al."
} catch {
    Write-Log "Fout bij het aanmaken van de Organizational Units: $($_.Exception.Message)"
}

# ========================
# 📁 Maak Groepen aan
# ========================
try {
    New-ADGroup -Name "Administrators" -GroupScope Global -Path "OU=ICT Support,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
    Write-Log "Groep 'Administrators' succesvol aangemaakt of bestaat al."

    New-ADGroup -Name "Students" -GroupScope Global -Path "OU=Students,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
    Write-Log "Groep 'Students' succesvol aangemaakt of bestaat al."
} catch {
    Write-Log "Fout bij het aanmaken van groepen: $($_.Exception.Message)"
}

# ========================
# 📁 Maak serviceaccounts aan
# ========================
try {
    New-ADUser -Name "NPE-Account" -AccountPassword $ServiceAccountPassword -Enabled $true -Path "OU=ICT Support,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
    Write-Log "Serviceaccount 'NPE-Account' succesvol aangemaakt."

    New-ADUser -Name "GuestAccount" -AccountPassword $GuestPassword -Enabled $true -Path "OU=Students,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
    Write-Log "Serviceaccount 'GuestAccount' succesvol aangemaakt."
} catch {
    Write-Log "Fout bij het aanmaken van serviceaccounts: $($_.Exception.Message)"
}

# ========================
# 📁 Voeg admin-gebruikers toe
# ========================
try {
    $adminUsers = @("rudyadmin", "marnixadmin", "allardadmin", "wilmeradmin", "emmaadmin")
    foreach ($user in $adminUsers) {
        try {
            New-ADUser -Name $user -AccountPassword $AdminPassword -Enabled $true -Path "OU=ICT Support,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
            Write-Log "Admin gebruiker '$user' succesvol aangemaakt."
            
            Add-ADGroupMember -Identity "Administrators" -Members $user -ErrorAction SilentlyContinue
            Write-Log "Gebruiker '$user' succesvol toegevoegd aan de groep 'Administrators'."
        } catch {
            Write-Log "Fout bij het aanmaken van admin gebruiker '$user': $($_.Exception.Message)"
        }
    }
} catch {
    Write-Log "Fout bij het toevoegen van admin-gebruikers: $($_.Exception.Message)"
}

Write-Log "Einde van aduser.ps1 - Alle gebruikers zijn succesvol toegevoegd."
exit 0
