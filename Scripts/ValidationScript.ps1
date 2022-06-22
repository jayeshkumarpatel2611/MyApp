[CmdletBinding()]
param (
  [parameter(Mandatory=$true)]
  [ValidateSet('HC','HWS')]                 
  [string]$validationFor,                    # Required Parameter  # Example: HC or HWS 
  [parameter(Mandatory=$true)]               
  [ValidateSet('Pre','Post')]
  [string]$validationType,                   # Required Parameter  # Example: Pre or Post
  [parameter(Mandatory=$true,                
  HelpMessage="List of dotnet framework names separated by commas. Exanple: 2.1.28,3.1.16,7.0.0-preview.5")]
  [string]$dotnetRuntimes,                   # Required Parameter
  [parameter(Mandatory=$true)]
  [string]$EnvironmentName,                  # Required Parameter
  [parameter(Mandatory=$true)]
  [string]$metaFileReleaseJson,              # Required Parameter
  [parameter(Mandatory=$true)]
  [string]$ValidationScriptModulePath,       # Required Parameter
  [parameter(Mandatory=$true)]
  [string]$requiredHeliosConnectVersion,     # Required Parameter
  [parameter(Mandatory=$true)]
  [string]$requiredEnterpriseManagerVersion, # Required Parameter
  [parameter(Mandatory=$true)]
  [string]$sqlServer,                        # Required Parameter
  [parameter(Mandatory=$true)]
  [string]$sqlDatabase,                      # Required Parameter
  [parameter(Mandatory=$false)]
  [string]$sqlAccount,                       # Optional Parameter
  [parameter(Mandatory=$false)] 
  [string]$sqlRole,                          # Optional Parameter
  [parameter(Mandatory=$false)]           
  [string]$HC_PhysicalConnectionPath,        # Optional Parameter
  [parameter(Mandatory=$false)]           
  [string]$HWS_PhysicalConnectionPath        # Optional Parameter
  )

$logFolderName = "Logs"

$logFolderPath = "C:\" + $logFolderName



if(-not $sqlRole)
{

$sqlRole = "SXAGitActions"

}

if(-not $sqlAccount)
{

$sqlAccount =  $env:USERDOMAIN + "\" + $env:USERNAME

}

if($validationFor -eq "HC")
{
if(-not $HC_PhysicalConnectionPath)
{

$PhysicalConnectionPath = "C:\Program Files (x86)\Allscripts Sunrise\Helios\8.7\HeliosConnect" 

}
}

if($validationFor -eq "HWS")
{
if(-not $HWS_PhysicalConnectionPath)
{

$PhysicalConnectionPath = "C:\Program Files (x86)\Allscripts Sunrise\POH"

}

}

# Check Whether Script is invoked by Administrative Previledge User Account

$id = [System.Security.Principal.WindowsIdentity]::GetCurrent()

$p = New-Object System.Security.Principal.WindowsPrincipal($id)

if($p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator))
{ 
   
   Write-Host "Script is executed by Administrative Previledge Account" 
   
}     
else
{ 
   
   Write-Host "Script is executed by Non-Administrative Priviledge Account" 
   
}


function ImportValidationScriptModule
{
   
    Import-Module -Name $ValidationScriptModulePath
}

ImportValidationScriptModule

if($validationFor -eq "HC" -or $validationFor -eq "HWS" -and $validationType -eq "Pre" -or $validationType -eq "Post")
{

try 
{  

  CreateLogDirectory -logFolderPath $logFolderPath

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information      

}

}

# Prerequisites Check Before Service Deployment
 
if($validationFor -eq "HC" -or $validationFor -eq "HWS" -and $validationType -eq "Pre")
{

try 
{  

  CreateLogFilesFor_PreValidation -logFolderPath $logFolderPath

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   


}

try {

  Install_AzCLI

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

}

try {

  Install_DotnetBundle -dotnetRuntimes $dotnetRuntimes

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

}

try {

  Get_InstalledPackages -metaFileReleaseJson $metaFileReleaseJson -EnvironmentName $EnvironmentName -HC_PhysicalConnectionPath $HC_PhysicalConnectionPath -HWS_PhysicalConnectionPath $HWS_PhysicalConnectionPath

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

}

if(($validationFor -eq "HC") -and $validationType -eq "Pre")
{

try {

  Install_SqlModule

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

} 

try {

  Check_SqlScript -validationFor -sqlServer $sqlServer -sqlDatabase $sqlDatabase -sqlAccount $sqlAccount -sqlRole $sqlRole

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

}

try {

  Check_HeliosConnet_EnterpriseManager -validationFor $validationFor -requiredHeliosConnectVersion $requiredHeliosConnectVersion -requiredEnterpriseManagerVersion $requiredEnterpriseManagerVersion -requiredAllscriptsGatewayVersion $requiredAllscriptsGatewayVersion

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

}

try {

  Check_HTTPS_Binding

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

} 

}

}

# Post Check After Service Deployment

if($validationFor -eq "HC" -or $validationFor -eq "HWS" -and $validationType -eq "Post")
{ 

try 
{  

  CreateLogFilesFor_PostValidation -logFolderPath $logFolderPath

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   


}

try {

  Compare_Packages_With_Json -metaFileReleaseJson $metaFileReleaseJson -EnvironmentName $EnvironmentName -HC_PhysicalConnectionPath $HC_PhysicalConnectionPath -HWS_PhysicalConnectionPath $HWS_PhysicalConnectionPath

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

} 

try {

  Check_IISAppPools -validationFor -metaFileReleaseJson $metaFileReleaseJson -EnvironmentName $EnvironmentName -HC_PhysicalConnectionPath $HC_PhysicalConnectionPath -HWS_PhysicalConnectionPath $HWS_PhysicalConnectionPath

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

} 

}

# Create UploadLogs Directory to upload logs generated by script.

try {

New-Item -Path C:\ -Name UploadLogs -ItemType Directory -Force -ErrorAction Stop | Out-Null

Write-Log -Message "Directory created for uploading logs." -Severity Information

}
catch {

Write-Host "Failed to create directory to upload logs"

}

# Copy Logs Files from C:\Logs to C:\UploadLogs Directory for upload

if($validationType -eq "Pre")
{

try {
Copy-Item -Path $logFilePath -Destination 'C:\UploadLogs' -Force -ErrorAction Stop
Write-Log -Message "$($logFilePath) File copied to C:\UploadLogs directory successfully!" -Severity Information
}
catch {
Write-Log -Message "$($logFilePath) File failed to copy to C:\UploadLogs directory!" -Severity Information
}

try {
Copy-Item -Path "$($logFolderPath)\beforeDeploymentPackages.csv" -Destination 'C:\UploadLogs' -Force -ErrorAction Stop
Write-Log -Message "$($logFolderPath)\beforeDeploymentPackages.csv File copied to C:\UploadLogs directory successfully!" -Severity Information
}
catch {
Write-Log -Message "$($logFolderPath)\beforeDeploymentPackages.csv File failed to copy to C:\UploadLogs directory!" -Severity Information
}

}

if($validationType -eq "Post")
{

try {
Copy-Item -Path $logFilePath -Destination 'C:\UploadLogs' -Force -ErrorAction Stop
Write-Log -Message "$($logFilePath) File copied to C:\UploadLogs directory successfully!" -Severity Information
}
catch {
Write-Log -Message "$($logFilePath) File failed to copy to C:\UploadLogs directory!" -Severity Information
}

try {
Copy-Item -Path "$($logFolderPath)\afterDeploymentPackages.csv" -Destination 'C:\UploadLogs' -Force -ErrorAction Stop
Write-Log -Message "$($logFolderPath)\afterDeploymentPackages.csv File copied to C:\UploadLogs directory successfully!" -Severity Information
}
catch {
Write-Log -Message "$($logFolderPath)\afterDeploymentPackages.csv File failed to copy to C:\UploadLogs directory!" -Severity Information
}

try {
Copy-Item -Path "$($logFolderPath)\DeployedPackageHistory.csv" -Destination 'C:\UploadLogs' -Force -ErrorAction Stop
Write-Log -Message "$($logFolderPath)\DeployedPackageHistory.csv File copied to C:\UploadLogs directory successfully!" -Severity Information
}
catch {
Write-Log -Message "$($logFolderPath)\DeployedPackageHistory.csv File failed to copy to C:\UploadLogs directory!" -Severity Information
}

}


if($validationType -eq "Pre" -and $validationFor -eq "HC")
{

if($sqlScriptCheck -eq $false)
{
$LASTEXITCODE = 1

Write-Host "Last Exit Code: " $LASTEXITCODE

Write-Host "SQL Check: " $sqlScriptCheck
}

}

# Not Used Code Blocks

<#

try {

  Install_AzPowerShell

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

}

try {

  Check_POHSQL -validationFor $validationFor -metaFileReleaseJson $metaFileReleaseJson -EnvironmentName $EnvironmentName -HC_PhysicalConnectionPath $HC_PhysicalConnectionPath -HWS_PhysicalConnectionPath $HWS_PhysicalConnectionPath

}
catch {

  $ErrorMessage = $_.Exception.Message  
  Write-Log -Message "Error: $($ErrorMessage)" -Severity Information   

}

#>
