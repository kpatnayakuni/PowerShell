##########################################################
##    Listing/Finding the commands using Get-Command    ##
##########################################################

# To list all the commands availble in the current session
Get-Command 

<# 
Search the commands with the name using wildcard, and it returns all types 
of commands matching the name with the given pattern, you can also filter 
further down the commands using -Module, -CommandType or both
#>
Get-Command -Name *VHD*
Get-Command -Name *VHD* -CommandType Function
Get-Command -Name *VHD* -Module Hyper-V
Get-Command -Name *VHD* -CommandType Cmdlet -Module Hyper-V 

<# 
Search the commands with Verb or Noun, or both using direct names 
or wildcards as well, also with -Module as well
#>
Get-Command -Verb Get 
Get-Command -Noun SmbShare
Get-Command -Verb Set -Noun Smb*
Get-Command -Verb Get -Noun Smb* -Module SmbShare

<# 
List the commands in a module, again you can filter 
further down using -Name or -Verb & -Noun, and -CommandType
#>
Get-Command -Module SqlServer 
Get-Command -Module SqlServer -CommandType Alias

<#
Search commands by either the parameter name or parameter type, or both
You can still filter further down using -Name, or -Verb & -Noun, 
-Module and -CommandType
#>
Get-Command -ParameterName VMName
Get-Command -ParameterType System.Boolean
Get-Command -ParameterName Scoped -ParameterType System.Boolean

<#
List the commands from the modules loaded in the current session
You can still filter further down using -Name, or -Verb & -Noun, -Module 
-CommandType, -ParameterName and -ParameterType
#>
Get-Command -ListImported

<#
To limit the output count. You can use with all ParameterSets
Works with all possible parameter combination
#>
Get-Command -TotalCount 10
Get-Command -ListImported -TotalCount 10

<#
Search the commands from closest match to least likely match. You can use 
this switch if you are not sure about exact name of the command, and you can't 
use this with wildcard search, and works only with -Name parameter combination
#>
Get-Command -Name gotcemmand -UseFuzzyMatching

<#
List the commands with the same name from different sources
To test this, create an empty Write-Error function and then run the command below
To create an empty function: 
Function Write-Error {}
#>
Get-Command -Name Write-Error -All
# Or to list all
Get-Command -All

<#
List the commands using the FullyQualifiedModule parameter to list the commands 
from the specific version of the module
-FullyQualifiedModule and -Module are mutually exclusive
#>
Get-Command -FullyQualifiedModule @{ModuleName = "UEV"; ModuleVersion = "2.1.639.0" }

<#
Get the command count
Get-Command can be used with all possible parameter combinations
#>

Get-Command | Measure-Object -Line | Select-Object -ExpandProperty Lines

<#
List commands return output, and its output type
Get-Command can be used with all possible parameter combinations
#>
Get-Command | Where-Object OutputType | Format-List

###################################################################
##   Get information about a specific CmdLet using Get-Command   ##
###################################################################

# Get the command basic info 
Get-Command -Name Get-ComputeProcess

# Get the syntax(s) of a given command
Get-Command -Name Get-Counter -Syntax

# Get complete information about the given command
Get-Command -Name New-NetIPAddress | Format-List *

# Get all the parameters of a given command
Get-Command -Name Get-ControlPanelItem | Select-Object -ExpandProperty Parameters
# Or
(Get-Command -Name Get-ControlPanelItem).Parameters

# Get the module name of a given command
Get-Command -Name Show-ControlPanelItem | Select-Object -ExpandProperty ModuleName
# Or
(Get-Command -Name Show-ControlPanelItem).ModuleName

# Get the definition of a given command
# For CmdLets you see only systax, it works only for Functions
Get-Command -Name Get-NetAdapterStatistics | Select-Object -ExpandProperty Definition
# Or
(Get-Command -Name Get-NetAdapterStatistics).Definition

# Get the command output type
Get-Command -Name Get-NetAdapterHardwareInfo | Select-Object -ExpandProperty OutputType
# Or
(Get-Command -Name Get-NetAdapterHardwareInfo).OutputType

# Get the command's default parameter set
Get-Command -Name Get-Disk | Select-Object -ExpandProperty DefaultParameterSet
# Or
(Get-Command -Name Get-Disk).DefaultParameterSet

# Get the type of a given command
Get-Command -Name Get-NetRoute | Select-Object -ExpandProperty CommandType
# Or
(Get-Command -Name Get-NetRoute).CommandType

# Get the dynamic parameter list of a given command (if any)
Get-Command -Name Get-Package -ArgumentList 'Cert:' | `
    Select-Object -ExpandProperty ParameterSets | `
    ForEach-Object { $_.Parameters } | `
    Where-Object { $_.IsDynamic } | `
    Select-Object -Property Name -Unique

###################################################################
##  Get help of a specific CmdLet or about topic using Get-Help  ##
###################################################################

# To get the basic help 
Get-Help -Name Get-WULastInstallationDate

# To get the parameter description & examples in-addition to the basic help
Get-Help -Name Test-WSMan -Detailed

# To get the comprehensive help includes parameter descriptions and attributes, 
# examples, input and output object types, and additional notes.
Get-Help -Name Invoke-Expression -Full

# To get the help with examples only
Get-Help -Name New-LocalGroup -Examples

# To get the online help in a browser seperately
Get-Help -Name Test-Connection -Online

# To get the full help in a seperate window
Get-Help -Name Get-Process -ShowWindow

# To get the help of a specific parameter of a command
Get-Help -Name Get-NetConnectionProfile -Parameter InterfaceIndex

# To get the help of all the parameters of a command
Get-Help -Name Compress-Archive -Parameter *

# You can use alias name as well, and works with all the above parameter combination
Get-Help -Name ls

# To get the help of a script (if available), and works with all the above parameter combination
Get-Help -Name C:\GitRepo\Test-Script.ps1

# To list the available help matching with a specific word
Get-Help -Name netconnection

# To list all the conceptual topics
Get-Help -Name about_*

# To get the help of a specific conceptual topic
Get-Help -Name about_ForEach-Parallel

#################################################
##  Get members of an object using Get-Member  ##
#################################################

# Get all the member of an output object of Get-StartApps
Get-StartApps | Get-Member

# Get all the members and the intrinsic members and compiler-generated 
# members of the objects to the display, but by default they are hidden.
$FirewallRules = Get-NetFirewallRule -Name FPS-*
$FirewallRules | Get-Member -Force
$FirewallRules.psbase

# Get all the extended members of an InputObject, works with pipeline as well
$VMProcessors = Get-VMProcessor -VMName Lab-ClientX
Get-Member -InputObject $VMProcessors -View Extended

# Get all the details of a member by name
Get-NetTCPConnection | Get-Member -Name State | Format-List *

## Get the members by type
Get-NetAdapter | Get-Member -MemberType Properties # All types of properties
Get-NetAdapter | Get-Member -MemberType ScriptProperty # ScriptProperties Only
Get-NetAdapter | Get-Member -MemberType Methods # All methods
Get-NetAdapter | Get-Member -MemberType Method # Only method type
