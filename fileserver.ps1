# Install DFS and Management Tools
Install-WindowsFeature FS-DFS-Namespace, FS-DFS-Replication, RSAT-DFS-Mgmt-Con -IncludeManagementTools

# Create a folder for the DFS Namespace if it doesn't exist
$TargetPath = "C:\DFSRoot"
if (-not (Test-Path -Path $TargetPath)) {
    New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
}

# Create a DFS Namespace (Standalone)
$NamespaceRoot = "\\$env:COMPUTERNAME\DFSRoot"
New-DfsnRoot -Path $NamespaceRoot -TargetPath $TargetPath -Description "Standard DFS Namespace"

Write-Host "DFS installed and namespace created at $NamespaceRoot with backing folder $TargetPath."
