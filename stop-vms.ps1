# Define the resource group and VM names
$RESOURCE_GROUP = "Harderwijk-1"
$VM_NAMES = @("werkplekvm1", "werkplekvm2", "werkplekvm3", "werkplekvm4", "werkplekvm5")

# Loop through each VM and stop it
foreach ($VM_NAME in $VM_NAMES) {
    Write-Host "Stopping VM: $VM_NAME"
    az vm stop --resource-group $RESOURCE_GROUP --name $VM_NAME
}
