# Login-AzAccount
# Get-AzContext
# Select-AzSubscription

$ResourceGroupName  = 'demo-rg'
$Location           = 'westus'
$SANamePrefix       = 'demosa'
$StorageAccountName = ($SANamePrefix, -join ((0x30..0x39) + ( 0x61..0x7A) | Get-Random -Count 8  | foreach {[char]$_})) -join ''
$Tags               = @{Env = 'Test'; Purpose = 'Demo'}
$SAContainerName    = 'scripts'
#$ScriptFile         = 'C:\Users\kiran\OneDrive\Projects\Git Repos\PowerShell\Windows\Sample-Inventory.ps1'
[string] $Script = [scriptblock]::Create({
    Get-Service | Out-File -FilePath C:\Windows\Temp\Log.txt
}).ToString()

$ScriptFile = [System.IO.Path]::GetTempFileName()

Set-Content -Path $ScriptFile -Value $Script
# $SABlobName         = Split-Path -Path $ScriptFile -Leaf
# $ExtensionName      = Split-Path -Path $ScriptFile -LeafBase
$SABlobName         = 'GetService.ps1'
$ExtensionName      = 'GetService'

$VMResourceGroupName= 'learning-rg'
$VMName             = 'learning-vm'
$VM                 = Get-AzVM -ResourceGroupName $VMResourceGroupName -Name $VMName

$ExtensionParameters= @{
    Name                = $VM.Extensions.Name
    ResourceGroupName   = $VMResourceGroupName
    VMName              = $VMName
}

$IsCustomExtExists  = Get-AzVMCustomScriptExtension @ExtensionParameters -ErrorAction SilentlyContinue
if ($IsCustomExtExists)
{ Remove-AzVMCustomScriptExtension @ExtensionParameters -Force }

$CommonParamaters   = @{
    ResourceGroupName = $ResourceGroupName
    Location        = $Location
    Tags            = $Tags
}

$ResourceGroup      = New-AzResourceGroup @CommonParamaters -Force

$SAParameters       = @{
    Name            = $StorageAccountName
    SkuName         = 'Standard_LRS'
    Kind            = 'StorageV2'
    AccessTier      = 'Hot'
}

$SAParameters += $CommonParamaters

$StorageAccount     = New-AzStorageAccount @SAParameters
$SAContext          = $StorageAccount.Context

$SAContainer        = New-AzStorageContainer -Name $SAContainerName -Context $SAContext 
$SABlob             = Set-AzStorageBlobContent -File $ScriptFile -Container $SAContainerName -Blob $SABlobName -Context $SAContext
$SAKeys             = Get-AzStorageAccountKey -Name $StorageAccount.StorageAccountName -ResourceGroupName $ResourceGroupName
$SAKey              = $($SAKeys)[0].Value

$SetVMExtParameters = @{
    Name                = $ExtensionName
    VMObject            = $VM
    Location            = $VM.Location
    ContainerName       = $SAContainerName
    FileName            = $SABlobName
    StorageAccountName  = $StorageAccount.StorageAccountName
    StorageAccountKey   = $SAKey
    TypeHandlerVersion  = 1.1
    ErrorAction         = 'Stop'
}

Set-AzVMCustomScriptExtension @SetVMExtParameters



$SqlResourceGroupName = 'sql-rg'
$SqlLocation = 'westus'
$SqlServerName = 'sqlserver20191208'
$SqlDatabaseName = 'Inventory'
$PlanPassword   = 'SqlServer@2016'
$SecurePassword = $PlanPassword | ConvertTo-SecureString -AsPlainText -Force
$SqlCredentials = [pscredential]::new('sqladmin',$SecurePassword)

$SqlResourceGroup = New-AzResourceGroup -Name $SqlResourceGroupName -Location $SqlLocation
$SqlServer = New-AzSqlServer -ResourceGroupName $SqlResourceGroupName -Location $SqlLocation -ServerName $SqlServerName -SqlAdministratorCredentials $SqlCredentials
$SqlDatabase = New-AzSqlDatabase -ResourceGroupName $SqlResourceGroupName -ServerName $SqlServer.ServerName -DatabaseName $SqlDatabaseName




