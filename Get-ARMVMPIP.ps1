[CmdLetBinding(DefaultParameterSetName='Name')]

param
(
    [Parameter(Mandatory=$true,ParameterSetName='Name')]
    [string] $ResourceGroupName,
    [Parameter(Mandatory=$true,ParameterSetName='Name')]
    [string] $VMName,
    [Parameter(Mandatory=$true,ParameterSetName='Object')]
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VMObject,
    [Parameter(Mandatory=$false,ParameterSetName='Name')]
    [Parameter(Mandatory=$false,ParameterSetName='Object')]
    [switch] $StartIfVMIsNotRunning,
    [Parameter(Mandatory=$false,ParameterSetName='Name')]
    [Parameter(Mandatory=$false,ParameterSetName='Object')]
    [switch] $ConnetRDP,
    [Parameter(Mandatory=$true,ParameterSetName='Help')]
    [switch] $H
)

if ($PSCmdlet.ParameterSetName -eq 'Help' -and $H)
{
    Get-Help $PSCommandPath
    break
}

[System.Version] $RequiredModuleVersion = '6.13.1'
[System.Version] $ModuleVersion = (Get-Module -Name AzureRM).Version
if ($ModuleVersion -lt $RequiredModuleVersion)
{
    Write-Verbose -Message "Import latest AzureRM module"
    break
}

if([string]::IsNullOrEmpty($(Get-AzureRmContext)))
{ $null = Add-AzureRmAccount }

try
{
    if ($PSCmdlet.ParameterSetName -eq 'Name')
    { [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachineInstanceView] $VM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName -Status}
    elseif ($PSCmdlet.ParameterSetName -eq 'Object') { [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachineInstanceView] $VM = Get-AzureRmVM -ResourceGroupName $VMObject.ResourceGroupName -Name $VMObject.Name -Status }
}
catch
{
    Write-Verbose -Message $_.Exception.Message
    break
}

[Microsoft.Azure.Management.Compute.Models.InstanceViewStatus] $VMStatus = $VM.Statuses | Where-Object { $_.Code -match 'running' }

if ([string]::IsNullOrEmpty($VMStatus)) { [bool] $ISVMRunning = $false } else { [bool] $ISVMRunning = $true }

if ($ISVMRunning -eq $false -and $StartIfVMIsNotRunning -eq $true)
{ $null = Start-AzureRMVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name } 

[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VirtualMachine = Get-AzureRMVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
[string] $NICId = $VirtualMachine.NetworkProfile.NetworkInterfaces.id
[Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource] $NICResource = Get-AzureRmResource -ResourceId $NICId
[string] $PIPId = $NICResource.Properties.ipConfigurations.properties.publicIPAddress.id
[Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource] $PIPResource = Get-AzureRmResource -ResourceId $PIPId
[ipaddress] $PIP = $PIPResource.Properties.ipAddress

[string] $PublicIPAllocationMethod = $PIPResource.Properties.publicIPAllocationMethod

if ([string]::IsNullOrEmpty($PIP.IPAddressToString) -and $ISVmRunning -eq $false -and $PublicIPAllocationMethod -eq 'Dynamic')
{
    Write-Verbose -Message $("Since {0} VM is not running and 'Public IP Allocation Method is Dynamic', unable to determine the Public IP.`nRun the command with -StartIfVMIsNotRunning flag" -f $VMName)
    break
}

if ($ConnetRDP)
{
    Invoke-Expression "mstsc.exe /v $($PIP.IPAddressToString)"
    break
}

return, $PIP.IPAddressToString
