# ========================
# 📁 Pad naar logbestand
# ========================
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

Write-Log "Start van aduser.ps1 - Toevoegen van gebruikers aan Active Directory..."

# 🔐 Haal de wachtwoorden op uit protectedSettings
try {
    $protectedSettings = ConvertFrom-Json $env:AZURE_PROTECTED_SETTINGS

    $AdminPassword = $protectedSettings.AdminPassword | ConvertTo-SecureString -AsPlainText -Force
    $ServiceAccountPassword = $protectedSettings.ServiceAccountPassword | ConvertTo-SecureString -AsPlainText -Force
    $GuestPassword = $protectedSettings.GuestPassword | ConvertTo-SecureString -AsPlainText -Force

    Write-Log "Wachtwoorden zijn succesvol opgehaald en geconverteerd naar SecureString."
} catch {
    Write-Log "Fout bij het ophalen van de wachtwoorden: $($_.Exception.Message)"
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
