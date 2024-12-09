# Installeer DFS en Management Tools
Install-WindowsFeature -Name FS-DFS-Namespace, FS-DFS-Replication, RSAT-DFS-Mgmt-Con -IncludeManagementTools

# Variabelen definiëren
$NamespacePath = "\\uvh.nl\DFS"       # DFS Namespace
$TargetPaths = @("\\Server1\Share1", "\\Server2\Share2") # Namespace targets (update as needed)
$ReplicationGroupName = "ReplicationGroup1" # Name of the replication group
$PrimaryMember = "\\Server1\Share1"         # Primary member (optional, first server by default)
$Servers = @("Server1", "Server2")          # List of servers for replication

# Maak een DFS-namespace
New-DfsnRoot -Path $NamespacePath -TargetPath $TargetPaths -Description "Standard DFS Namespace"

# Configureer DFS-replicatie
New-DfsReplicationGroup -GroupName $ReplicationGroupName

# Voeg leden toe aan de replicatiegroep
foreach ($Server in $Servers) {
    Add-DfsrMember -GroupName $ReplicationGroupName -ComputerName $Server
}

# Voeg een replicatiefolder toe aan de replicatiegroep
New-DfsrReplicationFolder -GroupName $ReplicationGroupName -FolderName "SharedFolder"

# Koppel de replicatiefolder aan paden op de servers
foreach ($TargetPath in $TargetPaths) {
    $ServerName = ($TargetPath -split "\\")[2] # Extract server name from the path
    Set-DfsrMemberFolder -GroupName $ReplicationGroupName -FolderName "SharedFolder" -ContentPath $TargetPath -ComputerName $ServerName
}

# Configureer replicatie tussen leden
for ($i = 0; $i -lt $Servers.Count - 1; $i++) {
    for ($j = $i + 1; $j -lt $Servers.Count; $j++) {
        New-DfsrConnection -GroupName $ReplicationGroupName -SourceComputerName $Servers[$i] -DestinationComputerName $Servers[$j] -Schedule Always
    }
}

Write-Host "DFS Namespace en replicatie geconfigureerd."
