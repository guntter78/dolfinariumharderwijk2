# Ensure the script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script as an Administrator."
    exit
}

# Variables
$exchangeISOUrl = "https://download.microsoft.com/download/b/c/7/bc766694-8398-4258-8e1e-ce4ddb9b3f7d/ExchangeServer2019-x64-CU12.ISO"
$isoPath = "$env:TEMP\ExchangeServer2019-x64-CU12.ISO"
$setupPath = "Setup.exe"

# Function to Download File
function Download-File($url, $outputPath) {
    Write-Host "Downloading file from: $url"
    try {
        Start-BitsTransfer -Source $url -Destination $outputPath -DisplayName "File Download" -Priority High
        Write-Host "Downloaded file to: $outputPath"
    } catch {
        Write-Error "Failed to download the file: $_"
        exit
    }
}

# Step 1: Download and Install Prerequisites
Write-Host "Downloading and installing prerequisites..."

# Microsoft Unified Communications Managed API 4.0
$ucmaUrl = "https://download.microsoft.com/download/2/C/4/2C47A5C1-A1F3-4843-B9FE-84C0032C61EC/UcmaRuntimeSetup.exe"
$ucmaPath = "$env:TEMP\UcmaRuntimeSetup.exe"
Download-File -url $ucmaUrl -outputPath $ucmaPath
Start-Process -FilePath $ucmaPath -ArgumentList "/passive /norestart" -Wait

# Visual C++ 2013 Redistributable Package
$vcRedistUrl = "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
$vcRedistPath = "$env:TEMP\vcredist_x64.exe"
Download-File -url $vcRedistUrl -outputPath $vcRedistPath
Start-Process -FilePath $vcRedistPath -ArgumentList "/install /quiet /norestart" -Wait

# IIS URL Rewrite Module
$urlRewriteUrl = "https://download.microsoft.com/download/1/2/8/128E2E22-C1B9-44A4-BE2A-5859ED1D4592/rewrite_amd64_en-US.msi"
$urlRewritePath = "$env:TEMP\rewrite_amd64_en-US.msi"
Download-File -url $urlRewriteUrl -outputPath $urlRewritePath
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$urlRewritePath`" /qn" -Wait

# Step 2: Install Windows Features
Write-Host "Installing Windows Features..."
Install-WindowsFeature -Name AD-Domain-Services, Web-Server, RSAT-ADDS, RSAT-Clustering, Web-Mgmt-Console, Web-Asp-Net45, Web-ISAPI-Ext, Web-Dyn-Compression, NET-Framework-45-Features -IncludeAllSubFeature -Restart

# Step 3: Download the Exchange Server ISO
if (-not (Test-Path $isoPath)) {
    Download-File -url $exchangeISOUrl -outputPath $isoPath
}

# Step 4: Mount the ISO
Write-Host "Mounting the Exchange Server ISO..."
try {
    $mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
    $driveLetter = ($mountResult | Get-Volume).DriveLetter
    if (-not $driveLetter) { throw "Failed to mount the ISO." }
    $mountPoint = "${driveLetter}:\"
    Write-Host "Mounted ISO at $mountPoint"
} catch {
    Write-Error "Failed to mount ISO: $_"
    exit
}

# Step 5: Run the Exchange Setup in Unattended Mode
Write-Host "Starting Exchange Server installation..."
try {
    # Prepare Schema and AD first
    Start-Process -FilePath "$mountPoint$setupPath" -ArgumentList "/PrepareSchema /IAcceptExchangeServerLicenseTerms" -Wait -NoNewWindow
    Start-Process -FilePath "$mountPoint$setupPath" -ArgumentList "/PrepareAD /IAcceptExchangeServerLicenseTerms" -Wait -NoNewWindow

    # Run the unattended installation
    $unattendedArgs = "/Mode:Install /InstallWindowsComponents /IAcceptExchangeServerLicenseTerms /Roles:MB"
    Start-Process -FilePath "$mountPoint$setupPath" -ArgumentList $unattendedArgs -Wait -NoNewWindow
} catch {
    Write-Error "Exchange installation failed: $_"
    exit
}

# Step 6: Retain ISO and Notify
Write-Host "Exchange Server installation process is complete."
Write-Host "The ISO has been retained for future use at: $isoPath"

Write-Host "Exchange Server setup is completed. Please verify the configuration manually."
