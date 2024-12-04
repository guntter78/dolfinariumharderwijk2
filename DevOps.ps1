Invoke-WebRequest -Uri https://raw.githubusercontent.com/guntter78/dolfinariumharderwijk2/main/mul_azure_devops_server_express_2022.2_x64_web_installer_4db8d6ad.exe -OutFile C:\AzureDevOpsServer2022.2.exe;
Start-Process -FilePath 'C:\AzureDevOpsServer2022.2.exe' -ArgumentList '/quiet' -Wait;
