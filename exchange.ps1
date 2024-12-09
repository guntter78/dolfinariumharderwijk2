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
    Write-Host "Downloading Exchange ISO from: $url"
    try {
        Start-BitsTransfer -Source $url -Destination $outputPath -DisplayName "Exchange ISO Download" -Priority High
        Write-Host "Downloaded ISO to: $outputPath"
    } catch {
        Write-Error "Failed to download the ISO: $_"
        exit
    }
}

# Step 1: Download the Exchange Server ISO
if (-not (Test-Path $isoPath)) {
    Download-File -url $exchangeISOUrl -outputPath $isoPath
    # Remove: if (-not (Verify-FileSize -filePath $isoPath -expectedSizeGB $expectedSizeGB)) {
    #     Write-Error "ISO file size verification failed. The download may be corrupt or incomplete."
    #     exit
    # }
}

# Step 2: Mount the ISO
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

# Step 3: Install Prerequisites for Exchange Server
Write-Host "Installing prerequisites for Exchange Server..."
try {
    Install-WindowsFeature -Name AD-Domain-Services, Web-Server, RSAT-ADDS -IncludeManagementTools
    Install-WindowsFeature RSAT-Clustering, Web-Mgmt-Console, Web-Asp-Net45, Web-ISAPI-Ext, Web-Dyn-Compression, NET-Framework-45-Features -IncludeAllSubFeature -Restart
} catch {
    Write-Error "Failed to install prerequisites: $_"
    exit
}

# Step 4: Run the Exchange Setup in Unattended Mode
Write-Host "Starting Exchange Server installation..."
try {
    Start-Process -FilePath "$mountPoint$setupPath" -ArgumentList "/PrepareSchema /IAcceptExchangeServerLicenseTerms_DiagnosticDataON" -Wait -NoNewWindow
    Start-Process -FilePath "$mountPoint$setupPath" -ArgumentList "/PrepareAD /IAcceptExchangeServerLicenseTerms_DiagnosticDataON" -Wait -NoNewWindow
    Start-Process -FilePath "$mountPoint$setupPath" -ArgumentList "/mode:Install /roles:Mailbox,ClientAccess /IAcceptExchangeServerLicenseTerms_DiagnosticDataON" -Wait -NoNewWindow
} catch {
    Write-Error "Exchange installation failed: $_"
    exit
}

# Step 5: Retain ISO and Notify
Write-Host "Exchange Server installation process is complete."
Write-Host "The ISO has been retained for future use at: $isoPath"

Write-Host "Exchange Server setup is completed. Please verify the configuration manually."
