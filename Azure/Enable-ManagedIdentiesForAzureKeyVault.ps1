## Create a new Virtual Machine
## Create a Managed Identity
## Create a Key Vault
## Add a secret to Key Vault
## Grant Reader IAM role on Key Vault to Managed Identity
## Grant access policy to Managed Identity on Key Vault to get the secrets from
## Enable User Assigned Managed Identity on Virtual Machine
## Test the access on the Virtual Machine

# To avoid accidental F5
return

# Create a Resource Group
$rgName = 'Test-RG'
$location = 'westus'
$null = New-AzResourceGroup -Name $rgName -Location $location

# Create a Virtual Machine
$vmName = 'Test-VM'
$userName = 'sysadmin'
$plainTextPassword = 'P@ssw0rd!'
$securePassword = $plainTextPassword | ConvertTo-SecureString -AsPlainText -Force
$credential = [pscredential]::new($userName, $securePassword)
$vm = New-AzVM -ResourceGroupName $rgName -Name $vmName `
                -Location $location -Credential $credential

# Install and Import the module
$moduleName = 'Az.ManagedServiceIdentity'
Install-Module -Name $moduleName -Force
Import-Module -Name $moduleName

# Create User Assugned Managed Identity
$identityName = 'amuai'
$identity = New-AzUserAssignedIdentity -Name $identityName `
                                        -ResourceGroupName $rgName -Location $location

# Create Azure Key Vault
$keyVaultName = 'testakv99'
$keyVault = New-AzKeyVault -ResourceGroupName $rgName `
                            -Name $keyVaultName -Location $location

# Add a secret to Key Vault
$null = Set-AzKeyVaultSecret -VaultName $keyVaultName `
                            -Name $userName -SecretValue $securePassword

# Grant Reader role to Managed Identity on Key Vault
$null = New-AzRoleAssignment -ApplicationId $identity.ClientId `
                            -RoleDefinitionName Reader -Scope $keyVault.ResourceId

# Grant GET permissions to secrets on Key Key Vault to managed identity
Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName `
                            -ServicePrincipalName $identity.ClientId -PermissionsToSecrets get

# Assign the identity and enable User Assigned Managed Identity on Virtual Machine.
$null = Update-AzVM -ResourceGroupName $rgName -VM $vm `
                    -IdentityType UserAssigned -IdentityID $identity.Id

# Get the public ip of the new VM
$vmPIP = Get-AzPublicIpAddress -ResourceGroupName $rgName -Name $vmName | % IpAddress

## On the NEW VM in which User Assigned Managed Identity enabled
# Enter-PSSession -ComputerName $vmPIP -Credential $credential

# Install NuGet package where Az module is availble 
Install-PackageProvider -Name NuGet -Force

# Install the Az module
Install-Module -Name Az -Force

# Login to Azure with managed identity
Login-AzAccount -Identity

# Get the secret from the Key Vault
$kvName = 'testakv99'
$keyName = 'sysadmin'
Get-AzKeyVaultSecret -VaultName $kvName -Name $keyName | ForEach-Object SecretValueText