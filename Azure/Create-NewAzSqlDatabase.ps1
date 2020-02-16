# Import required modules
$requiredModules = @('AzTable', 'Az.Resources', 'Az.KeyVault', 'Az.Sql')
Import-Module $requiredModules

# Deployment meta data
$subscriptionName = 'Kiran Test Subscription'
$storageAccountRG = 'info-rg'
$storageAccountName = 'infosa'
$storageAccountTableName = 'data'
$partitionKey = 'sqlmeta'
$rowKey = 1
$keyVaultName = 'kts-test-kv'
$ipApiUrl = 'https://api.ipify.org?format=json'

# If not logged in then login to Azure account 
if (-not(Get-AzContext)) { Connect-AzAccount -SubscriptionName $subscriptionName }

# If not the desired subscription then set the required subscription
if ((Get-AzContext).Subscription.Name -ne $subscriptionName) { Set-AzContext -SubscriptionName $subscriptionName }

# Retrieve the required parameter values from Azure Table Storage
$storageAccount = Get-AzStorageAccount -ResourceGroupName $storageAccountRG -Name $storageAccountName
$storageTable = Get-AzStorageTable -Name $storageAccountTableName -Context $storageAccount.Context
$sqlMeta = Get-AzTableRow -Table $storageTable.CloudTable -PartitionKey $partitionKey -RowKey $rowKey

# Resource Group Name
$resourceGroupName = $sqlMeta.rgName

# Location
$location = $sqlMeta.location

# Set an admin login and password for your server
$adminSqlLogin = $sqlMeta.userName
$password = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $adminSqlLogin | ForEach-Object SecretValue
$sqlCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $password

# Active Directory Sql Admin
$activeDirectorySqlAdmin = $sqlMeta.activeDirectorySqlAdmin

# Set server name - the logical server name has to be unique in the system
$serverName = @($sqlMeta.sqlServerName, $(Get-Random)) -join ''

# The sample database name
$databaseName = $sqlMeta.sqlDBName

# Allow your IP to access sql server, if you want to allow from all ips then specity '0.0.0.0' to Start and End Ips
$allowedIp = Invoke-RestMethod -Method Get -Uri $ipApiUrl | ForEach-Object ip

# Create a resource group
$null = New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create a server with a system wide unique server name
$sqlServer = New-AzSqlServer -ResourceGroupName $resourceGroupName -ServerName $serverName -Location $location -SqlAdministratorCredentials $sqlCredential

# Create a server firewall rule that allows access from the specified IP range
$null = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName -ServerName $serverName -FirewallRuleName "SqlAllowedIPs" -StartIpAddress $allowedIp -EndIpAddress $allowedIp

# Create a blank database with an S0 performance level
$null = New-AzSqlDatabase  -ResourceGroupName $resourceGroupName -ServerName $serverName -DatabaseName $databaseName -RequestedServiceObjectiveName "S0" -SampleName "AdventureWorksLT"

# Add Active Directory user as a SQL Admin
$null = Set-AzSqlServerActiveDirectoryAdministrator -ResourceGroupName $resourceGroupName -ServerName $serverName -DisplayName $activeDirectorySqlAdmin

# Print Sql Server FQDN to connect to the server
Write-Host ("Connect SQL Server using {0}:1433" -f $sqlServer.FullyQualifiedDomainName)

# Clean up deployment 
# Remove-AzResourceGroup -ResourceGroupName $resourceGroupName