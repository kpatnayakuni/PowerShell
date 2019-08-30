Function Get-WinSrvFromInv
{
    <#
        The purpose of this function is to retrieve the list of server for which you want to check the Windows Activation status.
        Write your piece of code to retirve the servers from your inventory.
        for example, Get-Content -Path $InvPath\Server.txt
    #>
    return @("Srv2K19", "Srv2K16", "Srv2K12")
}
Function Get-WindowsActivation 
{
    [CmdLetBinding()]
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]] $ComputerName
    )
    Begin
    {
        $ActivationStatus = @()
        $ErroredServers = @()
    }
    Process
    {
        foreach ($CN in $ComputerName)
        {
            try { 
                    $SPL = Get-CimInstance -ClassName SoftwareLicensingProduct -ComputerName $CN -Filter "PartialProductKey IS NOT NULL"
                    $WinProduct = $SPL | Where-Object Name -like "Windows*" 
                    $Status = if ($WinProduct.LicenseStatus -eq 1) { "Activated" } else { "Not Activated" }
                    $ActivationStatus += New-Object -TypeName psobject -Property @{
                        ComputerName = $CN
                        Status = $Status
                    }
                }
            catch {
                    $ErroredServers += New-Object -TypeName psobject -Property @{
                        ComputerName = $CN
                        Error = $_.Exception.Message
                    } 
                }
        }
    }
    End
    {
        return $ActivationStatus, $ErroredServers
    }
}

Get-WinSrvFromInv | Get-WindowsActivation