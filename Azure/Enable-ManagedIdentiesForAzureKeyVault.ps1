# Create a VM
# Create a Identity
# Create a KeyVault
# Add a Secret
# Add Reader IAM role on Azure KeyVault to Identity
# Add Get Permissions to Secrets on Azure KeyVault to Identity
# Enable User Assigned Managed Indentity to VM
# Test access on the VM in which UAMI enabled

return
$rgName = 'Test-RG'
$location = 'westus'
$null = New-AzResourceGroup -Name $rgName -Location $location

$vmName = 'Test-VM'
$userName = 'sysadmin'
$plainTextPassword = 'P@ssw0rd!'
$securePassword = $plainTextPassword | ConvertTo-SecureString -AsPlainText -Force
$credential = [pscredential]::new($userName, $securePassword)
$vm = New-AzVM -ResourceGroupName $rgName -Name $vmName -Location $location -Credential $credential

$vmPIP = Get-AzPublicIpAddress -ResourceGroupName $rgName -Name $vmName | ForEach-Object IpAddress

$moduleName = 'Az.ManagedServiceIdentity'
Install-Module -Name $moduleName -Force
Import-Module -Name $moduleName

$identityName = 'amuai'
$identity = New-AzUserAssignedIdentity -Name $identityName -ResourceGroupName $rgName -Location $location

$keyVaultName = 'testakv99'
$keyVault = New-AzKeyVault -ResourceGroupName $rgName -Name $keyVaultName -Location $location

$null = Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $userName -SecretValue $securePassword

$null = New-AzRoleAssignment -ApplicationId $identity.ClientId -RoleDefinitionName Reader -Scope $keyVault.ResourceId

Set-AzKeyVaultAccessPolicy -ResourceGroupName $rgName -VaultName $keyVaultName -ServicePrincipalName $identity.ClientId -PermissionsToSecrets get

$null = Update-AzVM -ResourceGroupName $rgName -VM $vm -IdentityType UserAssigned -IdentityID $identity.Id

# On the VM in which UAMI enabled
Enter-PSSession -ComputerName $vmPIP -Credential $credential
Install-PackageProvider -Name NuGet -Force
Install-Module -Name Az -Force
Login-AzAccount -Identity
$kvName = 'testakv99'
$uName = 'sysadmin'
Get-AzKeyVaultSecret -VaultName $kvName -Name $uName | ForEach-Object SecretValueText