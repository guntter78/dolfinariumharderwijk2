Invoke-WebRequest -Uri "https://github.com/guntter78/dolfinariumharderwijk2/raw/refs/heads/main/setup.exe" -OutFile "$env:TEMP\setup.exe"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/guntter78/dolfinariumharderwijk2/refs/heads/main/Configuratie.xml" -OutFile "$env:TEMP\Configuratie.xml"

cd $env:TEMP

.\setup.exe /download .\Configuration.xml
.\setup.exe /configure .\Configuration.xml
