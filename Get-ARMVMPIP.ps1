<#
.SYNOPSIS

Retrieves public ip of an AzureVM.

.DESCRIPTION

Retrieves the public ip of an AzureVM, Starts the VM if the VM is not running and connect to RDP session.

.PARAMETER ResourceGroupName

Specify the resourcegroup name when the prameterset name is 'Name'

.PARAMETER VMName

Specify the virtual machine name when the parameterset name is 'Name'

.PARAMETER VMObject

Specify the VM Object when the parameterset name is 'Object', and it accepts the object from pipeline as well 

.PARAMETER StartIfVMIsNotRunning

Specify the flag to start the VM is it is not running.

.PARAMETER ConnectRDP

Specify the flag to connect to remote desktop session

.PARAMETER H

Specify the flag to disply this help

.INPUTS

Specify ResourceGroupName & VMName parameters when the script wants to be resolved through 'Name' parameterset.
Specify the VMObject parameter when the script wants to be resolved through 'Object' parameterset.
And other common paramaters for their respective purposes

.OUTPUTS

Returns the public ip address of an Azure VM
Connects to remote destop session for an Azure VM

.EXAMPLE

C:\GitRepo> .\Get-ARMVMPIP.ps1 -ResourceGroupName lab-rg -Name Workstation
xxx.xxx.xxx.xxx 

Returns the public ip address when the VM is running or the VM is deallocated but the publicIPAllocationMethod is set to 'Static'.

.EXAMPLE

C:\GitRepo> $VM = Get-AzureRmVM -ResourceGroupName lab-rg -Name Workstation
C:\GitRepo> $VM | .\Get-ARMVMPIP.ps1
xxx.xxx.xxx.xxx

Returns the public ip address when the VM is running or the VM is deallocated but the publicIPAllocationMethod is set to 'Static'.

.EXAMPLE

C:\GitRepo> .\Get-ARMVMPIP.ps1 -ResourceGroupName lab-rg -Name Workstation -StartIfVMIsNotRunning
xxx.xxx.xxx.xxx

Returns the public ip address when the VM is running or starts the VM if it is not running and returns the public ip.

.EXAMPLE

C:\GitRepo> .\Get-ARMVMPIP.ps1 -ResourceGroupName lab-rg -Name Workstation -ConnectRDP

# Doesn't return any output simply connects to RDP session 

Connect to RDP session when the VM is running

.EXAMPLE

C:\GitRepo> .\Get-ARMVMPIP.ps1 -ResourceGroupName lab-rg -Name Workstation -ConnectRDP

# Doesn't return any output simply connects to RDP session 

Connect to RDP session when the VM is running and if the VM is not running it will start and establish the RDP session.

.NOTES

Author: Kiran Patnayakuni

#>


[CmdLetBinding(DefaultParameterSetName='Name')]

param
(
    [Parameter(Mandatory=$true,ParameterSetName='Name')]
    [string] $ResourceGroupName, # ResourceGroup Name when the ParameterSetName is 'Name'
    [Parameter(Mandatory=$true,ParameterSetName='Name')]
    [string] $VMName, # Virtual Machine Name when the ParameterSetName is 'Name'
    [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='Object')]
    [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VMObject, # VM Object when the ParameterSetName is 'Object'
    [Parameter(Mandatory=$false,ParameterSetName='Name')]
    [Parameter(Mandatory=$false,ParameterSetName='Object')]
    [switch] $StartIfVMIsNotRunning, # Start the VM, if it is not running
    [Parameter(Mandatory=$false,ParameterSetName='Name')]
    [Parameter(Mandatory=$false,ParameterSetName='Object')]
    [switch] $ConnetRDP, # Connect Remote Desktop Session
    [Parameter(Mandatory=$true,ParameterSetName='Help')]
    [switch] $H # Get Help
)

# Get Help
if ($PSCmdlet.ParameterSetName -eq 'Help' -and $H)
{
    Get-Help $PSCommandPath -Full
    break
}

# Ensure the 6.13.1 version AzureRM module is loaded, because some commands output have been changed in this version
[System.Version] $RequiredModuleVersion = '6.13.1'
[System.Version] $ModuleVersion = (Get-Module -Name AzureRM).Version
if ($ModuleVersion -lt $RequiredModuleVersion)
{
    Write-Verbose -Message "Import latest AzureRM module"
    break
}

# Login in into the Azure account, if it is not already logged in
if([string]::IsNullOrEmpty($(Get-AzureRmContext)))
{ $null = Add-AzureRmAccount }

# Retrieve the virtual machine running status
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

# Check whether the vm PowerState is running
[Microsoft.Azure.Management.Compute.Models.InstanceViewStatus] $VMStatus = $VM.Statuses | Where-Object { $_.Code -match 'running' }
if ([string]::IsNullOrEmpty($VMStatus)) { [bool] $ISVMRunning = $false } else { [bool] $ISVMRunning = $true }

# If VM is not running and -StartIfVMIsNotRunning flag is enabled, then start the VM 
if ($ISVMRunning -eq $false -and $StartIfVMIsNotRunning -eq $true)
{ 
    $null = Start-AzureRMVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name 
    $ISVmRunning = $true
} 

# Get Public IP address 
[Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VirtualMachine = Get-AzureRMVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name
[string] $NICId = $VirtualMachine.NetworkProfile.NetworkInterfaces.id
[Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource] $NICResource = Get-AzureRmResource -ResourceId $NICId
[string] $PIPId = $NICResource.Properties.ipConfigurations.properties.publicIPAddress.id
[Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.PSResource] $PIPResource = Get-AzureRmResource -ResourceId $PIPId
[ipaddress] $PIP = $PIPResource.Properties.ipAddress

# Exit the script if the VM is not running and PublicIPAllocationMethod is Dynamic or public ip is not assigned 
[string] $PublicIPAllocationMethod = $PIPResource.Properties.publicIPAllocationMethod
if ([string]::IsNullOrEmpty($PIP.IPAddressToString) -and $ISVMRunning -eq $false -and $PublicIPAllocationMethod -eq 'Dynamic')
{
    Write-Verbose -Message $("Since {0} VM is not running and 'Public IP Allocation Method is Dynamic', unable to determine the Public IP.`nRun the command with -StartIfVMIsNotRunning flag" -f $VMName)
    break
}
elseif ([string]::IsNullOrEmpty($PIP.IPAddressToString) -and $ISVMRunning -eq $true)
{
    Write-Verbose -Message $("No public ip id assigned to this {0} VM." -f $VMName)
    break
}

# Connect the VM when -ConnectRDP flag is enabled and VM is running
if ($ConnetRDP -and $ISVMRunning)
{
    Invoke-Expression "mstsc.exe /v $($PIP.IPAddressToString)"
    break
}

# Just return the IP address when no flags are enabled
return, $PIP.IPAddressToString