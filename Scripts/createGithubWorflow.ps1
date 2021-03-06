[CmdletBinding()]
param (
  [parameter(Mandatory=$true)]
  $RingInfo,
  [parameter(Mandatory=$true)]
  [string]$Token
  ) 

# Creating Github WorkFlow for POH Service Deployment

$RingInfo = "$($RingInfo)" | ConvertFrom-Json

foreach($ring in $RingInfo)
{

$ymlFilePath = $ring.name + "_Service_Deployment.yml"
$ringFilePath = $ring.name + "_Ring.yml"
$regionFilePath = $ring.name + "_Region.yml"
$locationFilePath = $ring.name + "_Location.yml"
$envTypesFilePath = $ring.name + "_envTypes.yml"
$envsFilePath = $ring.name + "_Envs.yml"

New-Item -Path $ringFilePath -ItemType File -Force
New-Item -Path $regionFilePath -ItemType File -Force
New-Item -Path $locationFilePath -ItemType File -Force
New-Item -Path $envTypesFilePath -ItemType File -Force
New-Item -Path $envsFilePath -ItemType File -Force

Add-Content -Path $ymlFilePath -Value "name: $($ring.name) POH Services Deployment"
Add-Content -Path $ymlFilePath -Value "on:"
Add-Content -Path $ymlFilePath -Value "   workflow_dispatch:"
Add-Content -Path $ymlFilePath -Value ""
Add-Content -Path $ymlFilePath -Value "jobs:"

Write-Host $ring.name

Add-Content -Path $ringFilePath -Value "   $($ring.name):"
Add-Content -Path $ringFilePath -Value "      runs-on: ubuntu-latest"
Add-Content -Path $ringFilePath -Value "      environment: 'poh-services-prod-ring0'"
Add-Content -Path $ringFilePath -Value "      steps:"
Add-Content -Path $ringFilePath -Value "         - run: echo `"$($ring.name) Approved`""
Add-Content -Path $ringFilePath -Value ""

Write-Host "Ring: " $ring.displayName
Write-Host "-----------------------------------------"


    foreach($region in $ring.regions)
    {

    Add-Content -Path $regionFilePath -Value "   $($region.name):"
    Add-Content -Path $regionFilePath -Value "      runs-on: ubuntu-latest"
    Add-Content -Path $regionFilePath -Value "      needs: $($ring.name)"
    Add-Content -Path $regionFilePath -Value "      steps:"
    Add-Content -Path $regionFilePath -Value "         - run: echo `"$($region.name)_Region Approved`""
    Add-Content -Path $regionFilePath -Value ""

    Write-Host "region: " $region.displayName
    Write-Host "Depends On: " $ring.displayName
    Write-Host "-----------------------------------------"


        foreach($location in $region.locations)
        {

        Add-Content -Path $locationFilePath -Value "   $($location.name):"
        Add-Content -Path $locationFilePath -Value "      runs-on: ubuntu-latest"
        Add-Content -Path $locationFilePath -Value "      needs: $($region.name)"
        Add-Content -Path $locationFilePath -Value "      steps:"
        Add-Content -Path $locationFilePath -Value "         - run: echo `"$($location.name)_Location Approved`""
        Add-Content -Path $locationFilePath -Value ""

        Write-Host "Location: " $location.displayName
        Write-Host "Depends On: " $region.displayName

            foreach($envType in $location.envTypes)
            {

            Add-Content -Path $envTypesFilePath -Value "   $($envType.name):"
            Add-Content -Path $envTypesFilePath -Value "      runs-on: ubuntu-latest"
            Add-Content -Path $envTypesFilePath -Value "      needs: $($location.name)"
            Add-Content -Path $envTypesFilePath -Value "      steps:"
            Add-Content -Path $envTypesFilePath -Value "         - run: echo `"$($envType.name) Approved`""
            Add-Content -Path $envTypesFilePath -Value ""

            Write-Host "envTypes: " $envType.displayName
            Write-Host "Depends On: " $location.displayName

                foreach($env in $envType.envs)
                {

                $appDomainAccount = $env.appDomainAccount
                $pos = $appDomainAccount.IndexOf("\")
                $leftPart = $appDomainAccount.Substring(0, $pos)
                $rightPart = $appDomainAccount.Substring($pos+1)
                $appDomainAccount = $leftPart + "\\" + $rightPart

                Add-Content -Path $envsFilePath -Value "   $($env.name):"
                Add-Content -Path $envsFilePath -Value "    uses: ./.github/workflows/deployment-template_prod.yml"
                Add-Content -Path $envsFilePath -Value "    needs: $($envType.name)"
                Add-Content -Path $envsFilePath -Value "    with:"
                Add-Content -Path $envsFilePath -Value "      ringLevel: `"$($ring.name)`""
                Add-Content -Path $envsFilePath -Value "      serviceHost: `"$($env.serviceHost)`""
                Add-Content -Path $envsFilePath -Value "      appDomainAccount: `"$($appDomainAccount)`""
                Add-Content -Path $envsFilePath -Value "      envName: `"$($env.envName)`""
                Add-Content -Path $envsFilePath -Value "      HWSServer: `"$($env.HWSServer)`""
                Add-Content -Path $envsFilePath -Value "      HCServer: `"$($env.HCServer)`""
                Add-Content -Path $envsFilePath -Value "      approvalStageEnv: `"$($env.approvalStageEnv)`""
                Add-Content -Path $envsFilePath -Value "      POHTenantID: `"$($env.POHTenantID)`""
                Add-Content -Path $envsFilePath -Value "      IDNTenantID: `"$($env.IDNTenantID)`""
                Add-Content -Path $envsFilePath -Value "      POHBASEURL: `"$($env.POHBASEURL)`""
                Add-Content -Path $envsFilePath -Value "      envCode: `"$($env.environmentCode)`""
                Add-Content -Path $envsFilePath -Value "      clientName: `"$($env.clientName)`""
                Add-Content -Path $envsFilePath -Value "      clientEnvName: `"$($env.environment)`""
                Add-Content -Path $envsFilePath -Value "      metajsonfile: `"poh-services-metadata.json`""
                Add-Content -Path $envsFilePath -Value "      AppsToDeploy: `"DeployAll`""
                Add-Content -Path $envsFilePath -Value "      SDRM: `$False"
                Add-Content -Path $envsFilePath -Value "      isRestore: `$False"
                Add-Content -Path $envsFilePath -Value "      DevopsKeyVault: `"poh-0-durable-kv`""
                Add-Content -Path $envsFilePath -Value "      GlobalKeyVault: `"poh-0-global-kv`""
                Add-Content -Path $envsFilePath -Value "      HCPhysicalPath: `"C:\\Program Files (x86)\\Allscripts Sunrise\\Helios\\8.7\\HeliosConnect`""
                Add-Content -Path $envsFilePath -Value "      HWSPhysicalPath: `"C:\\Program Files (x86)\\Allscripts Sunrise\\POH`""
                Add-Content -Path $envsFilePath -Value "      EnterpriseMangerPath: `"C:\\Program Files (x86)\\Allscripts Sunrise\\Enterprise Manager`""
                Add-Content -Path $envsFilePath -Value "      VirtualConnectionPath: `"HeliosConnect/87`""
                Add-Content -Path $envsFilePath -Value "    secrets:"
                Add-Content -Path $envsFilePath -Value "      AZURE_DEVOPS_PAT_TOKEN: `${{ secrets.AZURE_DEVOPS_PAT_TOKEN }}"
                Add-Content -Path $envsFilePath -Value ""

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

    Get-Content -Path $ringFilePath | Add-Content -Path $ymlFilePath
    Get-Content -Path $regionFilePath | Add-Content -Path $ymlFilePath
    Get-Content -Path $locationFilePath | Add-Content -Path $ymlFilePath
    Get-Content -Path $envTypesFilePath | Add-Content -Path $ymlFilePath
    Get-Content -Path $envsFilePath | Add-Content -Path $ymlFilePath

    Remove-Item -Path $ringFilePath -Force
    Remove-Item -Path $regionFilePath -Force
    Remove-Item -Path $locationFilePath -Force
    Remove-Item -Path $envTypesFilePath -Force
    Remove-Item -Path $envsFilePath -Force


    # Get SHA for service_deployment.yml file to delete from repo

    $uri="https://api.github.com/repos/jayeshkumarpatel2611/MyApp/contents/.github/workflows/$($ymlFilePath)"

    try {

    $WebObj = Invoke-WebRequest -Uri $uri -Headers $headers -Method Get -ErrorAction Stop

    $WebObj = $WebObj.Content | ConvertFrom-Json

    $SHA = $WebObj.sha

    # Delete Old Service Deployment Github WorkFlow

    $headers = @{"Accept"="application/json"; "Authorization"="bearer $Token"}

    $payload = @{ "ref"="refs/heads/master"; "message" = "Deleting Github WorkFlow -> $($ymlFilePath) to create new one"; "sha" = "$($SHA)"  }

    $body = $payload | ConvertTo-Json

    $uri="https://api.github.com/repos/jayeshkumarpatel2611/MyApp/contents/.github/workflows/$($ymlFilePath)"

    try {

    $WebObj = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing -Body $body -Method Delete -ErrorAction Stop

    Write-Host "$($ymlFilePath) old workflow is deleted successfully!" -ForegroundColor Green

    }
    catch {

    Write-Host "Failed to delete $($ymlFilePath) old workflow!" -ForegroundColor Red

    Write-Host "Error: $($_)" -ForegroundColor Yellow 

    }

    }
    catch {

    Write-Host "Failed to get SHA for $($ymlFilePath) workflow!" -ForegroundColor Red

    Write-Host "Error: $($_)" -ForegroundColor Yellow 

    }

    # Upload Created Github WorkFlow for deploying POH Service.

    try {

    $content = [convert]::ToBase64String((Get-Content -Path "$($ymlFilePath)" -Encoding byte))
    $headers = @{"Accept"="application/json"; "Authorization"="bearer $Token"}
    $payload = @{ "ref"="refs/heads/main"; "message" = "New POH Service Deployment Github WorkFlow - $($ymlFilePath)"; "content" = "$($content)"  }
    $body = $payload | ConvertTo-Json
    $uri="https://api.github.com/repos/jayeshkumarpatel2611/MyApp/contents/.github/workflows/$($ymlFilePath)"
    
    $WebObj = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing -Body $body -Method Put -ErrorAction Stop

    Write-Host "$($ymlFilePath) workflow created and uploaded successfully!" -ForegroundColor Green

    Remove-Item -Path $ymlFilePath -Force

    
    # Dispatching Created POS Service Deployment Workflow

    $headers = @{"Accept"="application/json"; "Authorization"="bearer $Token"}

    $payload = @{ "ref"="refs/heads/master" }

    $body = $payload | ConvertTo-Json

    $uri="https://api.github.com/repos/jayeshkumarpatel2611/MyApp/actions/workflows/$($ymlFilePath)/dispatches"

    try {

    $WebObj = Invoke-WebRequest -Uri $uri -Headers $headers -UseBasicParsing -Body $body -Method POST -ErrorAction Stop

    Write-Host "$($ymlFilePath) workflow dispatched successfully!" -ForegroundColor Green

    }
    catch {

    Write-Host "Failed to dispatch $($ymlFilePath) workflow!" -ForegroundColor Red

    Write-Host "Error: $($_)" -ForegroundColor Yellow 

    }

    }
    catch {

    Write-Host "Failed to upload $($ymlFilePath) workflow!" -ForegroundColor Red

    Write-Host "Error: $($_)" -ForegroundColor Yellow 

    }


}
