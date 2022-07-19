[CmdletBinding()]
param (
  [parameter(Mandatory=$true)]
  $RingInfo,
  [parameter(Mandatory=$true)]
  [string]$Token
  ) 

# Creating Github WorkFlow for POH Service Deployment

$JSONObject = @{}

Write-Host "RingInfo:"

$RingInfo

$JSONObject = "$($RingInfo)" | ConvertFrom-Json

$ymlFilePath = "Ring0.yml" 

New-Item -Path $ymlFilePath -ItemType File -Force

Add-Content -Path $ymlFilePath -Value 'name: Ring0 POH Services Deployment'
Add-Content -Path $ymlFilePath -Value 'on:'
Add-Content -Path $ymlFilePath -Value '   workflow_dispatch:'
Add-Content -Path $ymlFilePath -Value ''
Add-Content -Path $ymlFilePath -Value 'jobs:'


# Ring

foreach($ring in $JSONObject)
{

Write-Host $ring.name

Add-Content -Path $ymlFilePath -Value "   $($ring.name):"
Add-Content -Path $ymlFilePath -Value "      runs-on: ubuntu-latest"
Add-Content -Path $ymlFilePath -Value "      environment: 'poh-services-prod-ring0'"
Add-Content -Path $ymlFilePath -Value "      steps:"
Add-Content -Path $ymlFilePath -Value "         - run: echo `"$($ring.name) Approved`""
Add-Content -Path $ymlFilePath -Value ''

Write-Host "Ring: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($region in $JSONObject.regions)
{

Write-Host "region: " $region.displayName
Write-Host "Depends On: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($location in $JSONObject.regions.locations)
{

Write-Host "Location: " $location.displayName
Write-Host "Depends On: " $region.displayName

foreach($envType in $location.envTypes)
{

Write-Host "envTypes: " $envType.displayName
Write-Host "Depends On: " $location.displayName

}

}

}

}


# Regions

foreach($ring in $JSONObject)
{

Write-Host $ring.name

Write-Host "Ring: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($region in $JSONObject.regions)
{

Add-Content -Path $ymlFilePath -Value "   $($region.name):"
Add-Content -Path $ymlFilePath -Value "      runs-on: ubuntu-latest"
Add-Content -Path $ymlFilePath -Value "      needs: $($ring.name)"
Add-Content -Path $ymlFilePath -Value "      steps:"
Add-Content -Path $ymlFilePath -Value "         - run: echo `"$($region.name)_Region Approved`""
Add-Content -Path $ymlFilePath -Value ''

Write-Host "region: " $region.displayName
Write-Host "Depends On: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($location in $JSONObject.regions.locations)
{

Write-Host "Location: " $location.displayName
Write-Host "Depends On: " $region.displayName

foreach($envType in $location.envTypes)
{

Write-Host "envTypes: " $envType.displayName
Write-Host "Depends On: " $location.displayName

}

}

}

}


# Locations

foreach($ring in $JSONObject)
{

Write-Host $ring.name

Write-Host "Ring: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($region in $JSONObject.regions)
{

Write-Host "region: " $region.displayName
Write-Host "Depends On: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($location in $JSONObject.regions.locations)
{

Add-Content -Path $ymlFilePath -Value "   $($location.name):"
Add-Content -Path $ymlFilePath -Value "      runs-on: ubuntu-latest"
Add-Content -Path $ymlFilePath -Value "      needs: $($region.name)"
Add-Content -Path $ymlFilePath -Value "      steps:"
Add-Content -Path $ymlFilePath -Value "         - run: echo `"$($location.name)_Location Approved`""
Add-Content -Path $ymlFilePath -Value ''

Write-Host "Location: " $location.displayName
Write-Host "Depends On: " $region.displayName

foreach($envType in $location.envTypes)
{

Add-Content -Path $ymlFilePath -Value "   $($envType.name):"
Add-Content -Path $ymlFilePath -Value "      runs-on: ubuntu-latest"
Add-Content -Path $ymlFilePath -Value "      needs: $($location.name)"
Add-Content -Path $ymlFilePath -Value "      steps:"
Add-Content -Path $ymlFilePath -Value "         - run: echo `"$($envType.name) Approved`""
Add-Content -Path $ymlFilePath -Value ''

Write-Host "envTypes: " $envType.displayName
Write-Host "Depends On: " $location.displayName

}

}

}

}

# Environment Types

foreach($ring in $JSONObject)
{

Write-Host $ring.name

Write-Host "Ring: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($region in $JSONObject.regions)
{

Write-Host "region: " $region.displayName
Write-Host "Depends On: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($location in $JSONObject.regions.locations)
{

Write-Host "Location: " $location.displayName
Write-Host "Depends On: " $region.displayName

foreach($envType in $location.envTypes)
{

Add-Content -Path $ymlFilePath -Value "   $($envType.name):"
Add-Content -Path $ymlFilePath -Value "      runs-on: ubuntu-latest"
Add-Content -Path $ymlFilePath -Value "      needs: $($location.name)"
Add-Content -Path $ymlFilePath -Value "      steps:"
Add-Content -Path $ymlFilePath -Value "         - run: echo `"$($envType.name) Approved`""
Add-Content -Path $ymlFilePath -Value ''

Write-Host "envTypes: " $envType.displayName
Write-Host "Depends On: " $location.displayName

}

}

}

}

foreach($ring in $JSONObject)
{

Write-Host "Ring: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($region in $JSONObject.regions)
{

Write-Host "region: " $region.displayName
Write-Host "Depends On: " $ring.displayName
Write-Host "-----------------------------------------"


foreach($location in $JSONObject.regions.locations)
{

Write-Host "Location: " $location.displayName
Write-Host "Depends On: " $region.displayName

foreach($envType in $location.envTypes)
{

Write-Host "envType: " $envType.displayName
Write-Host "Depends On: " $location.displayName


foreach($env in $location.envTypes.envs)
{

Add-Content -Path $ymlFilePath -Value "   $($env.name):"
Add-Content -Path $ymlFilePath -Value "    uses: ./.github/workflows/deployment-template_prod.yml"
Add-Content -Path $ymlFilePath -Value "    needs: $($envTypes.name)"
Add-Content -Path $ymlFilePath -Value "    with:"
Add-Content -Path $ymlFilePath -Value "      ringLevel: `"$($ring.name)`""
Add-Content -Path $ymlFilePath -Value "      serviceHost: `"$($env.serviceHost)`""
Add-Content -Path $ymlFilePath -Value "      appDomainAccount: `"$($env.appDomainAccount)`""
Add-Content -Path $ymlFilePath -Value "      envName: `"$($env.envName)`""
Add-Content -Path $ymlFilePath -Value "      HWSServer: `"$($env.HWSServer)`""
Add-Content -Path $ymlFilePath -Value "      HCServer: `"$($env.HCServer)`""
Add-Content -Path $ymlFilePath -Value "      approvalStageEnv: `"$($env.approvalStageEnv)`""
Add-Content -Path $ymlFilePath -Value "      POHTenantID: `"$($env.POHTenantID)`""
Add-Content -Path $ymlFilePath -Value "      IDNTenantID: `"$($env.IDNTenantID)`""
Add-Content -Path $ymlFilePath -Value "      POHBASEURL: `"$($env.POHBASEURL)`""
Add-Content -Path $ymlFilePath -Value "      envCode: `"$($env.environmentCode)`""
Add-Content -Path $ymlFilePath -Value "      clientName: `"$($env.clientName)`""
Add-Content -Path $ymlFilePath -Value "      clientEnvName: `"$($env.environment)`""
Add-Content -Path $ymlFilePath -Value "      metajsonfile: `"poh-services-metadata.json`""
Add-Content -Path $ymlFilePath -Value "      AppsToDeploy: `"DeployAll`""
Add-Content -Path $ymlFilePath -Value "      SDRM: `$False"
Add-Content -Path $ymlFilePath -Value "      isRestore: `$False"
Add-Content -Path $ymlFilePath -Value "      DevopsKeyVault: `"poh-0-durable-kv`""
Add-Content -Path $ymlFilePath -Value "      GlobalKeyVault: `"poh-0-global-kv`""
Add-Content -Path $ymlFilePath -Value "      HCPhysicalPath: `"C:\\Program Files (x86)\\Allscripts Sunrise\\Helios\\8.7\\HeliosConnect`""
Add-Content -Path $ymlFilePath -Value "      HWSPhysicalPath: `"C:\\Program Files (x86)\\Allscripts Sunrise\\POH`""
Add-Content -Path $ymlFilePath -Value "      EnterpriseMangerPath: `"C:\\Program Files (x86)\\Allscripts Sunrise\\Enterprise Manager`""
Add-Content -Path $ymlFilePath -Value "      VirtualConnectionPath: `"HeliosConnect/87`""
Add-Content -Path $ymlFilePath -Value "    secrets:"
Add-Content -Path $ymlFilePath -Value "      AZURE_DEVOPS_PAT_TOKEN: `${{ secrets.AZURE_DEVOPS_PAT_TOKEN }}"
Add-Content -Path $ymlFilePath -Value ''

Write-Host "Environment Type        : " $env.displayName
Write-Host "approvalStageEnv        : " $env.approvalStageEnv
Write-Host "environmentResourceGroup: " $env.environmentResourceGroup
Write-Host "environment             : " $env.environment
Write-Host "environmentCode         : " $env.environmentCode
Write-Host "Depends On              : " $envType.name
Write-Host "------------------------------------------"

}


}

}

}


}

# Upload Created Github WorkFlow for deploying POH Service.

$content = [convert]::ToBase64String((Get-Content -Path "$($ymlFilePath)" -Encoding byte))

$headers = @{"Accept"="application/json"; "Authorization"="bearer $Token"}

$payload = @{ "ref"="refs/heads/main"; "message" = "New Service Deployment Github WorkFlow"; "content" = "$($content)"  }
$body = $payload | ConvertTo-Json
$uri="https://api.github.com/repos/jayeshkumarpatel2611/MyApp/contents/.github/workflows/Ring0.yml"

$WebObj = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing -Body $body -Method Put

if($WebObj.StatusCode -eq "201" -and $WebObj.StatusDescription -eq "Created")
{

Write-Host "service_deployment.yml workflow created and uploaded successfully!" -ForegroundColor Green

}
