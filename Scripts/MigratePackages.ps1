[CmdletBinding()]
param (
  [string]$outputFile,
  [string]$outlogFile,
  [string]$metaFileReleaseJson,
  [parameter(Mandatory=$True)]
  [string]$destinationOrganization,
  [parameter(Mandatory=$True)]
  [string]$destinationProjectName,
  [parameter(Mandatory=$True)]
  [string]$destinationFeedName,
  [parameter(Mandatory=$True)]
  [string]$destinationScope,
  [parameter(Mandatory=$True)]
  [string]$metaFileReleasePath,
  [parameter(Mandatory=$True)]
  [string]$SourceOrg_PAT,
  [parameter(Mandatory=$True)]
  [string]$DestinationOrg_PAT
)

$metaFileReleasePath =  $metaFileReleasePath

$json = Get-Content -path $metaFileReleasePath |  ConvertFrom-Json

$zipPackageName = "Package-Name"

$artifactVersion = "Artifact-Version"

$ArtifactName = "Artifact-Name"

$sourceOrganization = $json.Organization

$downloadPath = "C:\Packages"

$sourceFeedName= $json.Feed

$sourceScope = $json.Scope

$sourceProjectName= $json.Project

$downloadedPackagesList = New-Object System.Collections.Generic.List[string]

$uploadedPackagesList = New-Object System.Collections.Generic.List[string]

$packagesExistsList = New-Object System.Collections.Generic.List[string]

$logFolderName = "Logs"

$packagesFolderName = "Packages"

$logFolderPath = "C:\" + $logFolderName

$logFileName = "Artifacts_Log" + "_" + $(get-date -f yyyy-MM-dd_HH-mm-ss) + ".txt"

$logFilePath  = $logFolderPath + "\" +  $logFileName

$match1 = $false

$match2 = $false

$jsonBase = @{}

$d = 0

$u = 0

$e = 0

$t = 0

if(-not (Test-Path -Path $downloadPath))
{

New-Item -Path C:\ -Name $packagesFolderName -ItemType Directory -Force 

}
else
{

Write-Host "C:\Packages directory already exists!"

}

if(-not (Test-Path -Path $logFolderPath))
{

New-Item -Path C:\ -Name $logFolderName -ItemType Directory -Force

New-Item -Path $logFolderPath -Name $logFileName -ItemType File -Force 

}
else
{
Write-Host "C:\Logs directory already exists!"
}

Function WriteLog
{
   Param ([string]$logstring)

   write-host ($logstring)
   Add-content $LogFilePath -value $logstring -Force
}

az extension add --name azure-devops

foreach ($serviceTypes in $json.Services)
{   

    foreach ($service in $serviceTypes.PSObject.Properties)
    {
        
         foreach ($application in $service.Value.PSObject.Properties)
         {

         $packageName = $application.Value.PSObject.Properties[$zipPackageName].Value
         $packageVersion = $application.Value.PSObject.Properties[$artifactVersion].Value

         $len = $sourceOrganization.Length - 22

         $Organization = $sourceOrganization.Substring(22, $($len)).Trim("/")

         $Response = ""

         $Url = "https://pkgs.dev.azure.com/$($Organization)/$($sourceProjectName)/_apis/packaging/feeds/$($sourceFeedName)/upack/packages/$($packageName)/versions/$($packageVersion)?api-version=6.0-preview.1";

         Write-Host "Initialize authentication context" -ForegroundColor Yellow

         $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$SourceOrg_PAT"))

         $Header = @{authorization = "Basic $Token"}

         try {

         $Response = Invoke-RestMethod -Uri $Url -Headers $Header -Method Get | ConvertTo-Json | ConvertFrom-Json

   
         } catch {

                if($_.ErrorDetails.Message) {
               
                        Write-Host "Error : $_.ErrorDetails.Message"     


                    } else {
                        
                        Write-Host "$_"
                    }

         }

         if($Response.name -match $packageName )
         {

         $packageName = $Response.name

         }
         else
         {

         Write-Host "No Zip Package."

         }

         $packageName = $application.Value.PSObject.Properties[$ArtifactName].Value
         $packageVersion = $application.Value.PSObject.Properties[$artifactVersion].Value

         $Response = ""

         $Url = "https://pkgs.dev.azure.com/$($Organization)/$($sourceProjectName)/_apis/packaging/feeds/$($sourceFeedName)/upack/packages/$($packageName)/versions/$($packageVersion)?api-version=6.0-preview.1";

         Write-Host "Initialize authentication context" -ForegroundColor Yellow

         $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$SourceOrg_PAT"))

         $Header = @{authorization = "Basic $Token"}

         try { 

         $Response = Invoke-RestMethod -Uri $Url -Headers $Header -Method Get | ConvertTo-Json | ConvertFrom-Json     

         } catch {

                if($_.ErrorDetails.Message) {
                
                       Write-Host "Error : $_.ErrorDetails.Message"


                    } else {
                 
                        Write-Host "$_"
                    }

         }

         if($Response.name -match $packageName )
         {

         $packageName = $Response.name

         }
         else
         {

         Write-Host "Zip Package."

         }

         # Check Currently Processed Package is available on destination feed or not, if not then only it will process for download and upload task
         
         Write-Host "Package: " $packageName

         Write-Host "Version: " $packageVersion


         $len = $destinationOrganization.Length - 22

         $Organization = $destinationOrganization.Substring(22, $($len)).Trim("/")

         $Response = ""

         $Url = "https://pkgs.dev.azure.com/$($Organization)/$($destinationProjectName)/_apis/packaging/feeds/$($destinationFeedName)/upack/packages/$($packageName)/versions/$($packageVersion)?api-version=6.0-preview.1";

         Write-Host "Initialize authentication context" -ForegroundColor Yellow

         $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$DestinationOrg_PAT"))

         $Header = @{authorization = "Basic $Token"}

         try {

         $Response = Invoke-RestMethod -Uri $Url -Headers $Header -Method Get -ErrorAction Stop | ConvertTo-Json | ConvertFrom-Json


         } catch {

                if($_.ErrorDetails.Message) {

                            Write-Host "Error : $_.ErrorDetails.Message"


                    } else {

                        Write-Host "$_"
                    }

         }
         

         if($Response.name -match $packageName -and $Response.version -match $packageVersion) 
         {

         $packagesExistsList.Add($packageName + "_" + $packageVersion)
         $Response = ""
         $Url = ""
         $Token = ""
         $e = $e + 1
        
         }
         else
         {
    
         Write-Host "Downloading below package from $($sourceFeedName) Feed" 

         Write-Host "Package: " $packageName

         Write-Host "Version: " $packageVersion

         Write-Host ""

         # Download Package from Source Feed

         $env:AZURE_DEVOPS_EXT_PAT = "$($SourceOrg_PAT)"

         $env:AZURE_DEVOPS_EXT_PAT | az devops login --organization $sourceOrganization

         $Error.clear();

         az artifacts universal download --organization $sourceOrganization --project="$($sourceProjectName)" --scope $sourceScope --feed $sourceFeedName --name $packageName --version $packageVersion --path $downloadPath --verbose

         $packagePath = $downloadPath + "\" + $packageName + ".zip"

         if($Error.Count -gt 0)
         {    
            foreach($err in $Error)
            {
                WriteLog($err.exception)
                Write-Host $err.exception
            }   
         }
         else
         {
            if(Test-Path -Path $packagePath)
            {
                WriteLog("Package " + $packageName + " is downloaded with version " + $packageVersion + " at: " + $packagePath)
                $downloadedPackagesList.Add($packageName + "_" + $packageVersion);
                $d = $d + 1

            }                            
         }

         az devops logout --organization $sourceOrganization

         $env:AZURE_DEVOPS_EXT_PAT = ""

         # Publish Package to Destination Feed

         $env:AZURE_DEVOPS_EXT_PAT = "$($DestinationOrg_PAT)"

         $env:AZURE_DEVOPS_EXT_PAT | az devops login --organization $destinationOrganization

         $Error.clear();

         Write-Host "Uploading below package to $($destinationFeedName) Feed" 

         Write-Host "Package: " $packageName

         Write-Host "Version: " $packageVersion

         Write-Host ""

         az artifacts universal publish --organization $destinationOrganization --project="$($destinationProjectName)" --scope $destinationScope --feed $destinationFeedName --name $packageName --version $packageVersion --path $downloadPath --verbose
         
         if($Error.Count -gt 0)
         {    
            foreach($err in $Error)
            {
                WriteLog($err.exception)
                Write-Host $err.exception
            }   
         }
         else
         {
         
         $len = $destinationOrganization.Length - 22

         $Organization = $destinationOrganization.Substring(22, $($len)).Trim("/")

         $Response = ""

         $Url = "https://pkgs.dev.azure.com/$($Organization)/$($destinationProjectName)/_apis/packaging/feeds/$($destinationFeedName)/upack/packages/$($packageName)/versions/$($packageVersion)?api-version=6.0-preview.1";

         Write-Host "Initialize authentication context" -ForegroundColor Yellow

         $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$DestinationOrg_PAT"))

         $Header = @{authorization = "Basic $Token"}

         try {

         $Response = Invoke-RestMethod -Uri $url -Headers $Header -Method Get -ErrorAction Stop | ConvertTo-Json | ConvertFrom-Json


         } catch {

                if($_.ErrorDetails.Message) {


                            WriteLog($_.ErrorDetails.Message)
                            Write-Host "Error : $_.ErrorDetails.Message"


                    } else {

                        Write-Host $_
                        WriteLog($_)
                    }

         }

         if($Response.name -match $packageName -and $Response.version -match $packageVersion) 
         {
                WriteLog("Package " + $packageName + " is uploaded with version " + $packageVersion + " at: " + $destinationFeedName)

                Write-Host "Package " + $packageName + " is uploaded with version " + $packageVersion + " at: " + $destinationFeedName
                $uploadedPackagesList.Add($packageName + "_" + $packageVersion);
                $Response = ""
                $Url = ""
                $Token = ""
                $u = $u + 1
        
         }
         else
         {
 
             WriteLog("Package upload failed " + $packageName + " with version " + $packageVersion + " at: " + $destinationFeedName)

             Write-Host "Package upload failed " + $packageName + " with version " + $packageVersion + " at: " + $destinationFeedName

         }
                            
         }

         az devops logout --organization $destinationOrganization

         $env:AZURE_DEVOPS_EXT_PAT = ""

        }

        $t = $t + 1

        }

    }

}

foreach ($installerTypes in $json.Installer)
{   

    foreach ($installer in $installerTypes.PSObject.Properties)
    {

         $packageName = $installer.Value.PSObject.Properties[$zipPackageName].Value
         $packageVersion = $installer.Value.PSObject.Properties[$artifactVersion].Value

         Write-Host "Installer Package Name: " $packageName
         Write-Host "Installer Package Version: " $packageVersion


         $len = $sourceOrganization.Length - 22

         $Organization = $sourceOrganization.Substring(22, $($len)).Trim("/")

         $Response = ""

         $Url = "https://pkgs.dev.azure.com/$($Organization)/$($sourceProjectName)/_apis/packaging/feeds/$($sourceFeedName)/upack/packages/$($packageName)/versions/$($packageVersion)?api-version=6.0-preview.1";

         Write-Host "Initialize authentication context" -ForegroundColor Yellow

         $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$SourceOrg_PAT"))

         $Header = @{authorization = "Basic $Token"}

         try {

         $Response = Invoke-RestMethod -Uri $Url -Headers $Header -Method Get | ConvertTo-Json | ConvertFrom-Json

   
         } catch {

                if($_.ErrorDetails.Message) {
               
                        Write-Host "Error : $_.ErrorDetails.Message"     


                    } else {
                        
                        Write-Host "$_"
                    }

         }

         if($Response.name -match $packageName )
         {

         $packageName = $Response.name

         }
         else
         {

         Write-Host "No Zip Package."

         $match1 = $true

         }

         $packageName = $installer.Value.PSObject.Properties[$ArtifactName].Value
         $packageVersion = $installer.Value.PSObject.Properties[$artifactVersion].Value

         $Response = ""

         $Url = "https://pkgs.dev.azure.com/$($Organization)/$($sourceProjectName)/_apis/packaging/feeds/$($sourceFeedName)/upack/packages/$($packageName)/versions/$($packageVersion)?api-version=6.0-preview.1";

         Write-Host "Initialize authentication context" -ForegroundColor Yellow

         $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$SourceOrg_PAT"))

         $Header = @{authorization = "Basic $Token"}

         try { 

         $Response = Invoke-RestMethod -Uri $Url -Headers $Header -Method Get | ConvertTo-Json | ConvertFrom-Json     

         } catch {

                if($_.ErrorDetails.Message) {
                
                       Write-Host "Error : $_.ErrorDetails.Message"


                    } else {
                 
                        Write-Host "$_"
                    }

         }

         if($Response.name -match $packageName )
         {

         $packageName = $Response.name

         }
         else
         {

         Write-Host "Zip Package."

         $match2 = $true

         }

         if($match1 -eq $true -and $match2 -eq $true)
         {

         $packageName = $installer.Value.PSObject.Properties[$ArtifactName].Value

         }

         # Check Currently Processed Package is available on destination feed or not, if not then only it will process for download and upload task
         
         Write-Host "Package: " $packageName

         Write-Host "Version: " $packageVersion


         $len = $destinationOrganization.Length - 22

         $Organization = $destinationOrganization.Substring(22, $($len)).Trim("/")

         $Response = ""

         $Url = "https://pkgs.dev.azure.com/$($Organization)/$($destinationProjectName)/_apis/packaging/feeds/$($destinationFeedName)/upack/packages/$($packageName)/versions/$($packageVersion)?api-version=6.0-preview.1";

         Write-Host "Initialize authentication context" -ForegroundColor Yellow

         $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$DestinationOrg_PAT"))

         $Header = @{authorization = "Basic $Token"}

         try {

         $Response = Invoke-RestMethod -Uri $Url -Headers $Header -Method Get -ErrorAction Stop | ConvertTo-Json | ConvertFrom-Json


         } catch {

                if($_.ErrorDetails.Message) {

                            Write-Host "Error : $_.ErrorDetails.Message"


                    } else {

                        Write-Host "$_"
                    }

         }
         

         if($Response.name -match $packageName -and $Response.version -match $packageVersion) 
         {

         $packagesExistsList.Add($packageName + "_" + $packageVersion)
         $Response = ""
         $Url = ""
         $Token = ""
         $e = $e + 1
        
         }
         else
         {
    
         Write-Host "Downloading below package from $($sourceFeedName) Feed" 

         Write-Host "Package: " $packageName

         Write-Host "Version: " $packageVersion

         Write-Host ""

         # Download Package from Source Feed

         $env:AZURE_DEVOPS_EXT_PAT = "$($SourceOrg_PAT)"

         $env:AZURE_DEVOPS_EXT_PAT | az devops login --organization $sourceOrganization

         $Error.clear();

         az artifacts universal download --organization $sourceOrganization --project="$($sourceProjectName)" --scope $sourceScope --feed $sourceFeedName --name $packageName --version $packageVersion --path $downloadPath --verbose

         $packagePath = $downloadPath + "\" + $packageName

         if($Error.Count -gt 0)
         {    
            foreach($err in $Error)
            {
                WriteLog($err.exception)
                Write-Host $err.exception
            }   
         }
         else
         {
            if(Test-Path -Path $packagePath + ".zip")
            {
                WriteLog("Package " + $packageName + " is downloaded with version " + $packageVersion + " at: " + $packagePath)
                $downloadedPackagesList.Add($packageName + "_" + $packageVersion);
                $d = $d + 1

            }
            elseif(Test-Path -Path $packagePath)
            {
            
                WriteLog("Package " + $packageName + " is downloaded with version " + $packageVersion + " at: " + $packagePath)
                $downloadedPackagesList.Add($packageName + "_" + $packageVersion);
                $d = $d + 1
            
            }                            
         }

         az devops logout --organization $sourceOrganization

         $env:AZURE_DEVOPS_EXT_PAT = ""

         # Publish Package to Destination Feed

         $env:AZURE_DEVOPS_EXT_PAT = "$($DestinationOrg_PAT)"

         $env:AZURE_DEVOPS_EXT_PAT | az devops login --organization $destinationOrganization

         $Error.clear();

         Write-Host "Uploading below package to $($destinationFeedName) Feed" 

         Write-Host "Package: " $packageName

         Write-Host "Version: " $packageVersion

         Write-Host ""

         az artifacts universal publish --organization $destinationOrganization --project="$($destinationProjectName)" --scope $destinationScope --feed $destinationFeedName --name $packageName --version $packageVersion --path $downloadPath --verbose
         
         if($Error.Count -gt 0)
         {    
            foreach($err in $Error)
            {
                WriteLog($err.exception)
                Write-Host $err.exception
            }   
         }
         else
         {
         
         $len = $destinationOrganization.Length - 22

         $Organization = $destinationOrganization.Substring(22, $($len)).Trim("/")

         $Response = ""

         $Url = "https://pkgs.dev.azure.com/$($Organization)/$($destinationProjectName)/_apis/packaging/feeds/$($destinationFeedName)/upack/packages/$($packageName)/versions/$($packageVersion)?api-version=6.0-preview.1";

         Write-Host "Initialize authentication context" -ForegroundColor Yellow

         $Token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$DestinationOrg_PAT"))

         $Header = @{authorization = "Basic $Token"}

         try {

         $Response = Invoke-RestMethod -Uri $url -Headers $Header -Method Get -ErrorAction Stop | ConvertTo-Json | ConvertFrom-Json


         } catch {

                if($_.ErrorDetails.Message) {


                            WriteLog($_.ErrorDetails.Message)
                            Write-Host "Error : $_.ErrorDetails.Message"


                    } else {

                        Write-Host $_
                        WriteLog($_)
                    }

         }

         if($Response.name -match $packageName -and $Response.version -match $packageVersion) 
         {
                WriteLog("Package " + $packageName + " is uploaded with version " + $packageVersion + " at: " + $destinationFeedName)

                Write-Host "Package " + $packageName + " is uploaded with version " + $packageVersion + " at: " + $destinationFeedName
                $uploadedPackagesList.Add($packageName + "_" + $packageVersion);
                $Response = ""
                $Url = ""
                $Token = ""
                $u = $u + 1
        
         }
         else
         {
 
             WriteLog("Package upload failed " + $packageName + " with version " + $packageVersion + " at: " + $destinationFeedName)

             Write-Host "Package upload failed " + $packageName + " with version " + $packageVersion + " at: " + $destinationFeedName

         }
                            
         }

         az devops logout --organization $destinationOrganization

         $env:AZURE_DEVOPS_EXT_PAT = ""

        }

        $t = $t + 1


    }
}
    
$jsonBase.Add("Downloaded Package List", $downloadedPackagesList)
$jsonBase.Add("Uploadeded Package List", $uploadedPackagesList)
$jsonBase.Add("Package Already Exists", $packagesExistsList)

Get-Content -Path $metaFileReleasePath | Out-File $metaFileReleaseJson 

if($jsonBase)
{
$jsonBase | ConvertTo-Json | Out-File $outputFile
}
else
{
Write-Host "No Data in jsonBase variable"
}

if(Test-Path -Path $LogFilePath)
{
Get-Content -Path $LogFilePath | Out-File $outlogFile

Write-Host "Logs"
Get-Content -path $logFilePath
}
else
{
Write-Host "No Log file found!"
}

WriteLog ("`nFollowing packages are downloaded")
foreach($downloadedPackage in $downloadedPackagesList)
{
    WriteLog($downloadedPackage)
}

Write-Host ""

WriteLog ("`nFollowing packages are uploaded")
foreach($uploadedPackage in $uploadedPackagesList)
{
    WriteLog($uploadedPackage)
}

Write-Host ""

WriteLog ("`nFollowing packages are already exists")
foreach($packageExist in $packagesExistsList)
{
    WriteLog($packageExist)
}

if($d -eq $u)
{
$du = $u
}

$r = $t - $du

if ($LastExitCode -ne 0) {

  if($downloadedPackagesList.Count -eq $uploadedPackagesList.Count)
  {
  Write-Host "All packages are downloaed and uploaded successfully."
  Write-Host "Script executed successfully with error!"
  exit 0
  }
  
  if($r -eq $e)
  {
  Write-Host "$($du) Packages are downloaded and uploaded out of total $($t) packages, remaining below $($r) packages are already exists in $($destinationOrganization)'s $($destinationFeedName) Feed"
  foreach($packageExist in $packagesExistsList)
  {
    Write-Host $packageExist
  }
  Write-Host "Script executed successfully with error!"
  exit 0
  }

  if($t -eq $e)
  {
  Write-Host "No new packages are available."
  Write-Host "Script executed successfully with error!"
  exit 0
  }
  
}
else
{
Write-Host "Script executed successfully!"
}
