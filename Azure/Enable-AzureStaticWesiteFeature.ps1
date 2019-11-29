#requires -Module Az

## Ensure logged into your Azure account
if([string]::IsNullOrEmpty($(Get-AzContext)))
{ Add-AzAccount }

## Define the required variables 
$SubscriptionId     = '<SubscriptionId>'    # This is your subscription id (ex: 'f34d6539-c45b-4a93-91d9-0b4e6ffb6030')
$ResourceGroupName  = 'static-websites-rg'  # Resource Group
$Location           = 'southindia'          # Location
$StorageAccountName = 'staticwebsitesa999'  # Storage Account
$WebpagePath        = "C:\wwwroot\"         # Static website files

## Select the required subscription, in case there multiple subscriptions
Select-AzSubscription -Subscription $SubscriptionId

## Select/Create Azure resource group
# Parameters
$ParamList = @{
    Name    = $ResourceGroupName
    Location= $Location
}
# Create the resource group if it doesn't exist
$ResourceGroup = Get-AzResourceGroup @ParamList -ErrorAction SilentlyContinue
if ($null -eq $ResourceGroup) { New-AzResourceGroup @ParamList }

## Select/Create storage account
# Parameters
$ParamTable = @{
    Name              = $StorageAccountName
    ResourceGroupName = $ResourceGroupName
}
# Create the storage account if it doesn't exist
$StorageAccount = Get-AzStorageAccount @ParamTable -ErrorAction SilentlyContinue
if ($null -eq $StorageAccount)
{
    $ParamTable.Location    = $Location
    $ParamTable.SkuName     = 'Standard_LRS'
    $ParamTable.Kind        = 'StorageV2'
    $ParamTable.AccessTier  = 'Hot' 
    New-AzStorageAccount @ParamTable
}

## Paramaters required to use with storage Cmdlets
$ParamTable = @{
    Name              = $StorageAccountName
    ResourceGroupName = $ResourceGroupName
}

## Set the storage account to enable the static website feature
Set-AzCurrentStorageAccount @ParamTable

## Enable the static website feature for the selected storage account
# Ensure the documents are created with the names mentioned 
Enable-AzStorageStaticWebsite -IndexDocument "index.html" -ErrorDocument404Path "error.html"

## Upload the website pages to the azure blob container
Get-ChildItem -Path $WebpagePath -Recurse | Set-AzStorageBlobContent -Container '$web'

## Verify the files uploaded to the azure blob container
Get-AzStorageContainer -Name '$web' | Get-AzStorageBlob

## Retrieve the public URL to access the static website
(Get-AzStorageAccount @ParamTable).PrimaryEndpoints.Web

## Add custom domain to your static website, but need to add CNAME record in your domain dns server
Set-AzStorageAccount @ParamTable -CustomDomainName "www.yourdomain.com" -UseSubDomain $True