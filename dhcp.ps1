Write-Host "Installeren van DHCP-serverrol..."
Install-WindowsFeature DHCP -IncludeManagementTools

Write-Host "Configureren van DHCP-scopes..."

# VLAN 10 - Beheer
Add-DhcpServerv4Scope -Name "Beheer" -StartRange "10.0.0.100" -EndRange "10.0.0.200" -SubnetMask "255.255.252.0"
Set-DhcpServerv4OptionValue -ScopeId "10.0.0.0" -OptionId 3 -Value "10.0.0.1"

# VLAN 11 - Staf
Add-DhcpServerv4Scope -Name "Staf" -StartRange "10.1.0.100" -EndRange "10.1.0.200" -SubnetMask "255.255.252.0"
Set-DhcpServerv4OptionValue -ScopeId "10.1.0.0" -OptionId 3 -Value "10.1.0.1"

# VLAN 12 - Onderwijs
Add-DhcpServerv4Scope -Name "Onderwijs" -StartRange "10.1.2.100" -EndRange "10.1.2.200" -SubnetMask "255.255.252.0"
Set-DhcpServerv4OptionValue -ScopeId "10.1.2.0" -OptionId 3 -Value "10.1.2.1"

# VLAN 13 - Datacentrum
Add-DhcpServerv4Scope -Name "Datacentrum" -StartRange "10.0.128.100" -EndRange "10.0.131.200" -SubnetMask "255.255.252.0"
Set-DhcpServerv4OptionValue -ScopeId "10.0.128.0" -OptionId 3 -Value "10.0.128.1"

# VLAN 14 - Int ISP
Add-DhcpServerv4Scope -Name "Int ISP" -StartRange "10.1.3.100" -EndRange "10.1.3.200" -SubnetMask "255.255.252.0"
Set-DhcpServerv4OptionValue -ScopeId "10.1.3.0" -OptionId 3 -Value "10.1.3.1"

Write-Host "Herstarten van DHCP-service..."
Restart-Service DHCPServer

Write-Host "DHCP-configuratie voltooid."
