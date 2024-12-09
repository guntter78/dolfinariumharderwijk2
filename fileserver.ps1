# Install DFS and Management Tools
Install-WindowsFeature FS-DFS-Namespace, FS-DFS-Replication, RSAT-DFS-Mgmt-Con -IncludeManagementTools

# Create a DFS Namespace
$NamespaceRoot = "\\$env:COMPUTERNAME\DFSRoot"
New-DfsnRoot -Path $NamespaceRoot -RootType Standalone -Description "Standard DFS Namespace"

Write-Host "DFS installed and namespace created at $NamespaceRoot."
