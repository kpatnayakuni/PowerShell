# Create a VM
# Create a Identity
# Create a KeyVault
# Add a Secret
# Add Reader IAM role on Azure KeyVault to Identity
# Add Get Permissions to Secrets on Azure KeyVault to Identity
# Enable User Assigned Managed Indentity to VM
# Test access on the VM in which UAMI enabled

Select-AzSubscription -SubscriptionName 'Kiran Lab Subscription'

$RGName = 'Test-RG'
$Location = 'westus'
$null = New-AzResourceGroup -Name $RGName -Location $Location

$VMName = 'Test-VM'
$UserName = 'sysadmin'
$PlainTextPassword = 'P@ssw0rd!'
$SecurePassword = $PlainTextPassword | ConvertTo-SecureString -AsPlainText -Force
$Credential = [pscredential]::new($UserName, $SecurePassword)
$VM = New-AzVM -ResourceGroupName $RGName -Name $VMName -Location $Location -Credential $Credential

Import-Module -Name Az.ManagedServiceIdentity

$IdentityName = 'amuai'
$Identity = New-AzUserAssignedIdentity -Name $IdentityName -ResourceGroupName $RGName -Location $Location

$KeyVaultName = 'testakv99'
$KeyVault = New-AzKeyVault -ResourceGroupName $RGName -Name $KeyVaultName -Location $Location

Set-AzKeyVaultSecret -VaultName $KeyVaultName -Name BadPassword -SecretValue $SecurePassword

New-AzRoleAssignment -ApplicationId $Identity.ClientId -RoleDefinitionName Reader -Scope $KeyVault.ResourceId

Set-AzKeyVaultAccessPolicy -ResourceGroupName $RGName -VaultName $KeyVaultName -ServicePrincipalName $Identity.ClientId -PermissionsToSecrets get

Update-AzVM -ResourceGroupName $RGName -VM $VM -IdentityType UserAssigned -IdentityID $Identity.Id

# On the VM in which UAMI enabled
Login-AzAccount -Identity
Get-AzKeyVaultSecret -VaultName testakv99 -Name BadPassword | Select-Object -ExpandProperty SecretValueText