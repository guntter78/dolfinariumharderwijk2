        # Download and install App Installer (includes winget)
        Invoke-WebRequest -Uri https://go.microsoft.com/fwlink/?linkid=2108834 -OutFile AppInstaller.msixbundle;
        Add-AppxPackage -Path .\\AppInstaller.msixbundle;
        winget install --id exchange -e --silent;
        winget install --id Splunk.UniversalForwarder -e --silent
