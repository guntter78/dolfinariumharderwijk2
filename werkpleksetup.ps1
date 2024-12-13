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

Invoke-WebRequest -Uri "https://github.com/guntter78/dolfinariumharderwijk2/raw/refs/heads/main/setup.exe" -OutFile "$env:TEMP\setup.exe"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/guntter78/dolfinariumharderwijk2/refs/heads/main/Configuratie.xml" -OutFile "$env:TEMP\Configuratie.xml"

cd $env:TEMP

.\setup.exe /download .\Configuration.xml
.\setup.exe /configure .\Configuration.xml



$dlurl = 'https://7-zip.org/' + (Invoke-WebRequest -UseBasicParsing -Uri 'https://7-zip.org/' | Select-Object -ExpandProperty Links | Where-Object {($_.outerHTML -match 'Download')-and ($_.href -like "a/*") -and ($_.href -like "*-x64.exe")} | Select-Object -First 1 | Select-Object -ExpandProperty href)
# modified to work without IE
# above code from: https://perplexity.nl/windows-powershell/installing-or-updating-7-zip-using-powershell/
$installerPath = Join-Path $env:TEMP (Split-Path $dlurl -Leaf)
Invoke-WebRequest $dlurl -OutFile $installerPath
Start-Process -FilePath $installerPath -Args "/S" -Verb RunAs -Wait
Remove-Item $installerPath


$interfaces = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses -ne $null }
Set-DnsClientServerAddress -InterfaceAlias $interfaces.InterfaceAlias -ServerAddresses ($IpAddress,"10.10.2.6")

$DomainUser = $Username + '@' + $DomainName

$Cred = New-Object System.Management.Automation.PSCredential ($DomainUser, (ConvertTo-SecureString $Password -AsPlainText -Force))
Add-Computer -DomainName $DomainName -Credential $Cred
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "Everyone"

Restart-Computer -Force
