# ========================
# 📁 Parameters
# ========================
$ExcelFilePath = "C:\Users\harderwijk-admin.UVH\Desktop\Bulk_Users_Template.xlsx"  
$mailDatabase = "Mailbox Database 1000089917"                

# ========================
# 📁 Controleer benodigde modules
# ========================
# Controleer of ImportExcel module aanwezig is
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host "De Import-Excel module is niet geïnstalleerd. Installeren..." -ForegroundColor Yellow
    Install-Module -Name ImportExcel -Force -Scope CurrentUser
}

# Controleer of Exchange Management Shell module aanwezig is
if (-not (Get-PSSnapin -Name Microsoft.Exchange.Management.PowerShell.SnapIn -ErrorAction SilentlyContinue)) {
    Write-Host "De Exchange Management Shell module is niet geladen. Laden..." -ForegroundColor Yellow
    Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn
}

# Controleer of Enable-Mailbox cmdlet beschikbaar is
if (-not (Get-Command Enable-Mailbox -ErrorAction SilentlyContinue)) {
    Write-Host "De cmdlet 'Enable-Mailbox' is niet beschikbaar. Controleer of je het script uitvoert in de Exchange Management Shell." -ForegroundColor Red
    exit
}

# ========================
# 📁 Gebruikers en mailboxen aanmaken
# ========================
try {
    Write-Host "Gebruikers laden vanuit Excel-bestand: $ExcelFilePath" -ForegroundColor Cyan
    $users = Import-Excel -Path $ExcelFilePath

    foreach ($user in $users) {
        try {
            # Lees gegevens uit Excel
            $firstName = $user.FirstName
            $lastName = $user.LastName
            $fullName = "$firstName $lastName"
            $samAccountName = $user.Username
            $password = (ConvertTo-SecureString -String $user.Password -AsPlainText -Force)
            $ou = $user.OU
            $group = $user.Group
            $homedir = $user.HomeDir
            $email = $user.Email

            # 1. Gebruiker aanmaken in Active Directory
            Write-Host "Voeg gebruiker '$fullName' toe aan AD..." -ForegroundColor Cyan
            New-ADUser -Name $fullName `
                       -GivenName $firstName `
                       -Surname $lastName `
                       -SamAccountName $samAccountName `
                       -UserPrincipalName $email `
                       -AccountPassword $password `
                       -Enabled $true `
                       -Path "$ou" `
                       -HomeDirectory $homedir `
                       -HomeDrive "H:" `
                       -ErrorAction Stop

            Write-Host "Gebruiker '$fullName' succesvol aangemaakt in AD." -ForegroundColor Green

            # 2. Gebruiker aan groep toevoegen
            if ($group -and (Get-ADGroup -Filter {Name -eq $group} -ErrorAction SilentlyContinue)) {
                Add-ADGroupMember -Identity $group -Members $samAccountName -ErrorAction Stop
                Write-Host "Gebruiker '$fullName' toegevoegd aan groep '$group'." -ForegroundColor Green
            } else {
                Write-Host "Groep '$group' bestaat niet. Gebruiker '$fullName' niet toegevoegd aan een groep." -ForegroundColor Yellow
            }

            # 3. Mailbox aanmaken in Exchange
            Write-Host "Maak mailbox voor '$fullName' aan..." -ForegroundColor Cyan
            Enable-Mailbox -Identity $email -Database $mailDatabase -ErrorAction Stop
            Write-Host "Mailbox voor '$fullName' succesvol aangemaakt." -ForegroundColor Green

        } catch {
            Write-Host "Fout bij verwerking van gebruiker '$($user.FirstName) $($user.LastName)': $($_.Exception.Message)" -ForegroundColor Red
        }
    }

} catch {
    Write-Host "Fout bij het laden of verwerken van Excel-bestand: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Einde van het script - Alle gebruikers zijn verwerkt." -ForegroundColor Cyan
