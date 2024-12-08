param (
    [SecureString]$AdminPassword,
    [SecureString]$ServiceAccountPassword,
    [SecureString]$GuestPassword
)

# ========================
# 📁 Pad naar logbestand
# ========================
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

Write-Log "Start van aduser.ps1 - Toevoegen van gebruikers aan Active Directory..."

# ========================
# 🔍 Organizational Units
# ========================
New-ADOrganizationalUnit -Name "Students" -Path "DC=uvh,DC=nl" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name "Staff" -Path "DC=uvh,DC=nl" -ErrorAction SilentlyContinue
New-ADOrganizationalUnit -Name "ICT Support" -Path "DC=uvh,DC=nl" -ErrorAction SilentlyContinue
Write-Log "OU's zijn aangemaakt (indien nodig)."

# ========================
# 🔍 Groepen
# ========================
New-ADGroup -Name "Administrators" -GroupScope Global -Path "OU=ICT Support,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
New-ADGroup -Name "Students" -GroupScope Global -Path "OU=Students,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
Write-Log "Groepen zijn aangemaakt (indien nodig)."

# ========================
# 🔍 Serviceaccounts
# ========================
New-ADUser -Name "NPE-Account" -AccountPassword $ServiceAccountPassword -Enabled $true -Path "OU=ICT Support,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
New-ADUser -Name "GuestAccount" -AccountPassword $GuestPassword -Enabled $true -Path "OU=Students,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
Write-Log "Serviceaccounts zijn aangemaakt (indien nodig)."

# ========================
# 🔍 Admin Gebruikers
# ========================
$adminUsers = @("rudyadmin", "marnixadmin", "allardadmin", "wilmeradmin", "emmaadmin")
foreach ($user in $adminUsers) {
    New-ADUser -Name $user -AccountPassword $AdminPassword -Enabled $true -Path "OU=ICT Support,DC=uvh,DC=nl" -ErrorAction SilentlyContinue
    Add-ADGroupMember -Identity "Administrators" -Members $user -ErrorAction SilentlyContinue
    Write-Log "Gebruiker $user is aangemaakt en toegevoegd aan de groep Administrators (indien nodig)."
}

Write-Log "Gebruikersconfiguratie voltooid."
exit 0
