Function Get-WinSrvFromInv
{
    <#
        The purpose of this function is to retrieve the list of server for which you want to check the Windows Activation status.
        Write your piece of code to retirve the servers from your inventory.
        for example, Get-Content -Path $InvPath\Server.txt
    #>
    return @("Srv2K19", "Srv2K16", "Srv2K12")
}
Function Check-WindowsActivation 
{
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]] $ComputerName
    )
    Begin
    {
        $Status = @()
    }
    Process
    {
        foreach ($CN in $ComputerName)
        {
            $SPL = Get-CimInstance -ClassName SoftwareLicensingProduct -ComputerName $CN
            $WinProduct = $SPL | Where-Object -FilterScript { $null -eq $_.PartialProductKey -and $_.Name -like "Windows*" }
            $Status = if ($WinProduct.LicenseStatus -eq 1) { "Activated" } else { "Not Activated" }
            $Status += New-Object -TypeName psobject -Property @{
                ComputerName = $ComputerName
                Status = $Status
            }
        }
    }
    End
    {
        return $Status
    }
}

Get-WinSrvFromInv | Check-WindowsActivation