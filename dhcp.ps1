Write-Host "Installeren van DHCP-serverrol..."
Install-WindowsFeature DHCP -IncludeManagementTools

Write-Host "Configureren van DHCP-scope..."
Add-DhcpServerv4Scope -Name "DefaultScope" -StartRange "192.168.1.100" -EndRange "192.168.1.200" -SubnetMask "255.255.255.0"

Write-Host "Instellen van standaard gateway-optie..."
Set-DhcpServerv4OptionValue -OptionId 3 -Value "192.168.1.1"

Write-Host "Herstarten van DHCP-service..."
Restart-Service DHCPServer

Write-Host "DHCP-configuratie voltooid."
