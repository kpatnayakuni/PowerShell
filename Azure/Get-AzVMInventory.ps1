Function Get-AzVMInventory
{
    if (-not (Get-AzContext)) { Login-AzAccount }

    $VMList = Get-AzVM -Status

    $Output = @()

    $Output += foreach ($VM in $VMList)
    {
        
        $NICID = $VM.NetworkProfile.NetworkInterfaces.id
        $NIC = Get-AzResource -ResourceId $NICID
        $IpConfig = $NIC.Properties.ipConfigurations.properties.subnet.id
        New-Object -TypeName psobject -Property @{
            VMName = $VM.Name
            RGName = $VM.ResourceGroupName
            Location = $VM.Location
            VMSize = $VM.HardwareProfile.VmSize
            NIC = $NIC.Name
            VNet = $($IpConfig.ToString().Split('/'))[-3]
            Subnet = $($IpConfig.ToString().Split('/'))[-1]
            OSName = $VM.StorageProfile.OsDisk.OsType
            State = $VM.PowerState
        }
    }
    return $($Output | Select-Object VMName, RGName, Location, VMSize, NIC, VNet, Subnet, OSName, State)
}