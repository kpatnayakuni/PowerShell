Function Get-WinSrvFromInv
{
    <#
        The purpose of this function is to retrieve the list of servers for which you want to check the Windows Activation status.
        Write your piece of code to retirve the servers from your inventory.
        for example, Get-Content -Path $InvPath\Server.txt
    #>
    return @("Srv2K19", "Srv2K16", "Srv2K12")
}
Function Get-WindowsActivation 
{
    <#
        This is a PowerShell advanced function to rerieve the Windows Activation Status using CIM classes.
        It takes one or more servers as an input, and it accepts through pipeline as well
        This script will check the connectivity, and then checks the activation status
        It collects the infor from all the servers and then return the value of error at once.
    #>
    [CmdLetBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]] $ComputerName
    )
    Begin
    {
        $ActivationStatus = @()
    }
    Process
    {
        foreach ($CN in $ComputerName)
        {
            $PingStatus = Test-Connection -ComputerName $CN -ErrorAction Stop -Count 1 -Quiet
            $SPL = Get-CimInstance -ClassName SoftwareLicensingProduct -ComputerName $CN -Filter "PartialProductKey IS NOT NULL" -ErrorAction Stop
            $WinProduct = $SPL | Where-Object Name -like "Windows*" 
            $Status = if ($WinProduct.LicenseStatus -eq 1) { "Activated" } else { "Not Activated" }
            if ($PingStatus -ne $true)
            {
                $PingStatus = "No"
                $Status = "Error"
            } else { $PingStatus = "Yes" }
            $ActivationStatus += New-Object -TypeName psobject -Property @{
                ComputerName = $CN
                Status = $Status
                IsPinging = $PingStatus
            }
        }
    }
    End
    {
        return $($ActivationStatus | Select-Object -Property ComputerName, IsPinging, Status)
    }
}

## Invoke the functions.
Get-WinSrvFromInv | Get-WindowsActivation