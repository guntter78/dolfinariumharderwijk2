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

# Download the setup file
Invoke-WebRequest -Uri "https://c2rsetup.officeapps.live.com/c2r/download.aspx?productReleaseID=O365HomePremRetail&platform=X86&language=en-US&TaxRegion=pr&correlationId=7e21dd05-491e-4160-9092-2def0c1f1548&token=03ec93e1-7670-4b54-ae66-c70b47d595b2&version=O15GA&source=O15OLSOMEX" -OutFile "$env:TEMP\Setup.exe"

# Change directory to TEMP and run the setup
cd $env:TEMP
.\Setup.exe


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
