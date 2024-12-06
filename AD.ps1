# Active Directory Configuratie
        Install-WindowsFeature AD-Domain-Services -IncludeManagementTools;
        Install-ADDSForest -DomainName 'uvh.nl' -DomainNetbiosName 'UVH' -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText 'Dolfinarium!' -Force) -Force;

        # Organizational Units (OU's)
        New-ADOrganizationalUnit -Name 'Students' -Path 'DC=uvh,DC=nl';
        New-ADOrganizationalUnit -Name 'Staff' -Path 'DC=uvh,DC=nl';
        New-ADOrganizationalUnit -Name 'ICT Support' -Path 'DC=uvh,DC=nl';

        # Groepen en Rollen
        New-ADGroup -Name 'Administrators' -GroupScope Global -Path 'OU=ICT Support,DC=uvh,DC=nl';
        New-ADGroup -Name 'Helpdesk' -GroupScope Global -Path 'OU=ICT Support,DC=uvh,DC=nl';
        New-ADGroup -Name 'Students' -GroupScope Global -Path 'OU=Students,DC=uvh,DC=nl';

        # Serviceaccounts
        New-ADUser -Name 'NPE-Account' -AccountPassword (ConvertTo-SecureString 'NPEpassword!' -AsPlainText -Force) -Enabled $true -Path 'OU=ICT Support,DC=uvh,DC=nl';
        New-ADUser -Name 'GuestAccount' -AccountPassword (ConvertTo-SecureString 'Guestpassword!' -AsPlainText -Force) -Enabled $true -Path 'OU=Students,DC=uvh,DC=nl';

        # Administrator Accounts
        New-ADUser -Name 'rudyadmin' -AccountPassword (ConvertTo-SecureString 'Dolfinarium1!' -AsPlainText -Force) -Enabled $true -Path 'OU=ICT Support,DC=uvh,DC=nl';
        Add-ADGroupMember -Identity 'Administrators' -Members 'rudyadmin';

        New-ADUser -Name 'marnixadmin' -AccountPassword (ConvertTo-SecureString 'Dolfinarium1!' -AsPlainText -Force) -Enabled $true -Path 'OU=ICT Support,DC=uvh,DC=nl';
        Add-ADGroupMember -Identity 'Administrators' -Members 'marnixadmin';

        New-ADUser -Name 'allardadmin' -AccountPassword (ConvertTo-SecureString 'Dolfinarium1!' -AsPlainText -Force) -Enabled $true -Path 'OU=ICT Support,DC=uvh,DC=nl';
        Add-ADGroupMember -Identity 'Administrators' -Members 'allardadmin';

        New-ADUser -Name 'wilmeradmin' -AccountPassword (ConvertTo-SecureString 'Dolfinarium1!' -AsPlainText -Force) -Enabled $true -Path 'OU=ICT Support,DC=uvh,DC=nl';
        Add-ADGroupMember -Identity 'Administrators' -Members 'wilmeradmin';

        New-ADUser -Name 'emmaadmin' -AccountPassword (ConvertTo-SecureString 'Dolfinarium1!' -AsPlainText -Force) -Enabled $true -Path 'OU=ICT Support,DC=uvh,DC=nl';
        Add-ADGroupMember -Identity 'Administrators' -Members 'emmaadmin';

        # Logging en Auditing
        AuditPol /Set /Category:"Account Logon" /Success:Enable /Failure:Enable;
        AuditPol /Set /Category:"Directory Service Access" /Success:Enable /Failure:Enable;
        
        # DHCP Configuratie
        Install-WindowsFeature DHCP -IncludeManagementTools;
        Add-DhcpServerv4Scope -Name 'DefaultScope' -StartRange '192.168.1.100' -EndRange '192.168.1.200' -SubnetMask '255.255.255.0';
        Set-DhcpServerv4OptionValue -OptionId 3 -Value '192.168.1.1';
        Restart-Service DHCPServer;

        # IIS Configuratie
        Install-WindowsFeature -Name Web-Server -IncludeManagementTools;
        $htmlContent = @"
        <!DOCTYPE html>
        <html>
          <head>
            <title>Welkom op IIS</title>
          </head>
          <body>
            <h1>Hallo, welkom op de webserver!</h1>
            <p>Deze webpagina is automatisch aangemaakt via Bicep!</p>
          </body>
        </html>
        "@;
        $path = 'C:\inetpub\wwwroot\index.html';
        $htmlContent | Out-File -FilePath $path -Encoding utf8;
        Restart-Service W3SVC;
