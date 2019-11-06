
$Computername = 'localhost'

$OS     = Get-CimInstance -ClassName CIM_OperatingSystem -ComputerName $Computername
$CS     = Get-CimInstance -ClassName CIM_ComputerSystem -ComputerName $Computername
$CPUs   = Get-CimInstance -ClassName CIM_Processor -ComputerName $Computername
$CPUInfo= @()
foreach ($CPU in $CPUs) 
{
    $CPUInfo += New-Object -TypeName psobject -Property @{
        DeviceID    = $CPU.DeviceID
        Name        = $CPU.Caption 
    }
}
$BIOS       = Get-CimInstance -ClassName CIM_BIOSElement -ComputerName $Computername
$Disks      = Get-CimInstance -ClassName CIM_LogicalDisk -ComputerName $Computername
$DiskInfo   = @()
foreach ($Disk in $Disks)
{
    if ($Disk.Access -ne 0) { continue }
    $DiskInfo += New-Object -TypeName psobject -Property @{
        Drive       = $Disk.Name
        Size        = [math]::Round($Disk.Size/1GB)
        FreeSpace   = [math]::Round($Disk.FreeSpace/1GB)
    }
}
$User = Invoke-Command -ScriptBlock { "$($ENV:USERDOMAIN)\$($ENV:USERNAME)" } -ComputerName $Computername

$Output = New-Object -TypeName psobject -Property @{
    ComputerName            = $Computername
    CurrentlyLoggedOnUser   = $User
    OperatingSystem         = $OS.Caption
    CPUInfo                 = $CPUInfo
    DiskInfo                = $DiskInfo
    TotalPhysicalMemory     = [math]::Round($CS.TotalPhysicalMemory/1GB)
    ServiceTag              = $BIOS.SerialNumber
}

return $Output