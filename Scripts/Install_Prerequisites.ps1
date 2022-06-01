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

$azCliCheckPassed               = $false
$azPowerShellCheckPassed        = $false
$azSqlServerModuleCheckPassed   = $false
$dotnetInstallCheckPassed       = $false

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


try {

Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi -ErrorAction Stop

$azCLI = az version | ConvertFrom-Json

if($azCLI -ne $null)
{
Write-Host "Installed Azure CLI with Version:  $($azCLI.'azure-cli')"

WriteLog("Installed Azure CLI with Version:  $($azCLI.'azure-cli')")

$azCliCheckPassed = $true

}
else
{

Write-Host "Azure CLI Installation Failed!"

WriteLog("Azure CLI Installation Failed!")

}

}
catch {

Write-Host "Failed to Download and Install Latest Azure CLI!"

WriteLog("Failed to Download and Install Latest Azure CLI!")

}



# Install Latest Azure Az PowerShell module


try {

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force -ErrorAction Stop 

$azPowerShell = Get-InstalledModule -Name Az

if($azPowerShell -ne $null)
{
Write-Host "Installed Azure PowerShell module with Version: $($azPowerShell).Version"

WriteLog("Installed Azure PowerShell module with Version: $($azPowerShell).Version")

$azPowerShellCheckPassed = $true

}
else
{

Write-Host "Azure PowerShell module Installation Failed!"

WriteLog("Azure PowerShell module Installation Failed!")

}

}
catch {

Write-Host "Failed to Download and Install Latest Azure PowerShell module!"

WriteLog("Failed to Download and Install Latest Azure PowerShell module!")

}



# Set the Security Protocol to Tls1.2

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


# Update the installed version of the SqlServer module

if($DeploymentType -match "HC")
{

try {

Install-Module -Name SqlServer -AllowClobber -Force -ErrorAction Stop

$sqlModule = Get-InstalledModule -Name SqlServer

if($sqlModule -ne $null)
{
Write-Host "Installed SqlServer Module with Version: $($sqlModule).Version"

WriteLog("Installed SqlServer Module with Version: $($sqlModule).Version")

$azSqlServerModuleCheckPassed = $true

}
else
{
Write-Host "SqlServer Module Installation Failed!"

WriteLog("SqlServer Module Installation Failed!")
}

}
catch {

Write-Host "Failed to Download and Install Latest SqlServer Module!"

WriteLog("Failed to Download and Install Latest SqlServer Module!")

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

dotnet-hosting-$($dotnetversion)-win.exe /install /quiet /norestart

}




$grepDotnet = ""

dotnet --info > result.txt

$grepDotnet = Get-Content .\result.txt | Select-String -Pattern "$($dotnetversion)"

if($grepDotnet)
{

Write-Host "dotnet-hosting-$($dotnetversion)-win .NET Core Runtime & Hosting Bundle Installation Successful!"

WriteLog("dotnet-hosting-$($dotnetversion)-win .NET Core Runtime & Hosting Bundle Installation Successful!")

}
else
{

Write-Host "dotnet-hosting-$($dotnetversion)-win .NET Core Runtime & Hosting Bundle Installation Failed!"

WriteLog("dotnet-hosting-$($dotnetversion)-win .NET Core Runtime & Hosting Bundle Installation Failed!")

}

}
