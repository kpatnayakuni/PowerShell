[CmdLetBinding(DefaultParameterSetName='Name')]

param
(
    [Parameter(Mandatory=$true,ParameterSetName='Name')]
    [string] $ResourceGroupName,
    [Parameter(Mandatory=$true,ParameterSetName='Name')]
    [string] $VMName,
    [Parameter(Mandatory=$true,ParameterSetName='Object')]
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM,
    [Parameter(Mandatory=$true,ParameterSetName='Help')]
    [string] $H
)

if([string]::IsNullOrEmpty($(Get-AzureRmContext)))
{
    $null = Add-AzureRmAccount
}

if ($PSCmdlet.ParameterSetName -eq 'Name')
{
    
}