
## Assign Reader role to a user on all the subscriptions 
Get-AzSubscription | %{ New-AzRoleAssignment -SignInName user@yourdomain.com -RoleDefinitionName Reader -Scope /subscriptions/$($_.SubscriptionId) }