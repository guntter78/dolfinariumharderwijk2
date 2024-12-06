param (
    [Parameter(Mandatory=$true)]
    [string]$DomainName,
    [Parameter(Mandatory=$true)]
    [string]$NetbiosName,
    [Parameter(Mandatory=$true)]
    [string]$ForestMode,
    [Parameter(Mandatory=$true)]
    [SecureString]$SafeModeAdministratorPassword
)

# Import the Server Manager module
Import-Module ServerManager

# Install the AD DS role
Write-Host "Installing Active Directory Domain Services (AD DS) role..."
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools -ErrorAction Stop
Write-Host "AD DS role installed successfully."

# Configure a new Active Directory Forest
Write-Host "Configuring a new Active Directory Forest..."
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -ForestMode Win2019 `
    -SafeModeAdministratorPassword $SafeModeAdministratorPassword `
    -Force

Write-Host "Active Directory configuration completed. The server will restart automatically."