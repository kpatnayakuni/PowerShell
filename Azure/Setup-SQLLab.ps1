Get-AzContext
Set-AzContext -SubscriptionName 'Kiran Lab Subscription'

$force = $true
$WarningPreference = [System.Management.Automation.ActionPreference]::SilentlyContinue

$dcMeta = @{ 
    prefix            = 'dc'
    location          = 'centralus'
    vNetAddressPrefix = '10.10.0.0./16'
    subnet            = @( @{ name = 'domain'; subnetAddressPrefix = '10.10.1.0/24' } )
    vmSize            = 'Standard_DS1_v2'
    SourceImage       = @{ publisherName = 'MicrosoftWindowsServer'; offer = 'WindowsServer'; skus = '2019-Datacenter'; version = 'latest' }
}

$sqlMeta = @{
    prefix      = 'sql'
    sqlA        = @{
        prefix            = 'sql-a'
        location          = 'eastus'
        vNetAddressPrefix = '10.20.0.0./16'
        subnet            = @( 
            @{ name = 'sqlnet-x'; subnetAddressPrefix = '10.20.1.0/24' }, 
            @{ name = 'sqlnet-y'; subnetAddressPrefix = '10.20.2.0/24' }
        )
    }
    sqlB        = @{
        prefix            = 'sql-b'
        location          = 'westus'
        vNetAddressPrefix = '10.30.0.0./16'
        subnet            = @( @{ name = 'sqlnet-z'; subnetAddressPrefix = '10.30.1.0/24' } )
    }
    vmSize      = 'Standard_DS1_v2'
    SourceImage = @{ publisherName = 'MicrosoftWindowsServer'; offer = 'WindowsServer'; skus = '2019-Datacenter'; version = 'latest' }
}

$wsMeta = @{ 
    prefix            = 'ws'
    location          = 'eastus2'
    vNetAddressPrefix = '10.40.0.0./16'
    subnet            = @( @{ name = 'client'; subnetAddressPrefix = '10.40.1.0/24' } )
    vmSize            = 'Standard_F2'
    SourceImage       = @{ publisherName = 'MicrosoftWindowsDesktop'; offer = 'Windows-10'; skus = '19h2-pro-g2'; version = 'latest' }
}

$networkResourceGroupName = 'network-rg'
$storageResourceGroupName = 'storage-rg'
$securityResourceGroupName = 'security-rg'
$computeResourceGroupName = 'compute-rg'
$rgLocation = 'centralus'

$rgNames = @( $networkResourceGroupName, $storageResourceGroupName, $securityResourceGroupName, $computeResourceGroupName ) 
$rgNames | ForEach-Object { $null = New-AzResourceGroup -Name $_ -Location $rgLocation -Force:$force }

$domainNetwork = @{ 
    vNet   = @{ name = "$($dcMeta.prefix)-vnet"; location = $dcMeta.location; addressPrefix = $dcMeta.vNetAddressPrefix }
    subnet = @( @{ name = $dcMeta.subnet[0].name; addressPrefix = $dcMeta.subnet[0].subnetAddressPrefix } )
}

$sqlANetwork = @{
    vNet   = @{ name = "$($sqlMeta.sqlA.prefix)-vnet"; location = $sqlMeta.sqlA.location; addressPrefix = $sqlMeta.sqlA.vNetAddressPrefix }
    subnet = @( 
        @{ name = $sqlMeta.sqlA.subnet[0].name; addressPrefix = $sqlMeta.sqlA.subnet[0].subnetAddressPrefix }, 
        @{ name = $sqlMeta.sqlA.subnet[1].name; addressPrefix = $sqlMeta.sqlA.subnet[1].subnetAddressPrefix }
    )
}

$sqlBNetwork = @{
    vNet   = @{ name = "$($sqlMeta.sqlB.prefix)-vnet"; location = $sqlMeta.sqlB.location; addressPrefix = $sqlMeta.sqlB.vNetAddressPrefix }
    subnet = @( @{ name = $sqlMeta.sqlB.subnet[0].name; addressPrefix = $sqlMeta.sqlB.subnet[0].subnetAddressPrefix } )
}

$workstationNetwork = @{ 
    vNet   = @{ name = "$($wsMeta.prefix)-vnet"; location = $wsMeta.location; addressPrefix = $wsMeta.vNetAddressPrefix }
    subnet = @( @{ name = $wsMeta.subnet[0].name; addressPrefix = $wsMeta.subnet[0].subnetAddressPrefix } )
}

$networks = @( $domainNetwork, $sqlANetwork, $sqlBNetwork, $workstationNetwork ) 
$networks | ForEach-Object { 
    $_.vNet.subnet = $_.subnet | ForEach-Object { New-AzVirtualNetworkSubnetConfig @_ }
    $_.virtualNetwork = $_.vNet | ForEach-Object { New-AzVirtualNetwork @_ -ResourceGroupName $networkResourceGroupName -Force:$force }
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

$dcNSG = @{ name = "$($dcMeta.prefix)-nsg"; location = $dcMeta.location; SecurityRules = @( $denyInternetRule ) }
$sqlANSG = @{ name = "$($sqlMeta.sqlA.prefix)-nsg"; location = $sqlMeta.sqlA.location; SecurityRules = @( $denyInternetRule, $sqlRule ) }
$sqlBNSG = @{ name = "$($sqlMeta.sqlB.prefix)-nsg"; location = $sqlMeta.sqlB.location; SecurityRules = @( $denyInternetRule, $sqlRule ) }
$workstationNSG = @{ name = "$($wsMeta.prefix)-nsg"; location = $wsMeta.location; SecurityRules = @( $rdpRule ) }

$nsgs = @( $dcNSG, $sqlANSG, $sqlBNSG, $workstationNSG ) 
$nsgs | ForEach-Object { $_.NSG = New-AzNetworkSecurityGroup @_ -ResourceGroupName $securityResourceGroupName -Force:$force }

$domainNetwork.virtualNetwork.Subnets[0].NetworkSecurityGroup = $dcNSG.NSG
$sqlANetwork.virtualNetwork.Subnets[0].NetworkSecurityGroup = $sqlANSG.NSG
$sqlANetwork.virtualNetwork.Subnets[1].NetworkSecurityGroup = $sqlANSG.NSG
$sqlBNetwork.virtualNetwork.Subnets[0].NetworkSecurityGroup = $sqlBNSG.NSG
$workstationNetwork.virtualNetwork.Subnets[0].NetworkSecurityGroup = $workstationNSG.NSG

$networks | ForEach-Object { $null = Set-AzVirtualNetwork -VirtualNetwork $_.virtualNetwork }

$dcsa = @{ name = ("{0}{1}{2}" -f $($dcMeta.prefix.Replace('-', '')), (Get-Random), 'sa'); location = $dcMeta.location }
$sqlasa = @{ name = ("{0}{1}{2}" -f $($sqlMeta.sqlA.prefix.Replace('-', '')), (Get-Random), 'sa'); location = $sqlMeta.sqlA.location }
$sqlbsa = @{ name = ("{0}{1}{2}" -f $($sqlMeta.sqlB.prefix.Replace('-', '')), (Get-Random), 'sa'); location = $sqlMeta.sqlB.location }
$wssa = @{ name = ("{0}{1}{2}" -f $($wsMeta.prefix.Replace('-', '')), (Get-Random), 'sa'); location = $wsMeta.location }

$storageAccounts = @( $dcsa, $sqlasa, $sqlbsa, $wssa )

$saSplat = @{
    resourceGroupName = $storageResourceGroup.name
    skuName           = 'Standard_LRS'
    Kind              = 'StorageV2'
}

$storageAccounts | ForEach-Object { $_.storageAccount = New-AzStorageAccount @_ @saSplat }

$adminCredentials = [pscredential]::new('sysadmin', $(ConvertTo-SecureString -AsPlainText -String "P@ssw0rd!" -Force))

$dcConfig = @{
    vmConfig           = @{ vmName = "$($dcMeta.prefix)01"; vmSize = $dcMeta.vmSize }
    sourceImage        = $dcMeta.SourceImage
    nicConfig          = @{ 
        resourceGroupName = $computeResourceGroupName
        nicName           = "$($dcMeta.prefix)01-nic"
        subnetId          = $domainNetwork.virtualNetwork.Subnets[0].id
        location          = $dcMeta.location 
    }
    storageAccountName = $dcsa.name
    licenseType        = 'Windows_Server'
    adminCredentials   = $adminCredentials
}

$sqlAxConfig = @{
    vmConfig           = @{ vmName = "$($sqlMeta.prefix)-x"; vmSize = $sqlMeta.vmSize }
    sourceImage        = $sqlMeta.SourceImage
    nicConfig          = @{ 
        resourceGroupName = $computeResourceGroupName
        nicName           = "$($sqlMeta.prefix)-x-nic"
        subnetId          = $sqlANetwork.virtualNetwork.Subnets[0].id
        location          = $sqlMeta.sqlA.location 
    }
    storageAccountName = $sqlasa.name
    licenseType        = 'Windows_Server'
    adminCredentials   = $adminCredentials
}

$sqlAyConfig = @{
    vmConfig           = @{ vmName = "$($sqlMeta.prefix)-y"; vmSize = $sqlMeta.vmSize }
    sourceImage        = $sqlMeta.SourceImage
    nicConfig          = @{ 
        resourceGroupName = $computeResourceGroupName
        nicName           = "$($sqlMeta.prefix)-y-nic"
        subnetId          = $sqlANetwork.virtualNetwork.Subnets[1].id
        location          = $sqlMeta.sqlA.location 
    }
    storageAccountName = $sqlasa.name
    licenseType        = 'Windows_Server'
    adminCredentials   = $adminCredentials
}

$sqlBzConfig = @{
    vmConfig           = @{ vmName = "$($sqlMeta.prefix)-z"; vmSize = $sqlMeta.vmSize }
    sourceImage        = $sqlMeta.SourceImage
    nicConfig          = @{ 
        resourceGroupName = $computeResourceGroupName
        nicName           = "$($sqlMeta.prefix)-z-nic"
        subnetId          = $sqlBNetwork.virtualNetwork.Subnets[0].id
        location          = $sqlMeta.sqlB.location 
    }
    storageAccountName = $sqlbsa.name
    licenseType        = 'Windows_Server'
    adminCredentials   = $adminCredentials
}

$wsConfig = @{
    vmConfig           = @{ vmName = "$($wsMeta.prefix)01"; vmSize = $wsMeta.vmSize }
    sourceImage        = $wsMeta.SourceImage
    nicConfig          = @{
        resourceGroupName = $computeResourceGroupName
        nicName           = "$($wsMeta.prefix)01-nic"
        subnetId          = $workstationNetwork.virtualNetwork.Subnets[0].id
        location          = $wsMeta.location 
    }
    storageAccountName = $wssa.name
    licenseType        = 'Windows_Client'
    adminCredentials   = $adminCredentials
    pipAddressName     = "$($wsMeta.prefix)01-pip"
}

$vmConfiguration = @( $dcConfig, $sqlAxConfig, $sqlAyConfig, $sqlBzConfig, $wsConfig )

$newVMScriptBlock = [scriptblock]::Create( {
        [CmdLetBinding()]
        param
        (
            [Parameter(Mandatory = $true)]
            [hashtable] $vmConfig,
            [Parameter(Mandatory = $true)]
            [hashtable] $sourceImage,
            [Parameter(Mandatory = $true)]
            [hashtable] $nicConfig,
            [Parameter(Mandatory = $true)]
            [string] $storageAccountName,
            [Parameter(Mandatory = $true)]
            [string] $licenseType,
            [Parameter(Mandatory = $true)]
            [pscredential] $adminCredentials,
            [Parameter(Mandatory = $false)]
            [string] $pipAddressName
        )
        
        if (-not [string]::IsNullOrEmpty($pipAddressName))
        {
            $pipSplat = @{
                resourceGroupName = $nicConfig.resourceGroupName
                location          = $nicConfig.location
                name              = $pipAddressName
                allocationMethod  = Dynamic
                domainNameLabel   = "$($vmConfig.vmName){0}" -f $(Get-Random)
            }
            $nicConfig.publicIpAddressId = (New-AzPublicIpAddress @pipSplat).Id
        }

        $nic = New-AzNetworkInterface @nicConfig

        $rgSplat = @{
            resourceGroupName = $nicConfig.resourceGroupName
            location          = $nicConfig.location
        }

        $vm = New-AzVMConfig @vmConfig
        $null = $vm | Set-AzVMOperatingSystem -Windows -ComputerName $vmConfig.vmName -Credential $adminCredentials
        $null = $vm | Set-AzVMOSDisk -CreateOption FromImage
        $null = $vm | Set-AzVMSourceImage @sourceImage
        $null = $vm | Add-AzVMNetworkInterface -Id $nic.Id -Primary
        $null = $vm | Set-AzVMBootDiagnostic @rgSplat -StorageAccountName $storageAccountName -Enable
        New-AzVM $rgSplat -VM $vm
    } )

$vmConfiguration | ForEach-Object { Invoke-Command -ScriptBlock $newVMScriptBlock -ArgumentList $_ }




set private ip
set dns name




https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/diagnostics-windows

$SubscriptionId = $AzContext.Context.Subscription.Id
$VM = Get-AzureRmVM -ResourceGroupName $RGName -Name VMName
$VMResourceId = $VM.Id
$ScheduledShutdownResourceId = "/subscriptions/$SubscriptionId/resourceGroups/wayneVMRG/providers/microsoft.devtestlab/schedules/shutdown-computevm-$VMName"

$Properties = @{}
$Properties.Add('status', 'Enabled')
$Properties.Add('taskType', 'ComputeVmShutdownTask')
$Properties.Add('dailyRecurrence', @{'time'= 1159})
$Properties.Add('timeZoneId', "Eastern Standard Time")
$Properties.Add('notificationSettings', @{status='Disabled'; timeInMinutes=15})
$Properties.Add('targetResourceId', $VMResourceId)

#Error
New-AzureRmResource -Location eastus -ResourceId $ScheduledShutdownResourceId  -Properties $Properties  -Force

$resourcegroup = "YOUR_RG_NAME"
$vm = "YOURVMNAME"
$shutdown_time = "1900"
$shutdown_timezone = "W. Europe Standard Time"

$properties = @{
    "status" = "Enabled";
    "taskType" = "ComputeVmShutdownTask";
    "dailyRecurrence" = @{"time" = $shutdown_time };
    "timeZoneId" = $shutdown_timezone;
    "notificationSettings" = @{
        "status" = "Disabled";
        "timeInMinutes" = 30
    }
    "targetResourceId" = (Get-AzureRmVM -ResourceGroupName $resourcegroup -Name $vm).Id
}

New-AzureRmResource -ResourceId ("/subscriptions/{0}/resourceGroups/{1}/providers/microsoft.devtestlab/schedules/shutdown-computevm-{2}" -f (Get-AzureRmContext).Subscription.Id, $resourcegroup, $vm) -Location (Get-AzureRmVM -ResourceGroupName $resourcegroup -Name $vm).Location -Properties $properties -Force