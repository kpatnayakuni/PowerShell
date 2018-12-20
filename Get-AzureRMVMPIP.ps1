[CmdLetBinding(DefaultParameterSetName='Name')]

param
(
    [Parameter(Mandatory=$true,ParameterSetName='Name')]
    [string] $ResourceGroupName,
    [Parameter(Mandatory=$true,ParameterSetName='Name')]
    [string] $VMName,
    [Parameter(Mandatory=$true,ParameterSetName='Object')]
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VMObject,
    [Parameter(Mandatory=$true,ParameterSetName='Help')]
    [switch] $H
)

if ($PSCmdlet.ParameterSetName -eq 'Help' -and $H)
{
    Get-Help $PSCommandPath
    break
}

if([string]::IsNullOrEmpty($(Get-AzureRmContext)))
{ $null = Add-AzureRmAccount }

if ($PSCmdlet.ParameterSetName -eq 'Name')
{ [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName }
else { [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM = $VMObject }

[string] $NICId = $VM.NetworkProfile.NetworkInterfaces.id
[Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource] $NICResource = Get-AzureRmResource -ResourceId $NICId
[string] $PIPId = $NICResource.Properties.ipConfigurations.properties.publicIPAddress.id
[Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource] $PIPResource = Get-AzureRmResource -ResourceId $PIPId
[ipaddress] $PIP = $PIPResource.Properties.ipAddress
return, $PIP.IPAddressToString