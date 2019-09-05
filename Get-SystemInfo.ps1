Function Get-CIMInfo 
{
    param 
    (
        [Parameter(Mandatory=$true)]
        [string] $ClassName,
        [Parameter(Mandatory=$false)]
        [string] $ComputerName = '.',
        [Parameter(Mandatory=$false)]
        [string] $SelectObjects = '*'
    )

    $SelectArgs = $SelectObjects.split(',')
    $CIMInfo = Get-CimInstance -ClassName $ClassName -ComputerName $ComputerName | Select-Object $SelectArgs
    return $CIMInfo
}
Function Get-SysInfo
{
    [CmdLetBinding()]
    param
    (
        [Parameter(Mandatory=$false,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]] $ComputerName = '.'
    )

    Begin
    {
        $SysInfo = @()
    }
    Process
    {
        foreach ($CN in $ComputerName)
        {
            if (Test-Connection -ComputerName $CN -Count 1 -Quiet)
            {
                $OSCIMInfo = Get-CIMInfo
                Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $CN
                $CompCIMInfo = Get-CimInstance -ClassName Win32_ComputerSystem
                $WinActiveStatus = Get-CimInstance -ClassName SoftwareLicensingProduct -ComputerName $CN -Filter "PartialProductKey IS NOT NULL" | Where-Object Name -like "Windows*" 
                $WinSystem = Get-CimInstance -ClassName CIM_UnitaryComputerSystem|fl Model,Manufacturer,NumberOfProcessors,NumberOfLogicalProcessors
                $IPConfiguration = Get-NetIPConfiguration
            }
        }
    }
    
}