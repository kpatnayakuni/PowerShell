# Exit the execution as a script 
return 

# List all the available RBAC roles
Get-AzRoleDefinition 

# Trim the list and display Name and Description of all the availble RBAC roles 
Get-AzRoleDefinition | Select-Object Name, Description

# Get a specific role
Get-AzRoleDefinition 'Reader'

# Get the actins of a specific role
Get-AzRoleDefinition 'SQL Server Contributor' | Select-Object -ExpandProperty Actions


# List all the role assignments in a subscription
Get-AzRoleAssignment

# List role assignments for a user
Get-AzRoleAssignment -SignInName kiran@patnayakuni.in 

# List all the role assignments at a resource group scope
Get-AzRoleAssignment -ResourceGroupName lab-rg

# List all the role assignments at a subscription scope
Get-AzRoleAssignment -Scope /subscriptions/<subscription_id>

# List role assignments for classic service administrator and co-administrator
Get-AzRoleAssignment -IncludeClassicAdministrators

# List all the azure AD users
Get-AzADUser

# List a specific user/group
Get-AzADUser -StartsWith "<search string>"
Get-AzADUser -DisplayName "<User DisplayName>"
Get-AzADUser -UserPrincipalName "<User Principal Name>"

Get-AzADGroup -SearchString "<group search string>"
Get-AzADServicePrincipal -SearchString "<service principal>"

# Create a role assignment for a user at a resource group scope
New-AzRoleAssignment -SignInName "<email_or_userprincipalname>" -RoleDefinitionName "<role_name>" -ResourceGroupName "<resource_group_name>"

# Create a role assignment for a group at a resource scope
New-AzRoleAssignment -ObjectId "<object_id>" -RoleDefinitionName "<role_name>" -ResourceName "<resource_name>" -ResourceType "<resource_type>" -ResourceGroupName "<resource_group_name>"
# -ObjectId is group id, and get the id using Get-AzADGroup CmdLet.

# Create a role assignment for an application at a subscription scope
New-AzRoleAssignment -ObjectId "<application_id>" -RoleDefinitionName "<role_name>" -Scope "/subscriptions/<subscription_id>"

# Remove the role assignment from the user on resource group scope
Remove-AzRoleAssignment -SignInName user@domain.com -RoleDefinitionName "Virtual Machine Contributor" -ResourceGroupName lab-rg

# Remove the role from a group at a subscription scope.
Remove-AzRoleAssignment -ObjectId "<object_id>" -RoleDefinitionName "<role_name>" -Scope "/subscriptions/<subscription_id>"
# -ObjectId is group id, and get the id using Get-AzADGroup CmdLet.