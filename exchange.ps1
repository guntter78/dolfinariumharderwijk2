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
    }
    catch {
        Write-Error "Failed to download the ISO: $_"
        exit
    }
}

# Function to Verify File Size
function Verify-FileSize($filePath, $expectedSizeGB) {
    $actualSize = (Get-Item $filePath).Length
    $actualSizeGB = $actualSize / 1GB
    $lowerBound = $expectedSizeGB * 0.95  # Allow 5% lower than expected
    $upperBound = $expectedSizeGB * 1.05  # Allow 5% higher than expected

    if ($actualSizeGB -lt $lowerBound -or $actualSizeGB -gt $upperBound) {
        Write-Warning "File size mismatch. Expected: $expectedSizeGB GB, Actual: $($actualSizeGB.ToString("F2")) GB"
        return $false
    }
    Write-Host "File size verified successfully. Actual size: $($actualSizeGB.ToString("F2")) GB"
    return $true
}

# Step 1: Download the Exchange Server ISO
if (-not (Test-Path $isoPath)) {
    Download-File -url $exchangeISOUrl -outputPath $isoPath
    $expectedSizeGB = 5.8  # Expected size in GB as per the webpage
    if (-not (Verify-FileSize -filePath $isoPath -expectedSizeGB $expectedSizeGB)) {
        Write-Error "ISO file size verification failed. The download may be corrupt or incomplete."
        exit
    }
}

# Step 2: Mount the ISO
Write-Host "Mounting the Exchange Server ISO..."
$mountResult = Mount-DiskImage -ImagePath $isoPath -PassThru
$driveLetter = ($mountResult | Get-Volume).DriveLetter

if (-not $driveLetter) {
    Write-Error "Failed to mount the ISO. Exiting."
    exit
}
$mountPoint = "${driveLetter}:\"

Write-Host "Mounted ISO at $mountPoint"

# Step 3: Install Prerequisites for Exchange Server
Write-Host "Installing prerequisites for Exchange Server..."
Install-WindowsFeature -Name AD-Domain-Services, Web-Server, RSAT-ADDS -IncludeManagementTools

# Install required roles and features for Exchange Server
Install-WindowsFeature RSAT-Clustering, Web-Mgmt-Console, Web-Asp-Net45, Web-ISAPI-Ext, Web-Dyn-Compression, NET-Framework-45-Features -IncludeAllSubFeature -Restart

# Step 4: Run the Exchange Setup in Unattended Mode
Write-Host "Starting Exchange Server installation..."
Start-Process -FilePath "$mountPoint$setupPath" -ArgumentList "/PrepareSchema /IAcceptExchangeServerLicenseTerms" -Wait
Start-Process -FilePath "$mountPoint$setupPath" -ArgumentList "/PrepareAD /IAcceptExchangeServerLicenseTerms" -Wait
Start-Process -FilePath "$mountPoint$setupPath" -ArgumentList "/mode:Install /roles:Mailbox,ClientAccess /IAcceptExchangeServerLicenseTerms" -Wait

# Step 5: Cleanup and Finish
Write-Host "Exchange Server installation is complete. Unmounting ISO..."
Dismount-DiskImage -ImagePath $isoPath

Write-Host "Exchange Server setup is completed. Verify configuration."
