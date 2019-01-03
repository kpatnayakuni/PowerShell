#requires -Modules Az

param
(
    [Parameter(Mandatory=$true)]
    [string] $ResourceGroupName,	# Resource Group
    [Parameter(Mandatory=$true)]
    [string] $VMName,				# VM Name
    [Parameter(Mandatory=$true)]
    [string] $Location,				# Location
	[Parameter(Mandatory=$true)]
	[ValidateSet('Windows','Linux')]
    [string] $OSType,				# OS Type (Windows/Linux)
    [Parameter(Mandatory=$true)]
    [string] $VirtualNetworkName,	# VNet
    [Parameter(Mandatory=$true)]
    [string] $SubnetName,			# Subnet
    [Parameter(Mandatory=$true)]
	[string] $SecurityGroupName, 	# NSG
	[Parameter(Mandatory=$false)]
    [string] $VMSize,				# VM Size
	[Parameter(Mandatory=$false)]
	[switch] $AssignPublicIP,		# Assign PIP
    [Parameter(Mandatory=$false)]
    [pscredential]$VMCredential,	# VM login credential
    [Parameter(Mandatory=$false)]
    [Int[]] $AllowedPorts			# NSG rules
)

# Verify Login
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Verifying the Azure login subscription status...")
if( -not $(Get-AzContext) ) 
{  
	Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Login to Azure subscription failed, no valid subscription found.")
	return 
}
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Login to Azure subscription successfully!")

# Verify VM doesn't exist
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Checking the $VMName VM existance...")
[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction SilentlyContinue
if($null -ne $VM)
{
	Write-Error "$VMName VM is already existed in $ResourceGroupName ResourceGroup, exiting..."
	break
}
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"No VM found with the name $VMName.")

# Create user object
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Obtaining the VM login credentials...")
if (-not $PSBoundParameters.ContainsKey('VMCredential'))
{
    [pscredential] $VMCredential = Get-Credential -Message 'Please enter the vm credentials'
}

# Verify credential
if ($VMCredential.GetType().Name -ne "PSCredential")
{
    Write-Error "No valid credential found, exiting..."
    break
}
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Obtained valid VM login credentials")

# Verify/Create a resource group
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Verifying the $ResourceGroupName Resource Group existance")
[Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResourceGroup] $ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $ResourceGroup)
{
	$ResourceGroup = New-AzResourceGroup -Name $ResourceGroupName -Location $Location
	Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"New resource group $ResourceGroupName is created.")
}
else 
{
	Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"$ResourceGroupName Resource Group already exists, skipping new resource group creation...")	
}

# Verify the virtual network
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Verifying the $VirtualNetworkName VNet existance.")
[Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork] $VNet = Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $VNet)
{
	[Microsoft.Azure.Commands.Network.Models.PSSubnet] $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix 192.168.1.0/24
	$VNet = New-AzVirtualNetwork -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location -Name $VirtualNetworkName -AddressPrefix 192.168.0.0/16 -Subnet $SubnetConfig
	Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"$VirtualNetworkName VNet doesn't exist, and new VNet is created.")
}
else 
{
	Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"$VirtualNetworkName VNet already exists, and verifying $SubnetName subnet existance.")
	[Microsoft.Azure.Commands.Network.Models.PSSubnet[]] $Subnets = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $VNet
	$SubnetConfig = $Subnets | Where-Object -FilterScript {$_.Name -eq $SubnetName}
	if ($null -eq $SubnetConfig)
	{
		$VNetAddressPrefixes = $VNet.AddressSpace.AddressPrefixes
		$AddressPrefix = @($VNetAddressPrefixes.Split('.'))
		$AddressPrefix[2] = [int]($Subnets.AddressPrefix|Measure-Object -Maximum).Maximum.ToString().Split('.')[2] + 1
		$AddressPrefix = $AddressPrefix -join '.'
		$VNet | Add-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $AddressPrefix | Set-AzVirtualNetwork
		Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"$SubnetName subnet doesn't exist, and new subnet is added to $VirtualNetworkName VNet.")
	}
	else 
	{
		Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"$VirtualNetworkName VNet is already exist and skipping new VNet creation.")
	}
}

[Microsoft.Azure.Commands.Network.Models.PSSubnet] $Subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $VNet

# Create a public IP address and specify a DNS name
if ($PSBoundParameters.ContainsKey('AssignPublicIP'))
{
	[string] $PipName = $VMName + '-pip'
	Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Verifying the public ip $PipName existance")
	[Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress] $VerifyPip = Get-AzPublicIpAddress -Name $PipName -ResourceGroupName $ResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
	if ($null -ne $VerifyPip) 
	{ 
		$PipName = $VMName + '-pip-' + $(Get-Random).ToString()
		Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"$($VerifyPip.Name) public ip already exists, and creating a new public ip $PipName")
	}
	[Microsoft.Azure.Commands.Network.Models.PSPublicIpAddress] $PublicIP = New-AzPublicIpAddress -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location -Name $PipName -AllocationMethod Static -IdleTimeoutInMinutes 4
	Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"New public ip $PipName is created")
}

# Create/Select a network security group
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Verifying the $SecurityGroupName network security group existance")
[Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup] $NSG = Get-AzNetworkSecurityGroup -Name $SecurityGroupName -ResourceGroupName $ResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $NSG)
{
	# Create an inbound network security group rules
	if ($PSBoundParameters.ContainsKey('AllowedPorts'))
	{
		[System.Array] $NsgRules = @()
		[int] $Priority = 1000
		foreach ($Port in $AllowedPorts)
		{
			[Microsoft.Azure.Commands.Network.Models.PSSecurityRule] $Rule = New-AzNetworkSecurityRuleConfig -Name "Allow_$Port" -Protocol Tcp -Direction Inbound -Priority $Priority -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange $Port -Access Allow
			$Priority++
			$NsgRules += $Rule
		}
		[Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup] $NSG = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location -Name $SecurityGroupName -SecurityRules $NsgRules
		Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"New security group $SecurityGroupName is created with the allowed ports.")
	}
	else
	{
		$NSG = New-AzNetworkSecurityGroup -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location -Name $SecurityGroupName
		Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"New security group $SecurityGroupName is created.")
	}
}
else 
{
	# Add an inbound network security group rules, if missing any
	if ($PSBoundParameters.ContainsKey('AllowedPorts'))
	{
		[int[]] $NSGAllowedPorts = $NSG.SecurityRules | Where-Object -FilterScript {$_.Access -eq "Allow"} | Select-Object -ExpandProperty DestinationPortRange
		[int[]] $PortsToAllow = $AllowedPorts | Where-Object -FilterScript {$_ -notin $NSGAllowedPorts}
		[int] $Priority = ($NSG.SecurityRules.Priority|Measure-Object -Maximum).Maximum + 100
		if ($PortsToAllow.Count -gt 0)
		{
			foreach($Port in $PortsToAllow)
			{
				$NSG | Add-AzNetworkSecurityRuleConfig -Name "Allow_$Port" -Protocol Tcp -Direction Inbound -Priority $Priority -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange $Port -Access Allow | Set-AzNetworkSecurityGroup
			}
		}
		Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Security group $SecurityGroupName is already exist, and added the allowed ports.")
	}
	else 
	{
		Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Security group $SecurityGroupName is already exist, and skipping add new security group.")
	}
}

# Create a virtual network card and associate with public IP address and NSG
[string] $NICName = "$VMName-nic"
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Verifying the network interface card $NICName existance")
[Microsoft.Azure.Commands.Network.Models.PSNetworkInterface] $NIC = Get-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue
if ($null -ne $NIC)
{
	$NICName = $VMName + "-nic-" + $(Get-Random).ToString()
	Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"$($NIC.Name) NIC already exists, and creating a new NIC $PipName")
}
[Microsoft.Azure.Commands.Network.Models.PSNetworkInterface] $NIC = New-AzNetworkInterface -Name $NICName -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location -SubnetId $Subnet.Id -NetworkSecurityGroupId $NSG.Id 
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"New $NICName NIC is created.")
if ($PSBoundParameters.ContainsKey('AssignPublicIP'))
{
	$NIC | Set-AzNetworkInterfaceIpConfig -Name $NIC.IpConfigurations[0].Name -PublicIpAddressId $PublicIP.Id -SubnetId $Subnet.Id | Set-AzNetworkInterface | Out-Null
	Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Public IP $($PublicIP.Name) is assigned to NIC $NICName")
}

# VM Size
if($PSBoundParameters.ContainsKey('VMSize') -eq $false )
{
	$VMSize = 'Standard_A1'
}
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Selecting the VMSize:$VMSize")

# OS Type
[hashtable] $VMSourceImage = @{PublisherName='';Offer='';Sku=''}
switch ($OSType) {
	'Windows' { $VMSourceImage.PublisherName = 'MicrosoftWindowsServer'
				$VMSourceImage.Offer = 'WindowsServer'
				$VMSourceImage.Sku = '2016-Datacenter'
			}
	'Linux'	{
				$VMSourceImage.PublisherName = 'Canonical'
				$VMSourceImage.Offer = 'UbuntuServer'
				$VMSourceImage.Sku = '18.10-DAILY'
			}  
}
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Selecting the OSType:$OSType")

# Create a virtual machine configuration
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Configuring $VMName VM...")
[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VMConfig = New-AzVMConfig -VMName $VMName -VMSize $VMSize 
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Choosing VMSize:$VMSize")
if ($OSType -eq 'Windows')
{
	$VMConfig | Set-AzVMOperatingSystem -Windows -ComputerName $VMName -Credential $VMCredential | Out-Null
}
else 
{
	$VMConfig | Set-AzVMOperatingSystem -Linux -ComputerName $VMName -Credential $VMCredential | Out-Null
}
$VMConfig | Set-AzVMSourceImage -PublisherName $VMSourceImage.PublisherName -Offer $VMSourceImage.Offer -Skus $VMSourceImage.Sku -Version latest | Out-Null
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Configuring $OSType VM...")
$VMConfig | Add-AzVMNetworkInterface -Id $NIC.Id | Out-Null
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Configuring NIC...")
$VMConfig | Set-AzVMBootDiagnostics -Disable | Out-Null
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"Configuring boot diagnostics...")

# Create a virtual machine
Write-Verbose -Message ("{0} - {1}" -f (Get-Date).ToString(),"$VMName VM deployement started.")
New-AzVM -ResourceGroupName $ResourceGroup.ResourceGroupName -Location $Location -VM $VMConfig

<#
.\Create-AzVM.ps1 -ResourceGroupName test-rg -VMName testvm -Location southindia -OSType Linux -VirtualNetworkName test-vnet -SubnetName testnet -SecurityGroupName test-nsg -AssignPublicIP -AllowedPorts 22 -VMCredential $cred -Verbose
.\Create-AzVM.ps1 -ResourceGroupName test-rg -VMName testvm -Location southindia -OSType Windows -VirtualNetworkName test-vnet -SubnetName testnet -SecurityGroupName test-nsg -AssignPublicIP -AllowedPorts 3389 -VMCredential $cred -Verbose
#>