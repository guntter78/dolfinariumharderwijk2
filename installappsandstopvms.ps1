# Install App Installer (includes winget)
Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?linkid=2108834 -OutFile AppInstaller.msixbundle
Add-AppxPackage -Path .\AppInstaller.msixbundle

# Install Office and 7zip silently
winget install --id Microsoft.Office -e --silent
winget install --id 7zip.7zip -e --silent

# Define the resource group and VM names
$RESOURCE_GROUP = "Harderwijk-1"
$VM_NAMES = @("werkplekvm1", "werkplekvm2", "werkplekvm3", "werkplekvm4", "werkplekvm5")

# Loop through each VM and stop it
foreach ($VM_NAME in $VM_NAMES) {
    Write-Host "Stopping VM: $VM_NAME"
    az vm stop --resource-group $RESOURCE_GROUP --name $VM_NAME
}
