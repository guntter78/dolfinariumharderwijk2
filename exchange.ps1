        # Download and install App Installer (includes winget)
        Invoke-WebRequest -Uri https://download.microsoft.com/download/b/c/7/bc766694-8398-4258-8e1e-ce4ddb9b3f7d/ExchangeServer2019-x64-CU12.ISO -OutFile AppInstaller.msixbundle;
        Add-AppxPackage -Path .\\AppInstaller.msixbundle;
        winget install --id exchange -e --silent;
        winget install --id Splunk.UniversalForwarder -e --silent
