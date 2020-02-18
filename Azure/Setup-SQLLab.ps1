Get-AzContext
Set-AzContext -SubscriptionName 'Kiran Lab Subscription'

$force = $true
$WarningPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

$networkResourceGroup = @{ name = 'network-rg'; location = 'centralus' }
$storageResourceGroup = @{ name = 'storage-rg'; location = 'centralus' }
$securityResourceGroup = @{ name = 'security-rg'; location = 'centralus' }
$computeResourceGroup = @{ name = 'compute-rg'; location = 'centralus' }

@( $networkResourceGroup, $storageResourceGroup, $securityResourceGroup, $computeResourceGroup ) | ForEach-Object { $null = New-AzResourceGroup @_ -Force:$force }

$domainNetwork = @{ 
    vNet   = @{ name = 'dc-vnet'; resourceGroupName = $networkResourceGroup.name; location = 'centralus'; addressPrefix = '10.10.0.0/16' }
    subnet = @( @{ name = 'domain'; addressPrefix = '10.10.1.0/24' } )
}

$sqlANetwork = @{
    vNet   = @{ name = 'sql-a-vnet'; resourceGroupName = $networkResourceGroup.name; location = 'eastus'; addressPrefix = '10.20.0.0/16' }
    subnet = @( @{ name = 'sqlserver-x'; addressPrefix = '10.20.1.0/24' }, @{ name = 'sqlserver-y'; addressPrefix = '10.20.2.0/24' } )
}

$sqlBNetwork = @{
    vNet   = @{ name = 'sql-b-vnet'; resourceGroupName = $networkResourceGroup.name; location = 'westus'; addressPrefix = '10.30.0.0/16' }
    subnet = @( @{ name = 'sqlserver-z'; addressPrefix = '10.30.1.0/24' } )
}

$workstationNetwork = @{ 
    vNet   = @{ name = 'ws-vnet'; resourceGroupName = $networkResourceGroup.name; location = 'eastus2'; addressPrefix = '10.40.0.0/16' }
    subnet = @( @{ name = 'client'; addressPrefix = '10.40.1.0/24' } )
}

$Networks = @( $domainNetwork, $sqlANetwork, $sqlBNetwork, $workstationNetwork ) 
$Networks | ForEach-Object { 
    $_.vNet.subnet = $_.subnet | ForEach-Object { New-AzVirtualNetworkSubnetConfig @_ }
    $_.virtualNetwork = $_.vNet | ForEach-Object { New-AzVirtualNetwork @_ -Force:$force }
}

0 .. $($Networks.Count - 1) | ForEach-Object {
    $virtualNetwork = $Networks[$_].virtualNetwork
    $Networks | Select-Object -Skip $($_ + 1) | ForEach-Object {
        $null = Add-AzVirtualNetworkPeering -Name ("{0}-{1}" -f $virtualNetwork.name.Replace('-',''), $_.vNet.name.Replace('-','')) -VirtualNetwork $virtualNetwork -RemoteVirtualNetworkId $_.virtualNetwork.id
        $null = Add-AzVirtualNetworkPeering -Name ("{1}-{0}" -f $virtualNetwork.name.Replace('-',''), $_.vNet.name.Replace('-','')) -VirtualNetwork $_.virtualNetwork -RemoteVirtualNetworkId $virtualNetwork.id
    }
}





