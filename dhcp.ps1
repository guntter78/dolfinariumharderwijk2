# Installeren van de DHCP-serverrol
Write-Host "Installeren van DHCP-serverrol..."
Install-WindowsFeature DHCP -IncludeManagementTools

Write-Host "Configureren van DHCP-scopes..."

# VLAN 10 - Beheer (Subnet: 10.0.0.0/24)
Add-DhcpServerv4Scope -Name "Beheer" -StartRange "10.0.0.100" -EndRange "10.0.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.0.0.0" -OptionId 3 -Value "10.0.0.1"

# VLAN 11 - Staf (Subnet: 10.1.0.0/24)
Add-DhcpServerv4Scope -Name "Staf" -StartRange "10.1.0.100" -EndRange "10.1.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.1.0.0" -OptionId 3 -Value "10.1.0.1"

# VLAN 12 - Onderwijs (Subnet: 10.1.2.0/24)
Add-DhcpServerv4Scope -Name "Onderwijs" -StartRange "10.1.2.100" -EndRange "10.1.2.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.1.2.0" -OptionId 3 -Value "10.1.2.1"

# VLAN 13 - Datacentrum (Subnet: 10.0.128.0/22)
Add-DhcpServerv4Scope -Name "Datacentrum" -StartRange "10.0.128.100" -EndRange "10.0.131.200" -SubnetMask "255.255.252.0"
Set-DhcpServerv4OptionValue -ScopeId "10.0.128.0" -OptionId 3 -Value "10.0.128.1"

# VLAN 14 - Int ISP (Subnet: 10.1.3.0/24)
Add-DhcpServerv4Scope -Name "Int ISP" -StartRange "10.1.3.100" -EndRange "10.1.3.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.1.3.0" -OptionId 3 -Value "10.1.3.1"

# Configuratie voor VLAN20 (10.2.0.0/24 - Nunspeet)
Add-DhcpServerv4Scope -Name "Nunspeet VLAN20" -StartRange "10.2.0.100" -EndRange "10.2.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.2.0.0" -OptionId 3 -Value "10.2.0.1"

# Configuratie voor VLAN21 (10.2.1.0/24 - Onderwijs)
Add-DhcpServerv4Scope -Name "Onderwijs VLAN21" -StartRange "10.2.1.100" -EndRange "10.2.1.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.2.1.0" -OptionId 3 -Value "10.2.1.1"

# Configuratie voor VLAN30 (10.3.0.0/24 - Putten)
Add-DhcpServerv4Scope -Name "Putten VLAN30" -StartRange "10.3.0.100" -EndRange "10.3.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.3.0.0" -OptionId 3 -Value "10.3.0.1"

# Configuratie voor VLAN31 (10.3.1.0/24 - Onderwijs)
Add-DhcpServerv4Scope -Name "Onderwijs VLAN31" -StartRange "10.3.1.100" -EndRange "10.3.1.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.3.1.0" -OptionId 3 -Value "10.3.1.1"

# Configuratie voor VLAN20 (10.2.0.0/24 - Nunspeet)
Add-DhcpServerv4Scope -ComputerName "Windowsadserver" -Name "Nunspeet VLAN20" -StartRange "10.2.0.100" -EndRange "10.2.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ComputerName "Windowsadserver" -ScopeId "10.2.0.0" -OptionId 3 -Value "10.2.0.1"

# Configuratie voor VLAN21 (10.2.1.0/24 - Onderwijs)
Add-DhcpServerv4Scope -ComputerName "Windowsadserver" -Name "Onderwijs VLAN21" -StartRange "10.2.1.100" -EndRange "10.2.1.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ComputerName "Windowsadserver" -ScopeId "10.2.1.0" -OptionId 3 -Value "10.2.1.1"

# Configuratie voor VLAN30 (10.3.0.0/24 - Putten)
Add-DhcpServerv4Scope -ComputerName "Windowsadserver" -Name "Putten VLAN30" -StartRange "10.3.0.100" -EndRange "10.3.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ComputerName "Windowsadserver" -ScopeId "10.3.0.0" -OptionId 3 -Value "10.3.0.1"

# Configuratie voor VLAN31 (10.3.1.0/24 - Onderwijs)
Add-DhcpServerv4Scope -ComputerName "Windowsadserver" -Name "Onderwijs VLAN31" -StartRange "10.3.1.100" -EndRange "10.3.1.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ComputerName "Windowsadserver" -ScopeId "10.3.1.0" -OptionId 3 -Value "10.3.1.1"

# Herstarten van de DHCP-service
Write-Host "Herstarten van DHCP-service..."
Restart-Service DHCPServer

Write-Host "DHCP-configuratie voltooid."