Function Get-Inventory
{
    [CmdLetBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]] $ComputerName
    )
    
    Begin
    {
        $Output = @()
    }

    Process
    {
        foreach ($CN in $ComputerName)
        {
            if ($(Test-Connection -ComputerName $CN -ErrorAction Stop -Count 1 -Quiet) -eq $false) { continue }
            $OS     = Get-CimInstance -ClassName CIM_OperatingSystem -ComputerName $CN
            $CS     = Get-CimInstance -ClassName CIM_ComputerSystem -ComputerName $CN
            $CPUs   = Get-CimInstance -ClassName CIM_Processor -ComputerName $CN
            $CPUInfo= @()
            foreach ($CPU in $CPUs) 
            {
                $CPUInfo += New-Object -TypeName psobject -Property @{
                    DeviceID    = $CPU.DeviceID
                    Name        = $CPU.Caption 
                }
            }
            $BIOS       = Get-CimInstance -ClassName CIM_BIOSElement -ComputerName $CN
            $Disks      = Get-CimInstance -ClassName CIM_LogicalDisk -ComputerName $CN
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
            $User = Invoke-Command -ScriptBlock { "$($ENV:USERDOMAIN)\$($ENV:USERNAME)" } -ComputerName $CN

            $Output = New-Object -TypeName psobject -Property @{
                ComputerName            = $CN
                CurrentlyLoggedOnUser   = $User
                OperatingSystem         = $OS.Caption
                CPUInfo                 = $CPUInfo
                DiskInfo                = $DiskInfo
                TotalPhysicalMemory     = [math]::Round($CS.TotalPhysicalMemory/1GB)
                ServiceTag              = $BIOS.SerialNumber
            }
        }
    }

    End
    {
        return $Output
    }
}