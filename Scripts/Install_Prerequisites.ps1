[CmdletBinding()]
param (
  [parameter(Mandatory=$True,
  HelpMessage="List of dotnet framework names separated by commas.")]
  [string]$dotnetRuntimes,
  [parameter(Mandatory=$True,
  HelpMessage="Deployment Type either HC or HWS")]
  [string]$deploymentType
)

$dotnets = $dotnetruntimes.Split(",")

$logFolderName = "Logs"

$logFolderPath = "C:\" + $logFolderName

$logFileName = "Prerequisites_Check" + "_" + $(get-date -f yyyy-MM-dd_HH-mm-ss) + ".txt"

$logFilePath  = $logFolderPath + "\" +  $logFileName

$azCLIPresent = $false
$azPSPresent = $false
$sqlModulePresent = $false


Function WriteLog
{
   Param ([string]$logstring)

   write-host ($logstring)
   Add-content $LogFilePath -value $logstring -Force
}


if(-not (Test-Path -Path $logFolderPath))
{

New-Item -Path C:\ -Name $logFolderName -ItemType Directory -Force

New-Item -Path $logFolderPath -Name $logFileName -ItemType File -Force 

if(Test-Path -Path $logFilePath)
{

Write-Host "$($logFilePath) - Log file created successfully!"

WriteLog("$($logFilePath) - Log file created successfully!")

}
else
{

Write-Host "Log file creation failed!"

WriteLog("Log file creation failed!")

}

}
else
{
Write-Host "C:\Logs directory already exists!"
}


# Install Latest Azure CLI 

try 
{
$checkAzCli = az version


Write-Host "Found Azure CLI Installed with Version:  $($azCLI.'azure-cli')"

WriteLog("Found Azure CLI Installed with Version:  $($azCLI.'azure-cli')")

$azCLIPresent = $true

}
catch {

Write-Host "Azure CLI is not installed on $($env:COMPUTERNAME)"

WriteLog("Azure CLI is not installed on $($env:COMPUTERNAME)")

}

try {

Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi -ErrorAction Stop

}
catch {

Write-Host "Failed to Download and Install Latest Azure CLI!"

WriteLog("Failed to Download and Install Latest Azure CLI!")

}

$azCLI = az version | ConvertFrom-Json

if($azCLI -ne $null)
{

if($azCLIPresent -eq $True)
{

Write-Host "Updated Azure CLI with Version:  $($azCLI.'azure-cli')"

WriteLog("Updated Azure CLI with Version:  $($azCLI.'azure-cli')")

}
else
{
Write-Host "Installed Azure CLI with Version:  $($azCLI.'azure-cli')"

WriteLog("Installed Azure CLI with Version:  $($azCLI.'azure-cli')")
}

}
else
{

Write-Host "Azure CLI Installation Failed! on $($env:COMPUTERNAME)"

WriteLog("Azure CLI Installation Failed! on $($env:COMPUTERNAME)")

}



# Install Latest Azure Az PowerShell module

try 
{
$checkAzPowerShell = Get-InstalledModule -Name Az

Write-Host "Found Azure PowerShell module Installed with Version:  $($azCLI.'azure-cli')"

WriteLog("Found Azure PowerShell module Installed with Version:  $($azCLI.'azure-cli')")

$azPSPresent = $true

}
catch {

Write-Host "Azure Az PowerShell module is not installed on $($env:COMPUTERNAME)!"

WriteLog("Azure Az PowerShell module is not installed on $($env:COMPUTERNAME)!")

}

try {

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -ErrorAction Stop 

}
catch {

Write-Host "Failed to Download and Install Latest Azure PowerShell module!"

WriteLog("Failed to Download and Install Latest Azure PowerShell module!")

}

$azPowerShell = Get-InstalledModule -Name Az

if($azPowerShell -ne $null)
{

if($azPSPresent -eq $true)
{
Write-Host "Updated Azure PowerShell module with Version: $($azPowerShell).Version"

WriteLog("Updated Azure PowerShell module with Version: $($azPowerShell).Version")
}
else
{
Write-Host "Installed Azure PowerShell module with Version: $($azPowerShell).Version"

WriteLog("Installed Azure PowerShell module with Version: $($azPowerShell).Version")
}

}
else
{

Write-Host "Azure PowerShell module Installation Failed!"

WriteLog("Azure PowerShell module Installation Failed!")

}


# Set the Security Protocol to Tls1.2

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


# Update the installed version of the SqlServer module

if($DeploymentType -match "HC")
{

try 
{
$checksqlModule = Get-InstalledModule -Name SqlServer

Write-Host "Found SqlServer Module installed with Version: $($sqlModule).Version"

WriteLog("Found SqlServer Module installed with Version: $($sqlModule).Version")

$sqlModulePresent = $true

}
catch {

Write-Host "SqlServer Module is not installed on $($env:COMPUTERNAME)"

WriteLog("SqlServer Module is not installed on $($env:COMPUTERNAME)")

}


try {

Install-Module -Name SqlServer -AllowClobber -Force -ErrorAction Stop 

}
catch {

Write-Host "Failed to Download and Install Latest SqlServer Module"

WriteLog("Failed to Download and Install Latest SqlServer Module")

}

$sqlModule = Get-InstalledModule -Name SqlServer

if($sqlModule -ne $null)
{

if($sqlModulePresent -eq $true)
{
Write-Host "Updated SqlServer Module with Version: $($sqlModule).Version"

WriteLog("Updated SqlServer Module with Version: $($sqlModule).Version")
}
else
{
Write-Host "Installed SqlServer Module with Version: $($sqlModule).Version"

WriteLog("Installed SqlServer Module with Version: $($sqlModule).Version")
}

}
else
{
Write-Host "SqlServer Module Installation Failed!"

WriteLog("SqlServer Module Installation Failed!")
}

}

# Check Whether IIS Role is present on server or not

Set-ExecutionPolicy Bypass -Scope Process

$IISOptionalFeatures = @('IIS-WebServerRole', 
                        'IIS-WebServer', 
                        'IIS-CommonHttpFeatures', 
                        'IIS-Security', 
                        'IIS-RequestFiltering', 
                        'IIS-StaticContent', 
                        'IIS-DefaultDocument', 
                        'IIS-DirectoryBrowsing', 
                        'IIS-HttpErrors', 
                        'IIS-HttpRedirect', 
                        'IIS-HttpRedirect',
                        'IIS-ApplicationDevelopment', 
                        'IIS-WebSockets', 
                        'IIS-NetFxExtensibility', 
                        'IIS-NetFxExtensibility45', 
                        'IIS-ISAPIExtensions', 
                        'IIS-ISAPIFilter', 
                        'IIS-ASPNET45', 
                        'IIS-CGI', 
                        'IIS-HealthAndDiagnostics', 
                        'IIS-HttpLogging', 
                        'IIS-LoggingLibraries', 
                        'IIS-RequestMonitor', 
                        'IIS-HttpTracing', 
                        'IIS-BasicAuthentication', 
                        'IIS-WindowsAuthentication', 
                        'IIS-ClientCertificateMappingAuthentication', 
                        'IIS-Performance', 
                        'IIS-HttpCompressionStatic', 
                        'IIS-HttpCompressionDynamic', 
                        'IIS-WebServerManagementTools', 
                        'IIS-ManagementConsole', 
                        'IIS-LegacySnapIn', 
                        'IIS-ManagementScriptingTools', 
                        'IIS-IIS6ManagementCompatibility', 
                        'IIS-Metabase', 
                        'IIS-WMICompatibility', 
                        'IIS-LegacyScripts')


if ((Get-WindowsFeature Web-Server).InstallState -match "Installed") {

    Write-Host "IIS is installed on $($env:COMPUTERNAME)"

    WriteLog("IIS is installed on $($env:COMPUTERNAME)")

    foreach($IISOptionalFeature in $IISOptionalFeatures)
    {

    if((Get-WindowsOptionalFeature -Online -FeatureName "$($IISOptionalFeature)").State -notmatch "Enabled")
    {

    try {

    Enable-WindowsOptionalFeature -Online -FeatureName "$($IISOptionalFeature)" -ErrorAction Stop

    Write-Host "$($IISOptionalFeature) Enabled Successfully!"

    WriteLog("$($IISOptionalFeature) Enabled Successfully!")

    }
    catch {

    Write-Host "Failed to enable $($IISOptionalFeature) feature!"

    WriteLog("Failed to enable $($IISOptionalFeature) feature!")

    }

    }
    else
    {
    Write-Host "$($IISOptionalFeature) feature already enabled!"
    WriteLog("$($IISOptionalFeature) feature already enabled!")

    } 

    }


} 
else {
    

    Write-Host "IIS is not installed on $($env:COMPUTERNAME)"

    WriteLog("IIS is not installed on $($env:COMPUTERNAME)")

    try {

    Install-WindowsFeature -Name Web-Http-Redirect, Web-Log-Libraries, Web-Request-Monitor, Web-Http-Tracing, Web-Dyn-Compression, Web-Basic-Auth, Web-Client-Auth, Web-Windows-Auth, Web-Net-Ext, Web-Net-Ext45, Web-Asp-Net45, Web-CGI, Web-ISAPI-Ext, Web-ISAPI-Filter, Web-WebSockets, Web-Mgmt-Tools, Web-Mgmt-Compat, Web-Metabase, Web-Lgcy-Scripting, Web-WMI, Web-Scripting-Tools -IncludeManagementTools -ErrorAction Stop

    if((Get-WindowsFeature Web-Server).InstallState -match "Installed") 
    {
    Write-Host "Web Server Role Installation Successful!"
    WriteLog("Web Server Role Installation Successful!")

    foreach($IISOptionalFeature in $IISOptionalFeatures)
    {

    if((Get-WindowsOptionalFeature -Online -FeatureName "$($IISOptionalFeature)").State -notmatch "Enabled")
    {

    try {

    Enable-WindowsOptionalFeature -Online -FeatureName "$($IISOptionalFeature)" -ErrorAction Stop

    Write-Host "$($IISOptionalFeature) Enabled Successfully!"

    WriteLog("$($IISOptionalFeature) Enabled Successfully!")

    }
    catch {

    Write-Host "Failed to enable $($IISOptionalFeature) feature!"

    WriteLog("Failed to enable $($IISOptionalFeature) feature!")

    }

    }
    else
    {

    Write-Host "$($IISOptionalFeature) feature already enabled!"

    WriteLog("$($IISOptionalFeature) feature already enabled!")

    } 

    }

    }
    else
    {
    Write-Host "Web Server Role Installation Failed!"
    WriteLog("Web Server Role Installation Failed!")
    }

    }
    catch {

    Write-Host "Web Server Role Installation Failed!"

    WriteLog("Web Server Role Installation Failed!")

    }


}

# Check HTTPS Binding in IIS

$CheckHttpsBinding = Get-IISSiteBinding "Default Web Site" -Protocol https

if($CheckHttpsBinding -and $CheckHttpsBinding.BindingInformation -eq "*:443:")
{
Write-Host "https binding in IIS is already added!" 

WriteLog("https binding in IIS is already added!")
}
else
{
cls
Write-Host "Warning - https binding is not configured in IIS!” 

WriteLog("Warning - https binding is not configured in IIS!”)
}

# Download and Install .NET Core Runtime & Hosting Bundle

foreach($dotnet in $dotnets)
{

Write-Host ".Net Filename: $($dotnet)" 

$String = $dotnet 
$Regex = [Regex]::new("(?<=hosting-)(.*)(?=-win)")           
$Match = $Regex.Match($String)           
if($Match.Success)           
{           
    $dotnetversion = $Match.Value           
}

$dotnetfileHash = (Invoke-WebRequest -Uri https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-aspnetcore-$($dotnetversion)-windows-hosting-bundle-installer -Method Get -ContentType 'application/json' -UseBasicParsing).InputFields.value

$WebResponseObj = (Invoke-WebRequest -Uri https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-aspnetcore-$($dotnetversion)-windows-hosting-bundle-installer -Method Get -ContentType 'application/json' -UseBasicParsing)

$String = $WebResponseObj.RawContent           
$Regex = [Regex]::new("(?<=download/pr/)(.*)(?=/dotnet-)")           
$Match = $Regex.Match($String)           
if($Match.Success)           
{           
    $dotnet_download_path  = $Match.Value           
}


try {

Invoke-WebRequest -Uri https://download.visualstudio.microsoft.com/download/pr/$($dotnet_download_path)/dotnet-hosting-$($dotnetversion)-win.exe -OutFile dotnet-hosting-$($dotnetversion)-win.exe -ErrorAction Stop

}
catch {

Write-Host "Failed to download dotnet-hosting-$($dotnetversion)-win.exe!" 

WriteLog("Failed to download dotnet-hosting-$($dotnetversion)-win.exe!")

}

# Validate the hash
if((Get-FileHash -Path dotnet-hosting-$($dotnetversion)-win.exe -Algorithm SHA512).Hash.ToUpper() -ne $($dotnetfileHash).ToUpper()) 
{ 

Write-Host "Computed checksum did not match - dotnet-hosting-$($dotnetversion)-win.exe"

WriteLog("Computed checksum did not match - dotnet-hosting-$($dotnetversion)-win.exe")

Write-Host "Error encounter during download the file or file not downloaded completely!"

WriteLog("Error encounter during download the file or file not downloaded completely!")

}
else
{

Write-Host "dotnet-hosting-$($dotnetversion)-win.exe downloaded successfully!"

WriteLog("dotnet-hosting-$($dotnetversion)-win.exe downloaded successfully!")


$dotnetexe = Get-ChildItem | Where-Object { $_.Name -like "*.exe" }

Start-Process -FilePath $dotnetexe.FullName -ArgumentList "/install /quiet /norestart" -Wait -NoNewWindow -PassThru

}

if(Test-Path -Path C:\Program Files\dotnet\shared\Microsoft.NETCore.App\$($dotnetversion))
{

Write-Host "dotnet-hosting-$($dotnetversion)-win installed successfully!"

WriteLog("dotnet-hosting-$($dotnetversion)-win installed successfully!")

}
else
{

Write-Host "Failed to install dotnet-hosting-$($dotnetversion)-win!"
WriteLog("Failed to install dotnet-hosting-$($dotnetversion)-win!")

}
Remove-Item -Path $dotnetexe.FullName -Force
}
