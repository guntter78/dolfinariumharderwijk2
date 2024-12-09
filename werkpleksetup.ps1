# param (
#   [Parameter(Mandatory=$false)]
#   [string]$IpAddress,
#   [Parameter(Mandatory=$false)]
#   [string]$Username,https://github.com/guntter78/dolfinariumharderwijk2/blob/main/werkpleksetup.ps1
#   [Parameter(Mandatory=$true)]
#   [string]$DomainName,
#   [Parameter(Mandatory=$true)]
#   [string]$Password
# )

# Set-TimeZone -Id "W. Europe Standard Time"  

powershell -ExecutionPolicy bypass -File 7ZipSetup.ps1
# powershell -ExecutionPolicy bypass -File joinAD2.ps1 -IpAddress $IpAddress -Username $Username -DomainName $DomainName -Password $Password
