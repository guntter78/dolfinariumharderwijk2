Install-WindowsFeature -Name FS-DFS-Namespace -IncludeManagementTools

New-DfsnRoot -Path "\\uvh.nl\DFS" -TargetPath "C:\DFSRoots\DFS"
