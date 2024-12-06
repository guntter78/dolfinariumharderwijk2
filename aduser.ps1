param (
    [SecureString]$AdminPassword,
    [SecureString]$ServiceAccountPassword,
    [SecureString]$GuestPassword
)

Write-Host "Toevoegen van gebruikers aan Active Directory..."

# Organizational Units
New-ADOrganizationalUnit -Name "Students" -Path "DC=uvh,DC=nl"
New-ADOrganizationalUnit -Name "Staff" -Path "DC=uvh,DC=nl"
New-ADOrganizationalUnit -Name "ICT Support" -Path "DC=uvh,DC=nl"

# Gebruikers en Groepen
New-ADGroup -Name "Administrators" -GroupScope Global -Path "OU=ICT Support,DC=uvh,DC=nl"
New-ADGroup -Name "Students" -GroupScope Global -Path "OU=Students,DC=uvh,DC=nl"

# Serviceaccounts
New-ADUser -Name "NPE-Account" -AccountPassword $ServiceAccountPassword -Enabled $true -Path "OU=ICT Support,DC=uvh,DC=nl"
New-ADUser -Name "GuestAccount" -AccountPassword $GuestPassword -Enabled $true -Path "OU=Students,DC=uvh,DC=nl"

# Admin Gebruikers
$adminUsers = @("rudyadmin", "marnixadmin", "allardadmin", "wilmeradmin", "emmaadmin")
foreach ($user in $adminUsers) {
    New-ADUser -Name $user -AccountPassword $AdminPassword -Enabled $true -Path "OU=ICT Support,DC=uvh,DC=nl"
    Add-ADGroupMember -Identity "Administrators" -Members $user
}

Write-Host "Gebruikersconfiguratie voltooid."
