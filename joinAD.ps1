        # Install required Windows features
        Install-WindowsFeature -Name AD-Domain-Services, RSAT-AD-PowerShell -IncludeManagementTools;

        # Set domain join variables
        $DomainUser = '${domainUser}';
        $DomainPassword = '${domainPassword}';

        $Credential = New-Object System.Management.Automation.PSCredential ($DomainUser, (ConvertTo-SecureString -String $DomainPassword -AsPlainText -Force));

        # Join the server to the domain
        Add-Computer -DomainName ${domainName} -Credential $Credential -Force -Restart;

        # After restart, install applications
        Start-Sleep -Seconds 120; # Wait for server to restart
        Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?linkid=2108834 -OutFile AppInstaller.msixbundle;
        Add-AppxPackage -Path .\\AppInstaller.msixbundle;

        # Install applications with winget
        winget install --id exchange -e --silent;
        winget install --id Splunk.UniversalForwarder -e --silent;
