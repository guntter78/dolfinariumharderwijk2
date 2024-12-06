Write-Host "Installeren van IIS..."
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

Write-Host "Aanmaken van een standaard webpagina..."
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Welkom op IIS</title>
</head>
<body>
    <h1>Hallo, welkom op de webserver!</h1>
    <p>Deze webpagina is automatisch aangemaakt.</p>
</body>
</html>
"@
$path = "C:\inetpub\wwwroot\index.html"
$htmlContent | Out-File -FilePath $path -Encoding utf8

Write-Host "Herstarten van IIS-service..."
Restart-Service W3SVC

Write-Host "IIS-configuratie voltooid."
