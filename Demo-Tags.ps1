#requires -Module Az

# Connect-AzAccount

### Add new tags to an existing resource

# Get the resource
[Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource] $Resource = Get-AzResource -Name testvm -ResourceGroupName test-rg

# Resource tags
[hashtable] $Tags = $Resource.Tags

# Ensure not to overwrite the tags
if ($null -eq $Tags) {
    [hashtable] $Tags = @{Type="VM"; Environment="Test"} }
else {
    $Tags += @{Type="VM"; Environment="Test"} }

# Add new tags to the resource (-Force to override the confirmation if there are any existing tags)
Set-AzResource -ResourceId $Resource.Id -Tag $Tags -Force


### Remove an existing tag / remove all tags from a resource

# Get the resource
[Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource] $Resource = Get-AzResource -Name testvm -ResourceGroupName test-rg

# Resource tags
[hashtable] $Tags = $Resource.Tags

# Remove the specific tag
$Tags.Remove("Type")

# Overwrite the remaing tags to the resource (-Force to override the confirmation if there are any existing tags)
Set-AzResource -ResourceId $Resource.Id -Tag $Tags -Force

## Remove all tags
Set-AzResource -ResourceId $Resource.Id -Tag @{} -Force


### List all the resources with a specific tag key
Get-AzResource -TagName "Environment"

### List all the resources with a specific tag value
Get-AzResource -TagValue "Test"

### List all the resources with a specific tag key and value
Get-AzResource -Tag @{Environment="Test"}

### List all the tags and number of resources associated in a subscription.
Get-AzTag