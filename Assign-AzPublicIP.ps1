#requires -Module Az

# Function to create and assign a public ip address 
# to an Azure Virtual Machine using Az PowerShell module.
Function Assign-AzVMPublicIP2
{
    Param
    (
        # Resource Group Name
        [Parameter(Mandatory=$true)]
        [string] $ResourceGroupName,
        # Virtual Machine Name
        [Parameter(Mandatory=$true)]
        [string] $VMName
    )
    # Retrieve the Virtual Machine details
    $VM = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction SilentlyContinue

    # Checking the VM existance
    if($null -eq $VM)
    {
        Write-Error "Please enter a valid and existing Resource Group Name and Virtual Machine Name"
        return
    }

    $Location = $VM.Location    # Location to create a public ip
    $NICId = $VM.NetworkProfile.NetworkInterfaces.Id # Network Interface resource id
    $NICResource = Get-AzResource -ResourceId $NICId # Retrieve the NIC resource details

    # Retrive the NIC Object
    $NIC = Get-AzNetworkInterface -Name $NICResource.Name -ResourceGroupName $NICResource.ResourceGroupName
    $NICIPConfigName = $NIC.ipConfigurations[0].Name    # IP Config Name to be used with Set-AzNetworkInterfaceIpConfig CmdLet
    $NICSubnetId = $NIC.ipConfigurations[0].subnet.id   # Subnet id to be used with Set-AzNetworkInterfaceIpConfig CmdLet

    # Create a public ip
    $PublicIP = New-AzPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $Location -Name "$VMName-pip" -AllocationMethod Static -IdleTimeoutInMinutes 4

    # Warn the user if no NSG is associated with this VM
    if ($null -eq $NIC.NetworkSecurityGroup)
    {
        Write-Warning "Since no Network Security Group is associated with this Virtual Machine, by default all ports are open to the internet."
    }

    # Assign the public ip to the VM NIC
    $NIC | Set-AzNetworkInterfaceIpConfig -Name $NICIPConfigName -SubnetId $NICSubnetId -PublicIpAddressId $PublicIP.Id | Set-AzNetworkInterface
}

Assign-AzVMPublicIP2 -ResourceGroupName test-rg -VMName test-vm

