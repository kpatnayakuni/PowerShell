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

Get-AzADGroup -SearchString Az