function CreateLogDirectory # This function Creates Logs Directory on C:\
{

Param ([string]$logFolderPath
       )

if(-not (Test-Path -Path $logFolderPath))
{

try {
New-Item -Path $logFolderPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
#Write-Log -Message "$($logFolderPath) directory created successfully!" -Severity Information
Write-Host "$($logFolderPath) directory created successfully!"
}
catch {
#Write-Log -Message "Failed to create $($logFolderPath) directory!" -Severity Error
Write-Host "Failed to create $($logFolderPath) directory!"
}

}

}

function CreateLogFilesFor_PreValidation # This function Creates Log Files required for Pre-Check inside C:\Logs Directory
{

Param ([string]$logFolderPath
       )

if((Test-Path -Path $logFolderPath))
{

$logFileName = "Pre_Validation_Log" + "_" + $(get-date -f yyyy-MM-dd_HH-mm-ss) + ".csv"

$Global:logFilePath  = $logFolderPath + "\" +  $logFileName

New-Item -Path $logFolderPath -Name $logFileName -ItemType File -Force | Out-Null

if(Test-Path -Path $logFilePath)
{
Write-Log -Message "$($logFilePath) - Log file created successfully!" -Severity Information
}
else
{
Write-Log -Message "Log file creation failed!" -Severity Error
}

try {
New-Item -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -ItemType file -Force -ErrorAction Stop | Out-Null

Add-Content -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -Value '"PackageName","Version"' -ErrorAction Stop

Write-Log -Message "$($logFolderPath)\beforeDeploymentPackages.csv file created successfully!" -Severity Information

}
catch {
Write-Log -Message "Failed to create $($logFolderPath)\beforeDeploymentPackages.csv file!" -Severity Error
}
}

}

function CreateLogFilesFor_PostValidation # Creates Log Files required for Post-Check inside C:\Logs Directory
{

Param ([string]$logFolderPath
       )


$logFileName = "Post_Validation_Log" + "_" + $(get-date -f yyyy-MM-dd_HH-mm-ss) + ".csv"

$Global:logFilePath  = $logFolderPath + "\" +  $logFileName

New-Item -Path $logFolderPath -Name $logFileName -ItemType File -Force | Out-Null

if(Test-Path -Path $logFilePath)
{
Write-Log -Message "$($logFilePath) - Log file created successfully!" -Severity Information
}
else
{
Write-Log -Message "Log file creation failed!" -Severity Error
}

try {
New-Item -Path "$($logFolderPath)\afterDeploymentPackages.csv" -ItemType file -Force -ErrorAction Stop | Out-Null

Add-Content -Path "$($logFolderPath)\afterDeploymentPackages.csv" -Value '"PackageName","Version"' -ErrorAction Stop

Write-Log -Message "$($logFolderPath)\afterDeploymentPackages.csv file created successfully!" -Severity Information
}
catch {
Write-Log -Message "Failed to create $($logFolderPath)\afterDeploymentPackages.csv file!" -Severity Error
}

try {

New-Item -Path "$($logFolderPath)\DeployedPackageHistory.csv" -ItemType file -Force -ErrorAction Stop | Out-Null

Add-Content -Path "$($logFolderPath)\DeployedPackageHistory.csv" -Value '"PackageName","PreviousVersion","InstalledVersion,"ExpectedVersion"' -ErrorAction Stop

Write-Log -Message "$($logFolderPath)\DeployedPackageHistory.csv file created successfully!" -Severity Information

} catch {
Write-Log -Message "Failed to create $($logFolderPath)\DeployedPackageHistory.csv file!" -Severity Error
}

}

function Write-Log # This function Writes the Logs to Log Files and echo the Logs to terminal.
{
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Message,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information','Warning','Error')]
        [string]$Severity = 'Information'
    )
 
    [pscustomobject]@{
        Time = (Get-Date -f g)
        Message = $Message
        Severity = $Severity
    } | Export-Csv -Path "$($LogFilePath)" -Append -NoTypeInformation

    Write-Host ""
    Write-Host "Time: $((Get-Date -f g)) | Serverity: $($Severity) | Message: $($Message)"
 }

function Get_InstalledPackages # This function takes installed packages information in csv file during Pre Validation.
{

Param ([string]$validationFor,
       [string]$metaFileReleaseJson,
       [string]$EnvironmentName,
       [string]$HC_PhysicalConnectionPath,
       [string]$HWS_PhysicalConnectionPath
       )

$packageVersion = "Package-Version"
$apiName = "WebAPI-Name"
$targetServer = "Server"
$zipPackageName = "Package-Name"
$artifactName = "Artifact-Name"
$artifactVersion = "Artifact-Version"

Write-Log -Message "Collecting Information about existing packages installed on $($env:COMPUTERNAME)" -Severity Information 

$json = Get-Content -Path $metaFileReleaseJson |  ConvertFrom-Json

$services =@{}

if($validationFor -eq "HC")
{

$ExcludeServer = "HWS"

}

if($validationFor -eq "HWS")
{

$ExcludeServer = "HC"

}

foreach ($serviceTypes in $json.Services)
{   

    foreach ($service in $serviceTypes.PSObject.Properties)
    {
        
         foreach ($application in $service.Value.PSObject.Properties)
         {

         $server = $application.Value.PSObject.Properties[$targetServer].Value
         $webApiName = $application.Value.PSObject.Properties[$apiName].Value
         $newPackageVersion  = $application.Value.PSObject.Properties[$packageVersion].Value 

         if($server -match $ExcludeServer)
         {

         continue 

         }
         
         Write-Log -Message "Checking the physical path of WebAPI : $($webApiPath)" -Severity Information 

         $webApiPath = $PhysicalConnectionPath + "\" + $EnvironmentName + "\" + $service.Name + "\" + $webApiName  

         if(Test-Path -Path $webApiPath)
         {

            WriteLog("Check the version of File :" + $versionFile)
            <# Now get the existing version and save to csv file #>
            $exe = (Get-ChildItem $webApiPath -filter *exe)                                
            foreach($ex in $exe)
            {
                   $exeName =  $ex.Name  
                 
                   $existingProductversion = $ex.VersionInfo.FileVersion

                   if($ex.VersionInfo.FileVersion)
                   {

                   Write-Log -Message "Existing Package $($webApiName) Installed with Version : $($existingProductversion)" -Severity Information

                   [pscustomobject]@{ PackageName = $webApiName; Version = $existingProductversion } | Export-Csv -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -Append -NoTypeInformation

                   }
                
            }

         }
         else
         {

         Write-Log -Message "Physical Path of WebAPI - $($webApiName) was not found on $($env:COMPUTERNAME)" -Severity Error

         [pscustomobject]@{ PackageName = $webApiName; Version = "Not Installed" } | Export-Csv -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -Append -NoTypeInformation

         }

       }

     }

  }

     
  $installerName = $json.Installer.POHSql.$artifactName
  $sqlArtifactVersion = $json.Installer.POHSql.$artifactVersion
  $sqlPackageName = $json.Installer.POHSql.$zipPackageName 

  $sql =  Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "POH Business Services" -and $_.InstallSource -match "POH-Bus-Services-SQL" }

  if($sql.count -gt 1)
  {
      Write-Log -Message "Found Multiple Version POH SQL Installed" -Severity Warning

      foreach($s in $sql)
      {

       Write-Log -Message "SQL Package Name: $($s.DisplayName) | Version : $($s.DisplayVersion)" -Severity Information

      }

  }
  else
  {
    if((Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "POH Business Services" -and $_.InstallSource -match "POH-Bus-Services-SQL" }).DisplayVersion)
    {

       $sqlVersion = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "POH Business Services" -and $_.InstallSource -match "POH-Bus-Services-SQL" }).DisplayVersion

       Write-Log -Message "$($sqlPackageName) - $($sqlVersion)" -Severity Information

       [pscustomobject]@{ PackageName = $sqlPackageName; Version = $sqlVersion } | Export-Csv -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -Append -NoTypeInformation

    }
    else
    {

       [pscustomobject]@{ PackageName = $sqlPackageName; Version = "Not Installed" } | Export-Csv -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -Append -NoTypeInformation

    }

  }

}

function Install_AzCLI # This function install AzureCLI
{

if((Test-Path 'C:\Program Files (x86)\Microsoft SDKs\Azure\CLI*'))
{
$env:Path += ";C:\Program Files (x86)\Microsoft SDKs\Azure\CLI2\wbin"

$checkAzCli = az version | ConvertFrom-Json

Write-Log -Message "Found Azure CLI Installed with Version:  $($checkAzCli.'azure-cli')" -Severity Information

}
else
{
Write-Log -Message "Found Azure CLI is not installed on $($env:COMPUTERNAME)" -Severity Warning

try {

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Install-Package -Name PackageManagement -Force -Confirm:$false -Source PSGallery

Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi 

Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet' -ErrorAction Stop

rm .\AzureCLI.msi 

}
catch {

Write-Log -Message "Failed to Download and Install Latest Azure CLI!; Error: $($_)" -Severity Error

}

}

}

function Install_AzPowerShell # This function install AzPowerShell Module
{

$checkAzPowerShell = Get-InstalledModule -Name Az | select Name,Version

$AzPSVersion = $checkAzPowerShell.Version

if($AzPSVersion -ne $null)
{
Write-Log -Message "Found Azure PowerShell module Installed with Version:  $($AzPSVersion)" -Severity Information
}
else
{

Write-Log -Message "Found Azure Az PowerShell module is not installed on $($env:COMPUTERNAME)!" -Severity Warning

try {

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

[Net.ServicePointManager]::SecurityProtocol

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Install-Package -Name PackageManagement -Force -Confirm:$false -Source PSGallery

Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -AllowClobber -Force  -Confirm:$false -ErrorAction Stop

}
catch {

$Exception = "Error: $($_)"

Write-Log -Message "Failed to Download and Install Latest Azure PowerShell module!; $($Exception)" -Severity Error

}

}

}

function Install_SqlModule # This function install SqlModule Module
{

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

[Net.ServicePointManager]::SecurityProtocol

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Install-Package -Name PackageManagement -Force -Confirm:$false -Source PSGallery

try 
{
$checksqlModule = Get-InstalledModule -Name SqlServer -ErrorAction Stop | select Name,Version

$sqlModuleVersion = $checksqlModule.Version

Write-Log -Message "Found SqlServer Module installed with Version: $($sqlModuleVersion)" -Severity Information

}
catch {

Write-Log -Message "SqlServer Module is not installed on $($env:COMPUTERNAME)" -Severity Warning

try {

Install-Module -Name SqlServer -AllowClobber -Force -ErrorAction Stop -Confirm:$false

}
catch {

$Exception = "Error: $($_)"

Write-Log -Message "Failed to Download and Install Latest SqlServer Module; $($Exception)" -Severity Error

}

$sqlModule = Get-InstalledModule -Name SqlServer | select Name, Version

$sqlModuleVersion = $sqlModule.Version

if($sqlModule -ne $null)
{ 
Write-Host "Installed SqlServer Module with Version: $($sqlModuleVersion)"
}
else
{
Write-Host "SqlServer Module Installation Failed!; $($Exception)" 
}

}

}

function Install_DotnetBundle # This function install Dotnets which was passed through parameter
{

Param (
       [string]$dotnetRuntimes
       )

$dotnets = $dotnetRuntimes.Split(",")

foreach($dotnet in $dotnets)
{

Write-Host ".Net Filename: $($dotnet)" 

if(Test-Path -Path "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\$($dotnet)", (Test-Path -Path "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\$($dotnet).*"))
{

Write-Log -Message "Found dotnet-hosting-$($dotnet)-win already installed on $($env:COMPUTERNAME)!" -Severity Information

}
else
{
$dotnetfileHash = (Invoke-WebRequest -Uri https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-aspnetcore-$($dotnet)-windows-hosting-bundle-installer -Method Get -ContentType 'application/json' -UseBasicParsing).InputFields.value

$WebResponseObj = (Invoke-WebRequest -Uri https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-aspnetcore-$($dotnet)-windows-hosting-bundle-installer -Method Get -ContentType 'application/json' -UseBasicParsing)

#REGEX Pattern to get dotnet_download_path

$String = $WebResponseObj.RawContent           
$Regex = [Regex]::new("(?<=window.open).+?(?=\,)")           
$Match = $Regex.Match($String)           
if($Match.Success)           
{           
    $dotnet_download_path  = $Match.Value 
    $dotnet_download_path  = $dotnet_download_path.Substring(2)  
    $dotnet_download_path  = $dotnet_download_path.Substring(0, $($dotnet_download_path.Length)-1)            
}

#REGEX Pattern to get dotnet_file_name

$String = $WebResponseObj.RawContent           
$Regex = [Regex]::new("(?<=/dotnet-hosting-).+?(?=\,)")           
$Match = $Regex.Match($String)           
if($Match.Success)           
{           
    $dotnet_file_name  = $Match.Value  
    $dotnet_file_name  = $dotnet_file_name.Substring(0, $($dotnet_file_name.Length)-1)  
    $dotnet_file_name  = "dotnet-hosting-" + $dotnet_file_name 
         
}

if(-not $dotnet_file_name)
{

$dotnet_file_name = dotnet-hosting-$($dotnet)-win.exe
}

try {

Invoke-WebRequest -Uri $dotnet_download_path -OutFile "C:\Logs\$($dotnet_file_name)" -ErrorAction Stop

}
catch {

Write-Host "Failed to download $($dotnet_file_name)!" 

WriteLog("")

Write-Log -Message "Failed to download $($dotnet_file_name)!; Error: $($_)" -Severity Error

}

# Validate the hash
if((Get-FileHash -Path C:\Logs\$($dotnet_file_name) -Algorithm SHA512).Hash.ToUpper() -ne $($dotnetfileHash).ToUpper()) 
{ 

Write-Log -Message "Computed checksum did not match - $($dotnet_file_name)" -Severity Error

Write-Log -Message "Error encounter during download the file or file not downloaded completely!" -Severity Error

}
else
{

Write-Log -Message "$($dotnet_file_name) downloaded successfully!" -Severity Information

$dotnetexe = Get-ChildItem C:\Logs | Where-Object { $_.Name -like "*.exe" }

try {

Start-Process $($dotnetexe.FullName) -ArgumentList "/install /quiet /norestart" -Wait -NoNewWindow -PassThru -ErrorAction Stop
}
catch {

Write-Host "Error during installation of $($dotnet_file_name)"

}
}

if(Test-Path -Path "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\$($dotnet)", (Test-Path -Path "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\$($dotnet).*"))
{
Write-Log -Message "$($dotnet_file_name) installed successfully!" -Severity Information
}
else
{
Write-Log -Message "Failed to install $($dotnet_file_name)!" -Severity Error
}

Remove-Item -Path $dotnetexe.FullName -Force

}

}

}

function Compare_Packages_With_Json # This function takes installed packages information after service deployment, and also validate with metaFileReleaseJson and create Packages Histroy csv which include Previous Installed Packages, Installed Packages and packages which are required to install 
{
Param ([string]$validationFor,
       [string]$metaFileReleaseJson,
       [string]$EnvironmentName,
       [string]$HC_PhysicalConnectionPath,
       [string]$HWS_PhysicalConnectionPath
       )

$packageVersion = "Package-Version"
$apiName = "WebAPI-Name"
$targetServer = "Server"
$zipPackageName = "Package-Name"
$artifactName = "Artifact-Name"
$artifactVersion = "Artifact-Version"

Write-Log -Message "Collecting Information about existing packages installed on $($env:COMPUTERNAME)" -Severity Information 

$json = Get-Content -Path $metaFileReleaseJson |  ConvertFrom-Json

$services =@{}

if($validationFor -eq "HC")
{

$ExcludeServer = "HWS"

}

if($validationFor -eq "HWS")
{

$ExcludeServer = "HC"

}

foreach ($serviceTypes in $json.Services)
{   

    foreach ($service in $serviceTypes.PSObject.Properties)
    {
        
         foreach ($application in $service.Value.PSObject.Properties)
         {

         $server = $application.Value.PSObject.Properties[$targetServer].Value
         $webApiName = $application.Value.PSObject.Properties[$apiName].Value
         $newPackageVersion  = $application.Value.PSObject.Properties[$packageVersion].Value 

         if($server -match $ExcludeServer)
         {

         continue 

         }
         
         Write-Log -Message "Checking the physical path of WebAPI : $($webApiPath)" -Severity Information 

         $webApiPath = $PhysicalConnectionPath + "\" + $EnvironmentName + "\" + $service.Name + "\" + $webApiName  

         if(Test-Path -Path $webApiPath)
         {
            <# Now get the existing version, compare it with previuos packages information taken in pre_check and save to csv file #>
            $exe = (Get-ChildItem $webApiPath -filter *exe)                                
            foreach($ex in $exe)
            {
                $exeName =  $ex.Name  
                 
                $installedProductversion = $ex.VersionInfo.FileVersion

                if($installedProductversion -match $newPackageVersion)
                {

                   $previouslyInstalledProductVersion = $($beforeDeploymentPackages.GetEnumerator() | % { if($($_.key) -eq "$($webApiName)") { $($_.value) } })

                   $folderSize = Get-Childitem -Path $webApiPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue

                   $folderSizeInMB = "{0:N2} MB" -f ($folderSize.Sum / 1MB)

                   Write-Log -Message "PackageName: $($webApiName) - PackageSize: $($folderSizeInMB)" -Severity Information

                   Write-Log -Message "PackageName: $webApiName ==> Previous Version: $previouslyInstalledProductVersion | Installed Version : $($installedProductversion) | Expected Version : $($newPackageVersion)" -Severity Information

                   [pscustomobject]@{ PackageName = $webApiName; PreviousVersion = $($beforeDeploymentPackages.GetEnumerator() | % { if($($_.key) -eq "$($webApiName)") { $($_.value)  } }); InstalledVersion = $($installedProductversion); ExpectedVersion = $($newPackageVersion) } | Export-Csv -Path "$($logFolderPath)\DeployedPackageHistory.csv" -Append -NoTypeInformation

                   [pscustomobject]@{ PackageName = $webApiName; Version = $installedProductversion } | Export-Csv -Path "$($logFolderPath)\afterDeploymentPackages.csv" -Append -NoTypeInformation

                }
                
            }

         }
         else
         {

         Write-Log -Message "Physical Path of WebAPI - $($webApiName) was not found on $($env:COMPUTERNAME)" -Severity Error

         [pscustomobject]@{ PackageName = $webApiName; Version = "Not Installed" } | Export-Csv -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -Append -NoTypeInformation

         }

       }

     }

  }
     
  $installerName = $json.Installer.POHSql.$artifactName
  $sqlArtifactVersion = $json.Installer.POHSql.$artifactVersion
  $sqlPackageName = $json.Installer.POHSql.$zipPackageName 

  $sql =  Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "POH Business Services" -and $_.InstallSource -match "POH-Bus-Services-SQL" }

  if($sql.count -gt 1)
  {
      Write-Log -Message "Found Multiple Version POH SQL Installed" -Severity Warning

      foreach($s in $sql)
      {

       Write-Log -Message "SQL Package Name: $($s.DisplayName) | Version : $($s.DisplayVersion)" -Severity Information

      }

  }
  else
  {
    if((Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "POH Business Services" -and $_.InstallSource -match "POH-Bus-Services-SQL" }).DisplayVersion)
    {

       $sqlVersion = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "POH Business Services" -and $_.InstallSource -match "POH-Bus-Services-SQL" }).DisplayVersion

       Write-Log -Message "$($sqlPackageName) - $($sqlVersion)" -Severity Information

       [pscustomobject]@{ PackageName = $sqlPackageName; Version = $sqlVersion } | Export-Csv -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -Append -NoTypeInformation

    }
    else
    {

       [pscustomobject]@{ PackageName = $sqlPackageName; Version = "Not Installed" } | Export-Csv -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -Append -NoTypeInformation

    }

  }

 }

function Check_HTTPS_Binding # This function checkes IIS has Https Binidng or not
{

$WebSite = Get-Website

$CheckHttpsBinding = Get-IISSiteBinding $WebSite.Name -Protocol https | Out-Null

if($CheckHttpsBinding -and $CheckHttpsBinding.BindingInformation -eq "*:443:")
{
Write-Log -Message "https binding in IIS is already added!" -Severity Information
}
else
{
Write-Log -Message "https binding is not configured in IIS!" -Severity Warning
}

}

<#
function Check_POHSQL # This function checks for POH SQL Packages, it will ensure no multiple POH SQL Packages are installed. 
{

Param ([string]$validationFor,
       [string]$metaFileReleaseJson,
       [string]$EnvironmentName,
       [string]$HC_PhysicalConnectionPath,
       [string]$HWS_PhysicalConnectionPath
       )

  Write-Log -Message "Checking for POH SQL Packages on $($env:COMPUTERNAME)" -Severity Information 

  $sql =  Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "POH Business Services" -and $_.InstallSource -match "POH-Bus-Services-SQL" }

  if($sql.count -gt 1)
  {
      Write-Log -Message "Found Multiple Version POH SQL Installed" -Severity Warning

      foreach($s in $sql)
      {

       Write-Log -Message "SQL Package Name: $($s.DisplayName) | Version : $($s.DisplayVersion)" -Severity Information

      }

  }
  else
  {
    if((Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "POH Business Services" -and $_.InstallSource -match "POH-Bus-Services-SQL" }).DisplayVersion)
    {

       $sqlVersion = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -match "POH Business Services" -and $_.InstallSource -match "POH-Bus-Services-SQL" }).DisplayVersion

       Write-Log -Message "$($sqlPackageName) - $($sqlVersion)" -Severity Information


    }
    else
    {
       Write-Log -Message "$($sqlPackageName) - is not installed!" -Severity Warning
    }

  }

}

#>

function Check_HeliosConnet_EnterpriseManager # This function checks the Helios Connect and Enterprise Manager version is sufficient for Service Deployment
{

Param ([string]$requiredHeliosConnectVersion,
       [string]$requiredEnterpriseManagerVersion
      )

$checkHelios = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -like "*Helios Connect*" -and $_.DisplayName -notlike "*Services*" }).DisplayVersion
$checkEntMgr = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -like "*Enterprise Manager*" }).DisplayVersion

if($checkHelios -ne $null -and $checkEntMgr -ne $null)
{

$existingHeliosConnectVersion = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -like "*Helios Connect*" -and $_.DisplayVersion -eq "$($HeliosConnectVersion)" }).DisplayVersion

$existingEnterpriseManagerVersion = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -like "*Enterprise Manager*" -and $_.DisplayVersion -eq "$($EnterpriseManagerVersion)" }).DisplayVersion

$existingAllscriptsGatewayVersion = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -like "*Allscripts Gateway*" -and $_.DisplayVersion -eq "$($AllscriptsGatewayVersion)" }).DisplayVersion


if([version]$existingHeliosConnectVersion -lt [version]$requiredHeliosConnectVersion -and [version]$existingEnterpriseManagerVersion -lt [version]$requiredEnterpriseManagerVersion)
{
Write-Log -Message "Both Helios Connect and Enterprise Manager Version are lower than expected version to proceed with service deployment" -Severity Warning
$InstalledHeliosConnectVersion = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -like "*Helios Connect*" -and $_.DisplayName -notlike "*Services*" }).DisplayVersion
$InstalledEnterpriseManagerVersion = (Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where { $_.DisplayName -like "*Enterprise Manager*" }).DisplayVersion 
Write-Log -Message "Existing Helios Connect Version    : $($InstalledHeliosConnectVersion)" -Severity Information
Write-Log -Message "Existing Enterprise Manager Version: $($InstalledEnterpriseManagerVersion)" -Severity Information
}
elseif([version]$getHeliosConnectVersion -ge [version]$HeliosConnectVersion -and [version]$getEnterpriseManagerVersion -ge [version]$EnterpriseManagerVersion)
{
Write-Log -Message "Both Helios Connect and Enterprise Manager Version are same, We are good to proceed with service deployment" -Severity Information
}

}
else
{
Write-Log -Message "Enterprise Manager and Helios Connect is not installed on $($env:COMPUTERNAME)" -Severity Warning
}

}

function Check_SqlScript # This function checks service account has added in database and has required role assigned.
{

Param (
       [string]$sqlServer,
       [string]$sqlDatabase,
       [string]$sqlAccount,
       [string]$sqlRole
       )

try
{
$sqlLoginCheck = Invoke-Sqlcmd -Query "SELECT * FROM sys.server_principals WHERE Name = '$($sqlAccount)'" -ServerInstance $sqlServer

if($sqlLoginCheck.name -eq $sqlAccount)
{

Write-Log -Message "SQL Login $($sqlLoginCheck.name) is found added" -Severity Information

$sqlLoginPresent = $true

}


}
catch {

Write-Log -Message "sqlLoginCheck_Query failed; Error: $($_)" -Severity Error

}

try
{

$sqlRoleCheck = Invoke-Sqlcmd -Query "SELECT * FROM sys.database_principals WHERE Name = '$($sqlRole)'" -ServerInstance $sqlServer -Database $sqlDatabase


if($sqlRoleCheck.name -eq "$($sqlRole)")
{

Write-Log -Message "SQL Role $($sqlRoleCheck.name) is found added!" -Severity Information

$sqlRolePresent = $true


}

}
catch {

Write-Log -Message "sqlRoleCheck_Query failed; Error: $($_)" -Severity Error

}

if($sqlLoginPresent -eq $true -and $sqlRolePresent -eq $true)
{

Write-Log -Message "$($sqlAccount) User has $($sqlRole) Role Assigned on $($sqlDatabase) Database" -Severity Information

}

}

function Check_IISAppPools # This function checks Application Pools and tries to start the App Pool which was not started.
{

    Param ([string]$validationFor,
       [string]$metaFileReleaseJson,
       [string]$EnvironmentName,
       [string]$HC_PhysicalConnectionPath,
       [string]$HWS_PhysicalConnectionPath
       )


$packageVersion = "Package-Version"
$apiName = "WebAPI-Name"
$targetServer = "Server"
$zipPackageName = "Package-Name"
$artifactName = "Artifact-Name"
$artifactVersion = "Artifact-Version"

$json = Get-Content -Path $metaFileReleaseJson |  ConvertFrom-Json

$services =@{}

if($validationFor -eq "HC")
{

$ExcludeServer = "HWS"

}

if($validationFor -eq "HWS")
{

$ExcludeServer = "HC"

}

Import-Module WebAdministration

foreach ($serviceTypes in $json.Services)
{   

    foreach ($service in $serviceTypes.PSObject.Properties)
    {
        
         foreach ($application in $service.Value.PSObject.Properties)
         {

         $server = $application.Value.PSObject.Properties[$targetServer].Value
         $webApiName = $application.Value.PSObject.Properties[$apiName].Value
         $newPackageVersion  = $application.Value.PSObject.Properties[$packageVersion].Value 

         if($server -match $ExcludeServer)
         {

         continue 

         }
         
         Write-Log -Message "Checking App Pool for : $($webApiPath)" -Severity Information 

         $webApiPath = $PhysicalConnectionPath + "\" + $EnvironmentName + "\" + $service.Name + "\" + $webApiName  

         if(Test-Path -Path $webApiPath)
         {

         try {
                
                $checkWebApi = $null
				$completed   = $false
				$retryCount  = 0

				while (-not $completed) {

                try {

                $checkWebApi = Get-ChildItem IIS:AppPools | Where-Object { $_.name -like "*$($webApiName)*" } | Where-Object {$_.state -ne "Started"} | Start-WebAppPool

                if($checkWebApi.state -eq "Started")
                {

                 Write-Log -Message "App Pool Started Successfully : $($checkWebApi.Name) | Status: $checkWebApi.State " -Severity Information

                 $completed = $true 

                }
                else
                {

                throw "Retrying health check"

                } 

                }
                catch {

                      Write-Log -Message "Error during app pool start($(webApiName)) | Error: $($_)" -Severity Error

                	  if ($retryCount -ge $Retries) {
                         Write-Log -Message "Retrying to start $($webApiName) application pool has reached maximum no of $retryCount times." -Severity Warning
					     throw
				      } else {
                         Write-Log -Message "Failed to start $($webApiName) application pool. Retrying in $SecondsDelay seconds." -Severity Warning
					     Start-Sleep $SecondsDelay
					     $retryCount++
				      }

                }

                }
   
             }
             catch {

             Write-Host ""
             Write-Log -Message "Failed to start App Pool for $($webApiName) | Error: $($_)" -Severity Error

             }

         }
         else
         {

         Write-Log -Message "Physical Path of WebAPI - $($webApiName) was not found on $($env:COMPUTERNAME)" -Severity Error

         }

       }

     }

  }

}

function Check_Packages_PhysicalPath_With_IIS # This function validates the Packages Physical Connection Path with Web Application on IIS
{

    Param ([string]$validationFor,
       [string]$metaFileReleaseJson,
       [string]$EnvironmentName,
       [string]$HC_PhysicalConnectionPath,
       [string]$HWS_PhysicalConnectionPath
       )

$packageVersion = "Package-Version"
$apiName = "WebAPI-Name"
$targetServer = "Server"
$zipPackageName = "Package-Name"
$artifactName = "Artifact-Name"
$artifactVersion = "Artifact-Version"

$json = Get-Content -Path $metaFileReleaseJson |  ConvertFrom-Json

$services =@{}

if($validationFor -eq "HC")
{

$ExcludeServer = "HWS"

}

if($validationFor -eq "HWS")
{

$ExcludeServer = "HC"

}

foreach ($serviceTypes in $json.Services)
{   

    foreach ($service in $serviceTypes.PSObject.Properties)
    {
        
         foreach ($application in $service.Value.PSObject.Properties)
         {

         $server = $application.Value.PSObject.Properties[$targetServer].Value
         $webApiName = $application.Value.PSObject.Properties[$apiName].Value
         $newPackageVersion  = $application.Value.PSObject.Properties[$packageVersion].Value 

         if($server -match $ExcludeServer)
         {

         continue 

         }
         
         Write-Log -Message "Checking the Physical Path with IIS : $($webApiPath)" -Severity Information 

         $webApiPath = $PhysicalConnectionPath + "\" + $EnvironmentName + "\" + $service.Name + "\" + $webApiName  

         if(Test-Path -Path $webApiPath)
         {

           try {

                $checkApplication_PhysicalPath = Get-WebApplication | ConvertTo-Json | ConvertFrom-Json | % {  $_.PhysicalPath -like "*$($webApiName)" } -ErrorAction Stop
         
                Write-Log -Message "Web Application found for $($webApiName) in IIS with PhysicalPath -->  $($checkApplication_PhysicalPath)" -Severity Information
                
              }
              catch {

                Write-Log -Message "Web Application is not created for $($webApiName) in IIS, because Physical Path not found in IIS for $($webApiName)" -Severity Error

              }

         }
         else
         {

         Write-Log -Message "Physical Path of WebAPI - $($webApiName) was not found on $($env:COMPUTERNAME)" -Severity Error

         }

       }

     }

  }

}

