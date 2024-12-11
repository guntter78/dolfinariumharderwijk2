param (
  [Parameter(Mandatory=$false)]
  [string]$IpAddress,
  [Parameter(Mandatory=$false)]
  [string]$Username,
  [Parameter(Mandatory=$true)]
  [string]$DomainName,
  [Parameter(Mandatory=$true)]
  [string]$Password
)

Set-TimeZone -Id "W. Europe Standard Time"  

Invoke-WebRequest -Uri https://github.com/guntter78/dolfinariumharderwijk2/blob/main/mul_azure_devops_server_express_2022.2_x64_web_installer_4db8d6ad.exe -OutFile C:\AzureDevOpsServer2022.2.exe;
Start-Process -FilePath 'C:\AzureDevOpsServer2022.2.exe' -ArgumentList '/quiet' -Wait;

$interfaces = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null }
Set-DnsClientServerAddress -InterfaceAlias $interfaces.InterfaceAlias -ServerAddresses ($IpAddress,"10.10.2.6")

$DomainUser = $Username + '@' + $DomainName

$Cred = New-Object System.Management.Automation.PSCredential ($DomainUser, (ConvertTo-SecureString $Password -AsPlainText -Force))
Add-Computer -DomainName $DomainName -Credential $Cred

Restart-Computer -Force -Wait
