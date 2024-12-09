# ========================
# 📁 Parameters
# ========================
$ServiceAccountPassword = (ConvertTo-SecureString -String '' -AsPlainText -Force)
$GuestPassword = (ConvertTo-SecureString -String '' -AsPlainText -Force)
$AdminPassword = (ConvertTo-SecureString -String '' -AsPlainText -Force)

$domain = "DC=uvh,DC=nl"
$ouICTSupport = "OU=ICT Support,$domain"
$ouStudents = "OU=Students,$domain"
$ouStaff = "OU=Staff,$domain"

# ========================
# 📁 Stap 1: Maak Organizational Units (OU's) aan
# ========================
try {
    Write-Host "Controleren of de OU's bestaan en aanmaken indien nodig..." -ForegroundColor Cyan
    
    # OU ICT Support
    if (-not (Get-ADOrganizationalUnit -Filter {DistinguishedName -eq $ouICTSupport} -ErrorAction SilentlyContinue)) {
        Write-Host "OU 'ICT Support' bestaat niet. Aanmaken..." -ForegroundColor Yellow
        New-ADOrganizationalUnit -Name "ICT Support" -Path "DC=uvh,DC=nl" -ErrorAction Stop
        Write-Host "OU 'ICT Support' succesvol aangemaakt." -ForegroundColor Green
    } else {
        Write-Host "OU 'ICT Support' bestaat al." -ForegroundColor Green
    }

    # OU Students
    if (-not (Get-ADOrganizationalUnit -Filter {DistinguishedName -eq $ouStudents} -ErrorAction SilentlyContinue)) {
        Write-Host "OU 'Students' bestaat niet. Aanmaken..." -ForegroundColor Yellow
        New-ADOrganizationalUnit -Name "Students" -Path "DC=uvh,DC=nl" -ErrorAction Stop
        Write-Host "OU 'Students' succesvol aangemaakt." -ForegroundColor Green
    } else {
        Write-Host "OU 'Students' bestaat al." -ForegroundColor Green
    }

    # OU Staff
    if (-not (Get-ADOrganizationalUnit -Filter {DistinguishedName -eq $ouStaff} -ErrorAction SilentlyContinue)) {
        Write-Host "OU 'Staff' bestaat niet. Aanmaken..." -ForegroundColor Yellow
        New-ADOrganizationalUnit -Name "Staff" -Path "DC=uvh,DC=nl" -ErrorAction Stop
        Write-Host "OU 'Staff' succesvol aangemaakt." -ForegroundColor Green
    } else {
        Write-Host "OU 'Staff' bestaat al." -ForegroundColor Green
    }

} catch {
    Write-Host "Fout bij het aanmaken van de Organizational Units: $($_.Exception.Message)" -ForegroundColor Red
}

# ========================
# 📁 Stap 2: Maak groepen aan
# ========================
try {
    Write-Host "Controleren of de groepen bestaan en aanmaken indien nodig..." -ForegroundColor Cyan

    # Groep Administrators
    if (-not (Get-ADGroup -Filter {Name -eq "Administrators"} -ErrorAction SilentlyContinue)) {
        Write-Host "Groep 'Administrators' bestaat niet. Aanmaken..." -ForegroundColor Yellow
        New-ADGroup -Name "Administrators" -GroupScope Global -Path $ouICTSupport -ErrorAction Stop
        Write-Host "Groep 'Administrators' succesvol aangemaakt." -ForegroundColor Green
    } else {
        Write-Host "Groep 'Administrators' bestaat al." -ForegroundColor Green
    }

    # Groep Students
    if (-not (Get-ADGroup -Filter {Name -eq "Students"} -ErrorAction SilentlyContinue)) {
        Write-Host "Groep 'Students' bestaat niet. Aanmaken..." -ForegroundColor Yellow
        New-ADGroup -Name "Students" -GroupScope Global -Path $ouStudents -ErrorAction Stop
        Write-Host "Groep 'Students' succesvol aangemaakt." -ForegroundColor Green
    } else {
        Write-Host "Groep 'Students' bestaat al." -ForegroundColor Green
    }

} catch {
    Write-Host "Fout bij het aanmaken van groepen: $($_.Exception.Message)" -ForegroundColor Red
}

# ========================
# 📁 Stap 3: Maak serviceaccounts aan
# ========================
try {
    Write-Host "Aanmaken van serviceaccounts..." -ForegroundColor Cyan

    New-ADUser -Name "NPE-Account" `
               -AccountPassword $ServiceAccountPassword `
               -Enabled $true `
               -Path $ouICTSupport `
               -ErrorAction Stop

    Write-Host "Serviceaccount 'NPE-Account' succesvol aangemaakt." -ForegroundColor Green

    New-ADUser -Name "GuestAccount" `
               -AccountPassword $GuestPassword `
               -Enabled $true `
               -Path $ouStudents `
               -ErrorAction Stop

    Write-Host "Serviceaccount 'GuestAccount' succesvol aangemaakt." -ForegroundColor Green

} catch {
    Write-Host "Fout bij het aanmaken van serviceaccounts: $($_.Exception.Message)" -ForegroundColor Red
}

# ========================
# 📁 Stap 4: Maak admin-gebruikers aan
# ========================
try {
    Write-Host "Aanmaken van admin-gebruikers..." -ForegroundColor Cyan

    $adminUsers = @("rudyadmin", "marnixadmin", "allardadmin", "wilmeradmin", "emmaadmin")
    foreach ($user in $adminUsers) {
        try {
            New-ADUser -Name $user `
                       -AccountPassword $AdminPassword `
                       -Enabled $true `
                       -Path $ouICTSupport `
                       -ErrorAction Stop

            Write-Host "Admin gebruiker '$user' succesvol aangemaakt." -ForegroundColor Green

            Add-ADGroupMember -Identity "Administrators" `
                              -Members $user `
                              -ErrorAction Stop

            Write-Host "Gebruiker '$user' succesvol toegevoegd aan de groep 'Administrators'." -ForegroundColor Green

        } catch {
            Write-Host "Fout bij het aanmaken van admin gebruiker '$user': $($_.Exception.Message)" -ForegroundColor Red
        }
    }

} catch {
    Write-Host "Fout bij het toevoegen van admin-gebruikers: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Einde van het script - Alle taken zijn voltooid." -ForegroundColor Cyan
exit 0
