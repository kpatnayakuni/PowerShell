<#
This script pulls the date and the time on which the Azure VM(s) created.
This script accepts Resource Group & VM Name as mandatory parameters and accepts VM object(s) optionally.
Since there is no direct Cmdlet to fetch the create date, it is considered the disk create date as VM create date.
#>
Function Get-AzVMCreateDate
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $ResourceGroupName,                                        # Resource Group Name
        [parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
        [string] $Name,                                                     # VM Name
        [parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [System.Object[]] $VMObject                                         # VM Object
    )
    
    Begin
    {
        # Check if the VM Object is from the pipeline
        $IsItVMObject = $null -ne $VMObject

        # Checking login, if not asking for the login
        if (($IsItVMObject -eq $false) -and ($null -eq $(Get-AzContext -ErrorAction SilentlyContinue)))
        {
            Login-AzAccount
        }

        # Output array object
        $VMArray = @()
    }

    Process
    {
        # Fetching the VM details from Resource Group Name and VM Name if provided
        if ($IsItVMObject -eq $false)
        {
            $VMObject = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $Name
        }
        foreach ($VM in $VMObject)
        {
            # Get the OS Disk Name
            $VMDiskName = $VM.StorageProfile.OsDisk.Name

            # Get the Disk Info
            $VMDiskInfo = Get-AzDisk -ResourceGroupName $VM.ResourceGroupName -DiskName $VMDiskName

            # Get disk create date & time
            $VMCreatedDate = $VMDiskInfo.TimeCreated

            # Add result to the output array
            $VMArray += New-Object -TypeName psobject -Property @{
                ResourceGroup = $VM.ResourceGroupName
                VMName = $VM.Name
                CreateDate = $VMCreatedDate
            }
        }

    }
    
    End
    {
        # Output
        return ($VMArray | Select-Object ResourceGroup, VMName, CreateDate)
    }
    
}

<# Load the function
    PS /> . ./Get-AzVMCreateDate.ps1    # on Linux
    PS \> . .\Get-AzVMCreateDate.ps1    # on Windows
#>

<# Calling the function
    PS > Get-AzVMCreateDate
#>