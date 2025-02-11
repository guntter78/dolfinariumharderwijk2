# Installeren van de DHCP-serverrol
Write-Host "Installeren van DHCP-serverrol..."
Install-WindowsFeature DHCP -IncludeManagementTools

Write-Host "Configureren van DHCP-scopes..."

# VLAN 10 - Beheer (Subnet: 10.0.0.0/24)
Add-DhcpServerv4Scope -Name "Beheer" -StartRange "10.0.0.100" -EndRange "10.0.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.0.0.0" -OptionId 3 -Value "10.0.0.1"

# VLAN 11 - Harderwijk Staf (Subnet: 10.1.0.0/24)
Add-DhcpServerv4Scope -Name "Harderwijk Staf" -StartRange "10.1.0.100" -EndRange "10.1.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.1.0.0" -OptionId 3 -Value "10.1.0.1"
Set-DhcpServerv4OptionValue -ScopeId "10.1.0.0" -OptionId 6 -Value "10.10.2.6"

# VLAN 12 - Harderwijk Onderwijs (Subnet: 10.1.2.0/24)
Add-DhcpServerv4Scope -Name "Harderwijk Onderwijs" -StartRange "10.1.2.100" -EndRange "10.1.2.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.1.2.0" -OptionId 3 -Value "10.1.2.1"

# VLAN 13 - Datacentrum (Subnet: 10.0.128.0/22)
Add-DhcpServerv4Scope -Name "Datacentrum" -StartRange "10.0.128.100" -EndRange "10.0.131.200" -SubnetMask "255.255.252.0"
Set-DhcpServerv4OptionValue -ScopeId "10.0.128.0" -OptionId 3 -Value "10.0.128.1"

# VLAN 14 - Int ISP (Subnet: 10.1.3.0/24)
Add-DhcpServerv4Scope -Name "Int ISP" -StartRange "10.1.3.100" -EndRange "10.1.3.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.1.3.0" -OptionId 3 -Value "10.1.3.1"

# VLAN 20 - Nunspeet (Subnet: 10.2.0.0/24)
Add-DhcpServerv4Scope -Name "Nunspeet VLAN20" -StartRange "10.2.0.100" -EndRange "10.2.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.2.0.0" -OptionId 3 -Value "10.2.0.1"

# VLAN 21 - Onderwijs (Subnet: 10.2.1.0/24)
Add-DhcpServerv4Scope -Name "Onderwijs VLAN21" -StartRange "10.2.1.100" -EndRange "10.2.1.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.2.1.0" -OptionId 3 -Value "10.2.1.1"

# VLAN 30 - Putten (Subnet: 10.3.0.0/24)
Add-DhcpServerv4Scope -Name "Putten VLAN30" -StartRange "10.3.0.100" -EndRange "10.3.0.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.3.0.0" -OptionId 3 -Value "10.3.0.1"

# VLAN 31 - Onderwijs (Subnet: 10.3.1.0/24)
Add-DhcpServerv4Scope -Name "Onderwijs VLAN31" -StartRange "10.3.1.100" -EndRange "10.3.1.200" -SubnetMask "255.255.255.0"
Set-DhcpServerv4OptionValue -ScopeId "10.3.1.0" -OptionId 3 -Value "10.3.1.1"

# Toevoegen van DNS-servers aan alle scopes
$dnsServers = "10.24.102.106", "10.10.2.11", "10.10.2.6"
$scopes = Get-DhcpServerv4Scope
foreach ($scope in $scopes) {
    Set-DhcpServerv4OptionValue -ScopeId $scope.ScopeId -OptionId 6 -Value $dnsServers
    Write-Host "DNS servers added to scope: $($scope.ScopeId)"
}

# Herstarten van de DHCP-service
Write-Host "Herstarten van DHCP-service..."
Restart-Service DHCPServer

Write-Host "DHCP-configuratie voltooid."
