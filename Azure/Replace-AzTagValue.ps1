$KeyName = 'Department'
$NewKeyValue = "IT"
$Resources = Get-AzResource | Where-Object {$_.Tags.Keys -eq $KeyName}
foreach ($Resource in $Resources) 
{
    $Tags = $Resource.Tags
    $Tags.Remove($KeyName)
    $Tags.Add($KeyName,$NewKeyValue)
    $Resource | Set-AzResource -Tag $Tags -Force
}