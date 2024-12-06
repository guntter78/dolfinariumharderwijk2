# Parameters instellen
param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    [Parameter(Mandatory=$true)]
    [string]$NetbiosName,
    [Parameter(Mandatory=$true)]
    [SecureString]$SafeModeAdministratorPassword
)

# Installeren van AD DS rol
Write-Host "Installeren van Active Directory Domain Services (AD DS)..."
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Configureren van het domein
Write-Host "Configureren van een nieuw Active Directory Forest op Windows Server 2022..."
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -ForestMode Win2022 `
    -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
    -Force

Write-Host "Active Directory-configuratie voltooid. De server zal automatisch opnieuw opstarten."
