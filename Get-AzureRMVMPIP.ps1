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
    [string] $H
)

if ($PSCmdlet.ParameterSetName -eq 'Help' -and $H)
{
    Get-Help -Path $PSScriptRoot
    break
}
else { break }

if([string]::IsNullOrEmpty($(Get-AzureRmContext)))
{ $null = Add-AzureRmAccount }

if ($PSCmdlet.ParameterSetName -eq 'Name')
{ [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM = Get-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $VMName }
else { [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine] $VM = $VMObject }

[string] $NICId = $VM.NetworkProfile.NetworkInterfaces.id

[Microsoft.Azure.Commands.Network.Models.PSNetworkInterface] $NIC = Get-AzureRmNetworkInterface | Where-Object {$_.id -eq $NICId}

[string] $PIPId = $NIC.Properties.ipConfigurations.properties.publicIPAddress.id
$PIPId

<#

  Id CommandLine                                                                                                                                               
  -- -----------                                                                                                                                               
   1 Import-Module AzureRM                                                                                                                                     
   2 Get-AzureRmContext                                                                                                                                        
   3 Add-AzureRmAccount                                                                                                                                        
   4 Select-AzureRmSubscription                                                                                                                                
   5 $Context = Get-AzureRmContext                                                                                                                             
   6 Get-AzureRmSubscription                                                                                                                                   
   7 Get-Module AzureRM                                                                                                                                        
   8 Get-AzureRmVM                                                                                                                                             
   9 Get-AzureRmVM -ResourceGroupName lab-rg -Name Workstation                                                                                                 
  10 $VM = Get-AzureRmVM -ResourceGroupName lab-rg -Name Workstation                                                                                           
  11 $VM.NetworkProfile                                                                                                                                        
  12 $VM.NetworkProfile.NetworkInterfaces                                                                                                                      
  13 $VM.NetworkProfile.NetworkInterfaces.id                                                                                                                   
  14 Get-AzureRmResource -ResourceId $VM.NetworkProfile.NetworkInterfaces.id                                                                                   
  15 Get-AzureRmResource -ResourceId $VM.NetworkProfile.NetworkInterfaces.id | select *                                                                        
  16 $NIC = Get-AzureRmResource -ResourceId $VM.NetworkProfile.NetworkInterfaces.id                                                                            
  17 $NIC.Properties                                                                                                                                           
  18 $NIC.Properties.ipConfigurations                                                                                                                          
  19 Get-AzureRmPublicIpAddress -NetworkInterfaceName workstation73                                                                                            
  20 Get-AzureRmPublicIpAddress                                                                                                                                
  21 Get-AzureRmPublicIpAddress | select *                                                                                                                     
  22 Get-AzureRmNetworkInterface                                                                                                                               
  23 Get-AzureRmNetworkInterface | Select *                                                                                                                    
  24 $NIC                                                                                                                                                      
  25 $NIC|select *                                                                                                                                             
  26 $NIC.Properties                                                                                                                                           
  27 $NIC.Properties.ipConfigurations                                                                                                                          
  28 $NIC.Properties.ipConfigurations.properties                                                                                                               
  29 $NIC.Properties.ipConfigurations.properties.publicIPAddress                                                                                               
  30 $PIP = Get-AzureRmPublicIpAddress | ?{$_.id -eq $NIC.Properties.ipConfigurations.properties.publicIPAddress.id}                                           
  31 $PIP                                                                                                                                                      
  32 $PIP.IpAddress                                                                                                                                            
  33 Get-AzureRmResource -ResourceId $NIC.Properties.ipConfigurations.properties.publicIPAddress.id                                                            
  34 Get-AzureRmResource -ResourceId $NIC.Properties.ipConfigurations.properties.publicIPAddress.id | fl *                                                     
  35 $vm                                                                                                                                                       
  36 $vm|gm                                                                                                                                                    
  37 $VMObject = New-Object -TypeName [PSCustomObject]@{...                                                                                                    
  38 $VMObject = New-Object -TypeName [PSObject]@{...                                                                                                          
  39 $VMObject = New-Object -TypeName PSObject -Property @{...                                                                                                 
  40 $VMObject                                                                                                                                                 
  41 $VMObject['ResourceGroup'] = "lab-rg"                                                                                                                     
  42 $VMObject.ResourceGroup = "lab-rg"                                                                                                                        
  43 $VMObject                                                                                                                                                 
  44 $VMObject = @{...                                                                                                                                         
  45 $VMObject                                                                                                                                                 
  46 $VMObject.ResourceGroup = "lab-rg"                                                                                                                        
  47 $VMObject                                                                                                                                                 
  48 $vm                                                                                                                                                       
  49 $vm.ResourceGroupName                                                                                                                                     
  50 $vm.name                                                                                                                                                  
  51 history                                                                                                                                                   
  52 $VM.NetworkProfile.NetworkInterfaces.id                                                                                                                   
  53 $VM.NetworkProfile.NetworkInterfaces.id|gm                                                                                                                
  54 Get-AzureRmNetworkInterface                                                                                                                               
  55 Get-AzureRmNetworkInterface|slect *                                                                                                                       
  56 Get-AzureRmNetworkInterface|select *                                                                                                                      
  57 Get-AzureRmNetworkInterface| ?{$_.id -eq $VM.NetworkProfile.NetworkInterfaces.id}                                                                         
  58 Get-AzureRmNetworkInterface| ?{$_.id -eq $VM.NetworkProfile.NetworkInterfaces.id}|gm                                                                      
  59 history                                                                                                                                                   



#>





