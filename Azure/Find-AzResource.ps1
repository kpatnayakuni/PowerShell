<#
.SYNOPSIS
    Find-AzResource gets all the Azure tagged/not tagged resources,
.DESCRIPTION
    Find-AzResource gets all the Azure resources with...
    > All tags
    > No tags
    > Specific tag name(s)
    > Specific tag value(s) 
    > Specific tag(s) 
    ... from one or more resourcegroup(s) or subscripttion(s) and optionally filter the resources by location, name and type as well. 
.EXAMPLE
    Find-AzResource

    Displays full help
.EXAMPLE
    Find-AzResource -SubscriptionName Sub1, Sub2 -AllTagged

    Finds all the resources with tags in the given Subscriptions. it even works with ResourceGroupName as well.
    Optionally, you can even filter the resources by Name, Location and Type.
.EXAMPLE
    Find-AzResource -SubscriptionName Sub1, Sub2 -WithNoTag

    Finds all the resources with no tags in the given Subscriptions. It even works with ResourceGroupName as well.
    Optionally, you can even filter the resources by Name, Location and Type.
.EXAMPLE
    Find-AzResource -ResourceGroupName RG1, RG2 -TagName Status
    
    Finds all the resources with given tag name in the given resource groups. It even works with the subscriptions as well.
    Optionally, you can even filter the resources by Name, Location and Type.
.EXAMPLE
    Find-AzResource -ResourceGroupName RG1, RG2 -TagValue HR, Finance

    Finds all the resources with given tag values in the given resource groups. It even works with the subscriptions as well.
    Optionally, you can even filter the resources by Name, Location and Type.
.EXAMPLE
    Find-AzResource -ResourceGroupName RG1, RG2 -Tag @{Dept='IT'; Status="Expired"}

    Finds all the resources with given tags in the given resource groups. It even works with the subscriptions as well.
    Optionally, you can even filter the resources by Name, Location and Type.
.INPUTS
    Inputs (if any)
.OUTPUTS
    Azure Resource Object(s)
.NOTES
    Find-AzResource gets all the Azure resources with...
    > All tags
    > No tags
    > Specific tag name(s)
    > Specific tag value(s) 
    > Specific tag(s) 
    ... from one or more resourcegroup(s) or subscripttion(s) and optionally filter the resources by location, name and type as well. 
#>

Function Find-AzResource
{
    [CmdletBinding(DefaultParameterSetName = 'Help')]
    [Alias('Search-AzResource')]
    param 
    (
        # Resource Group Name(s)
        [Parameter(Mandatory = $true, ParameterSetName = 'AllInRg')]
        [Parameter(Mandatory = $true, ParameterSetName = 'NoTagInRg')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TNInRg')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TVInRg')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TagInRg')]
        [string[]] $ResourceGroupName,

        # Subscription Name(s)
        [Parameter(Mandatory = $true, ParameterSetName = 'AllInSub')]
        [Parameter(Mandatory = $true, ParameterSetName = 'NoTagInSub')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TNInSub')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TVInSub')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TagInSub')]
        [Alias('SubscriptionId')]
        [string[]]$SubscriptionName,

        # By Resource Name
        [Parameter(Mandatory = $false)]
        [string[]] $ResourceName,

        # By Location
        [Parameter(Mandatory = $false)]
        [string[]] $Location,

        # By Resource Type
        [Parameter(Mandatory = $false)]
        [string[]] $ResourceType,

        # All tagged resources
        [Parameter(Mandatory = $true, ParameterSetName = 'AllInRg')]
        [Parameter(Mandatory = $true, ParameterSetName = 'AllInSub')]
        [switch] $AllTagged,

        # Not tagged resources
        [Parameter(Mandatory = $true, ParameterSetName = 'NoTagInRg')]
        [Parameter(Mandatory = $true, ParameterSetName = 'NoTagInSub')]
        [switch] $WithNoTag,

        # By Tag Name(s)
        [Parameter(Mandatory = $true, ParameterSetName = 'TNInRg')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TNInSub')]
        [string[]] $TagName,

        # By Tag Value(s)
        [Parameter(Mandatory = $true, ParameterSetName = 'TVInRg')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TVInSub')]
        [string[]] $TagValue,

        # By Tag(s)
        [Parameter(Mandatory = $true, ParameterSetName = 'TagInRg')]
        [Parameter(Mandatory = $true, ParameterSetName = 'TagInSub')]
        [hashtable] $Tag
    )

    if ($PSCmdlet.ParameterSetName -eq "Help")
    {
        Get-Help $MyInvocation.InvocationName -Full
        return
    }

    # Get current subscription
    $CurrentSubscription = Get-AzContext

    # Initialise an empty resource array
    $Resources = @()

    ## Get all the resources from the given resourcegroup(s)/subscription(s). 
    
    # ParameterSet matching with 'Rg' (resourcegroup)
    if ($PSCmdlet.ParameterSetName -like "*Rg")
    {
        # Gets resources from one or more resourcegroups
        foreach ($RGName in $ResourceGroupName)
        {
            $Resources += Get-AzResource -ResourceGroupName $RGName   
        }

    }

    # ParameterSet matching with 'Sub' (subscription)
    if ($PSCmdlet.ParameterSetName -like "*Sub")
    {
        # Get resources from one or more subscriptions
        foreach ($SName in $SubscriptionName)
        {
            $null = Select-AzSubscription -Subscription $SName
            $ResourceGroupName = Get-AzResourceGroup | ForEach-Object ResourceGroupName
            foreach ($RGName in $ResourceGroupName)
            {
                $Resources += Get-AzResource -ResourceGroupName $RGName   
            }
        }
        $null = Select-AzSubscription -Subscription $CurrentSubscription.Subscription.Name
    }
    

    # If no location is provided then consider all the locations of the resources by default to query the resources
    if (-not $Location)
    {
        $Location = $Resources.Location
    }

    # Same as location, if the resource type is not provided then consider all the resource types
    if (-not $ResourceType)
    {
        $ResourceType = $Resources.ResourceType
    }

    # If the resource name is not provided then consider all the resource names else filter the resources with the given name(s)
    $RNames += if (-not $ResourceName)
    {
        $Resources.ResourceName
    }
    else
    {
        foreach ($RName in $ResourceName)
        {
            $Resources | Where-Object { $_.ResourceName -like $RName } | ForEach-Object ResourceName
        }
    }
    
    # Splating: custom expression to get only the subscription id from the resources
    $SubscriptionId = @{
        Name       = "SubscriptionId"
        Expression = {
            $_.ResourceId.Split('/')[2]
        }
    }

    # $InputObject = @{
    #     Name       = "InputObject"
    #     Expression = { $_ }
    # }

    # Get all the tagged resources with all the applicable filters
    $AllTagedResources = $Resources | Where-Object { 
        $_.Tags.Count -gt 0 -and $_.Location -in $Location -and $_.ResourceType -in $ResourceType -and $_.ResourceName -in $RNames
    } | Select-Object -Property ResourceName, ResourceGroupName, ResourceType, Location, Tags, $SubscriptionId, ResourceId  #, $InputObject

    # Get all the resources with no tags
    $NotTaggedResources = $Resources | Where-Object { $_.Tags.Count -eq 0 }

    # Return all the resources with `-AllTagged` switch
    if ($PSCmdlet.ParameterSetName -like "AllIn*")
    {
        return $AllTagedResources
    }

    # Return all the not tagged resources with `-WithNoTag` switch
    if ($PSCmdlet.ParameterSetName -like "NoTagIn*")
    {
        return $NotTaggedResources
    }

    # Return all the resources with specific tag name(s) with `-TagName` parameter
    if ($PSCmdlet.ParameterSetName -like "TNIn*")
    {
        $ResourcesWithSpecificTagName = @()
        foreach ($TN in $TagName)
        {
            $ResourcesWithSpecificTagName += $AllTagedResources | Where-Object { $_.Tags.Keys.Contains($TN) }
        }
        return $ResourcesWithSpecificTagName
    }
    
    # Return all the resources with specific tag value(s) with `-TagValue` parameter
    if ($PSCmdlet.ParameterSetName -like "TVIn*")
    {
        $ResourcesWithSpecificTagValue = @()
        foreach ($TV in $TagValue)
        {
            $ResourcesWithSpecificTagValue += $AllTagedResources | Where-Object { $_.Tags.Values.Contains($TV) }
        }
        return $ResourcesWithSpecificTagValue
    }

    # Return all the resources with specific tag(s) with `-Tag` parameter
    if ($PSCmdlet.ParameterSetName -like "TagIn*")
    {
        $ResourcesWithSpecificTag = @()
        foreach ($T in $Tag.GetEnumerator())
        {
            $ResourcesWithSpecificTag += $AllTagedResources | Where-Object { $_.Tags.Keys.Contains($T.Key) -and $_.Tags.Values.Contains($T.Value) }
        }
        return $ResourcesWithSpecificTag
    }
}