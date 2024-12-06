# Parameters instellen
param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    [Parameter(Mandatory=$true)]
    [string]$NetbiosName,
    [Parameter(Mandatory=$true)]
    [SecureString]$SafeModeAdministratorPassword
)

# Controleer of de AD DS-rol al is geïnstalleerd
Write-Host "Controleren of Active Directory Domain Services (AD DS) al is geïnstalleerd..."
if (-not (Get-WindowsFeature -Name AD-Domain-Services).Installed) {
    Write-Host "Installeren van AD DS-rol..."
    Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
    Write-Host "AD DS-rol succesvol geïnstalleerd."
} else {
    Write-Host "AD DS-rol is al geïnstalleerd."
}

# Configureren van het domein
Write-Host "Controleren of een Active Directory-domein al aanwezig is..."
if (-not (Test-Path "$Env:SystemRoot\NTDS")) {
    try {
        Write-Host "Configureren van een nieuw Active Directory Forest op Windows Server 2022..."
        Install-ADDSForest `
            -DomainName $DomainName `
            -DomainNetbiosName $NetbiosName `
            -ForestMode Win2022 `
            -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
            -Force -ErrorAction Stop

        Write-Host "Active Directory-configuratie voltooid. De server zal automatisch opnieuw opstarten."
    } catch {
        Write-Error "Er is een fout opgetreden tijdens de configuratie: $_"
        exit 1
    }
} else {
    Write-Host "Er bestaat al een Active Directory-domein op deze server."
}
