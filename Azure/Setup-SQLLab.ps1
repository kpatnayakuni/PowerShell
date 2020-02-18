Get-AzContext
Set-AzContext -SubscriptionName 'Kiran Lab Subscription'

$force = $true
$WarningPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

$networkResourceGroup = @{ name = 'network-rg'; location = 'centralus' }
$storageResourceGroup = @{ name = 'storage-rg'; location = 'centralus' }
$securityResourceGroup = @{ name = 'security-rg'; location = 'centralus' }
$computeResourceGroup = @{ name = 'compute-rg'; location = 'centralus' }

$resourceGroups = @( $networkResourceGroup, $storageResourceGroup, $securityResourceGroup, $computeResourceGroup ) 
$resourceGroups | ForEach-Object { $null = New-AzResourceGroup @_ -Force:$force }

$domainNetwork = @{ 
    vNet   = @{ name = 'dc-vnet'; location = 'centralus'; addressPrefix = '10.10.0.0/16' }
    subnet = @( @{ name = 'domain'; addressPrefix = '10.10.1.0/24' } )
}

$sqlANetwork = @{
    vNet   = @{ name = 'sql-a-vnet'; location = 'eastus'; addressPrefix = '10.20.0.0/16' }
    subnet = @( @{ name = 'sqlserver-x'; addressPrefix = '10.20.1.0/24' }, @{ name = 'sqlserver-y'; addressPrefix = '10.20.2.0/24' } )
}

$sqlBNetwork = @{
    vNet   = @{ name = 'sql-b-vnet'; location = 'westus'; addressPrefix = '10.30.0.0/16' }
    subnet = @( @{ name = 'sqlserver-z'; addressPrefix = '10.30.1.0/24' } )
}

$workstationNetwork = @{ 
    vNet   = @{ name = 'ws-vnet'; location = 'eastus2'; addressPrefix = '10.40.0.0/16' }
    subnet = @( @{ name = 'client'; addressPrefix = '10.40.1.0/24' } )
}

$networks = @( $domainNetwork, $sqlANetwork, $sqlBNetwork, $workstationNetwork ) 
$networks | ForEach-Object { 
    $_.vNet.subnet = $_.subnet | ForEach-Object { New-AzVirtualNetworkSubnetConfig @_ }
    $_.virtualNetwork = $_.vNet | ForEach-Object { New-AzVirtualNetwork @_ -ResourceGroupName $networkResourceGroup.name -Force:$force }
}

0 .. $($networks.Count - 1) | ForEach-Object {
    $virtualNetwork = $Networks[$_].virtualNetwork
    $Networks | Select-Object -Skip $($_ + 1) | ForEach-Object {
        $peeringSplat1 = @{
            Name                   = ("{0}-{1}" -f $virtualNetwork.name.Replace('-', ''), $_.vNet.name.Replace('-', '')) 
            VirtualNetwork         = $virtualNetwork 
            RemoteVirtualNetworkId = $_.virtualNetwork.id
        }
        $null = Add-AzVirtualNetworkPeering @peeringSplat1
        $peeringSplat2 = @{
            Name                   = ("{1}-{0}" -f $virtualNetwork.name.Replace('-', ''), $_.vNet.name.Replace('-', '')) 
            VirtualNetwork         = $_.virtualNetwork 
            RemoteVirtualNetworkId = $virtualNetwork.id
        }
        $null = Add-AzVirtualNetworkPeering $peeringSplat2
    }
}

$rdpRuleConfig = @{
    Name                     = "Allow_RDP" 
    Protocol                 = 'Tcp'
    Direction                = 'Inbound'
    Priority                 = 3389
    SourceAddressPrefix      = '*'
    SourcePortRange          = '*'
    DestinationAddressPrefix = '*' 
    DestinationPortRange     = 3389 
    Access                   = 'Allow'
}
$rdpRule = New-AzNetworkSecurityRuleConfig @rdpRuleConfig

$sqlRuleConfig = @{
    Name                     = "Allow_SqlServer" 
    Protocol                 = 'Tcp'
    Direction                = 'Inbound'
    Priority                 = 1433
    SourceAddressPrefix      = '*'
    SourcePortRange          = '*'
    DestinationAddressPrefix = '*' 
    DestinationPortRange     = 1433 
    Access                   = 'Allow'
}
$sqlRule = New-AzNetworkSecurityRuleConfig @sqlRuleConfig

$denyInternetRuleConfig = @{
    Name                     = "Deny_Internet" 
    Protocol                 = '*'
    Direction                = 'Outbound'
    Priority                 = 4096
    SourceAddressPrefix      = '*'
    SourcePortRange          = '*'
    DestinationAddressPrefix = 'Internet' 
    DestinationPortRange     = '*'
    Access                   = 'Deny'
}
$denyInternetRule = New-AzNetworkSecurityRuleConfig @denyInternetRuleConfig

$dcNSG = @{ name = 'dc-nsg'; location = 'centralus'; SecurityRules = @( $denyInternetRule ) }
$sqlANSG = @{ name = 'sql-a-nsg'; location = 'eastus'; SecurityRules = @( $denyInternetRule, $sqlRule ) }
$sqlBNSG = @{ name = 'sql-b-nsg'; location = 'westus'; SecurityRules = @( $denyInternetRule, $sqlRule ) }
$workstationNSG = @{ name = 'ws-nsg'; location = 'eastus2'; SecurityRules = @( $rdpRule ) }

$nsgs = @( $dcNSG, $sqlANSG, $sqlBNSG, $workstationNSG ) 
$nsgs | ForEach-Object { $_.NSG = New-AzNetworkSecurityGroup @_ -ResourceGroupName $securityResourceGroup.name -Force:$force }

$domainNetwork.virtualNetwork.Subnets[0].NetworkSecurityGroup = $dcNSG.NSG
$sqlANetwork.virtualNetwork.Subnets[0].NetworkSecurityGroup = $sqlANSG.NSG
$sqlANetwork.virtualNetwork.Subnets[1].NetworkSecurityGroup = $sqlANSG.NSG
$sqlBNetwork.virtualNetwork.Subnets[0].NetworkSecurityGroup = $sqlBNSG.NSG
$workstationNetwork.virtualNetwork.Subnets[0].NetworkSecurityGroup = $workstationNSG.NSG

$networks | ForEach-Object { $null = Set-AzVirtualNetwork -VirtualNetwork $_.virtualNetwork }

$dcsa = @{ name = ("dc01{0}sa" -f (Get-Random)); location = 'centralus' }
$sqlasa = @{ name = ("sqla{0}sa" -f (Get-Random)); location = 'eastus' }
$sqlbsa = @{ name = ("sqlb{0}sa" -f (Get-Random)); location = 'westus' }
$wssa = @{ name = ("ws{0}sa" -f (Get-Random)); location = 'eastus2' }

$storageAccounts = @( $dcsa, $sqlasa, $sqlbsa, $wssa )

$saSplat = @{
    resourceGroupName = $storageResourceGroup.name
    skuName           = 'Standard_LRS'
    Kind              = 'StorageV2'
}

$storageAccounts | ForEach-Object { $_.storageAccount = New-AzStorageAccount @_ @saSplat }