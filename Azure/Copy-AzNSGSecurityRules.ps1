Function Copy-AzNSGSecurityRules
{
    <#
    .SYNOPSIS

    Copies Azure NSG security rules from one NSG to another

    .DESCRIPTION

    Copies all the Azure Network Security Group security rules 
    from one Network Security Group to another Network Security Group.

    It can also create new Network Security Group if the target Network Security 
    doesn't exist.

    .PARAMETER SourceResourceGroupName
    Specify the source Resource Group Name

    .PARAMETER SourceNSGName
    Specify the source Network Security Group Name

    .PARAMETER TargetNSGName
    Specify the target Network Security Group Name

    .PARAMETER SourceNSG
    Specify the source Network Security Group

    .PARAMETER TargetNSG
    Specify the target Network Security Group

    .PARAMETER TargetResourceGroupName
    Specify the target Resource Group Name to create new Network Security Group

    .PARAMETER TargetLocation
    Specify the location to create new Network Security Group

    .INPUTS
    None

    .OUTPUTS
    System.String. Information

    .EXAMPLE

     . .\Copy-AzNSGSecurityRules.ps1
    PS C:\> Copy-AzNSGSecurityRules -SourceResourceGroupName 'rg1' -SourceNSGName 'nsg1' -TargetResourceGroupName 'rg2' -TargetNSGName 'nsg2'

    To copy security rules from the existing source NSG to existing target NSG

    Output:
    Following 2 security rule(s) is/are copied from source NSG 'rg1\nsg1' to target NSG 'rg2\nsg2'
    Deny_Internet, Allow_SqlServer

    .EXAMPLE

     . .\Copy-AzNSGSecurityRules.ps1
    PS C:\> Copy-AzNSGSecurityRules -SourceResourceGroupName 'rg1' -SourceNSGName 'nsg1' -TargetNSGName 'nsg2' -TargetResourceGroupName 'rg2' -TargetLocation 'southindia'

    To create a new NSG and then copy security rules from the existing source NSG

    Output:
    New NSG 'nsg2' has been created in resource group 'rg2' in 'southindia' location.
    Following 2 security rule(s) is/are copied from source NSG 'rg1\nsg1' to target NSG 'rg2\nsg2'
    Deny_Internet, Allow_SqlServer

    (If the target NSG is already existed)
    Output:
    The NSG 'nsg2' is already existed, so vomiting the '-TagetLocation' parameter value and skiping the NSG creation.
    Following 2 security rule(s) is/are copied from source NSG 'rg1\nsg1' to target NSG 'rg2\nsg2'
    Deny_Internet, Allow_SqlServer

    .EXAMPLE

     . .\Copy-AzNSGSecurityRules.ps1
    PS C:\> $nsg1 = Get-AzNetworkSecurityGroup -ResourceGroupName 'rg1' -Name 'nsg1'
    PS C:\> $nsg2 = Get-AzNetworkSecurityGroup -ResourceGroupName 'rg2' -Name 'nsg2'
    PS C:\> Copy-AzNSGSecurityRules -SourceNSG $nsg1 -TargetNSG $nsg2

    To copy security rules from the existing source NSG to existing target NSG (When direct NSG objects are provided)

    Output:
    Following 2 security rule(s) is/are copied from source NSG 'rg1\nsg1' to target NSG 'rg2\nsg2'
    Deny_Internet, Allow_SqlServer

    .EXAMPLE

     . .\Copy-AzNSGSecurityRules.ps1
    PS C:\> $nsg1 = Get-AzNetworkSecurityGroup -ResourceGroupName 'rg1' -Name 'nsg1'
    PS C:\> Copy-AzNSGSecurityRules -SourceNSG $nsg1 -TargetNSGName 'nsg2' -TargetResourceGroupName 'rg2' -TargetLocation 'southindia'

    To create a new NSG and then copy security rules from the existing source NSG (When direct source NSG object is provided)

    Output:
    New NSG 'nsg2' has been created in resource group 'rg2' in 'southindia' location.
    Following 2 security rule(s) is/are copied from source NSG 'rg1\nsg1' to target NSG 'rg2\nsg2'
    Deny_Internet, Allow_SqlServer

    (If the target NSG is already existed)
    Output:
    The NSG 'nsg2' is already existed, so vomiting the '-TagetLocation' parameter value and skiping the NSG creation.
    Following 2 security rule(s) is/are copied from source NSG 'rg1\nsg1' to target NSG 'rg2\nsg2'
    Deny_Internet, Allow_SqlServer

    .NOTES

    This function will accept the following Parameter Sets...
    
    Copy-AzNSGSecurityRules -SourceResourceGroupName <string> -SourceNSGName <string> -TargetResourceGroupName <string> -TargetNSGName <string> [<CommonParameters>]

    Copy-AzNSGSecurityRules -SourceResourceGroupName <string> -SourceNSGName <string> -TargetResourceGroupName <string> -TargetNSGName <string> -TargetLocation <string> [<CommonParameters>]

    Copy-AzNSGSecurityRules -SourceNSG <psobject> -TargetResourceGroupName <string> -TargetNSGName <string> -TargetLocation <string> [<CommonParameters>]

    Copy-AzNSGSecurityRules -SourceNSG <psobject> -TargetNSG <psobject> [-Overwrite] [<CommonParameters>]

    #>

    # Default Parameterset Name is 'Name'
    [CmdLetBinding(DefaultParameterSetName = 'Name')]
    param
    (
        # Source Resource Group Name
        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CreateNew')]
        [string] $SourceResourceGroupName,
        
        # Source NSG Name
        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CreateNew')]
        [string] $SourceNSGName,

        # Source NSG Object
        [Parameter(Mandatory = $true, ParameterSetName = 'NSG')]
        [Parameter(Mandatory = $true, ParameterSetName = 'NewNSG')]
        [psobject] $SourceNSG,
        
        # Target Resource Group Name
        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CreateNew')]
        [Parameter(Mandatory = $true, ParameterSetName = 'NewNSG')]
        [string] $TargetResourceGroupName,

        # Target NSG Name
        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CreateNew')]
        [Parameter(Mandatory = $true, ParameterSetName = 'NewNSG')]
        [string] $TargetNSGName,

        # Target NSG Object
        [Parameter(Mandatory = $true, ParameterSetName = 'NSG')]
        [psobject] $TargetNSG,

        # Target location, NSG to be created 
        [Parameter(Mandatory = $true, ParameterSetName = 'CreateNew')]
        [Parameter(Mandatory = $true, ParameterSetName = 'NewNSG')]
        [string] $TargetLocation,

        [Parameter(Mandatory = $false, ParameterSetName = 'NSG')]
        [switch] $Overwrite
    )

    # Check for source NSG, value by name
    if ($PSCmdlet.ParameterSetName -eq 'Name' -or $PSCmdlet.ParameterSetName -eq 'CreateNew')
    {
        try 
        { 
            Write-Host "Info: Checking for source NSG '$SourceNSGName'..." -ForegroundColor Green
            $SourceNSG = Get-AzNetworkSecurityGroup -ResourceGroupName $SourceResourceGroupName -Name $SourceNSGName -ErrorAction Stop 
            Write-Host ("Info: Source NSG '{0}' is found and it has {1} following security rules...`n{2}" -f $SourceNSGName, $SourceNSG.SecurityRules.Count, ($SourceNSG.SecurityRules.Name -join ', ') ) -ForegroundColor Green

        }
        catch 
        { 
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red 
            return 
        }
    }

    # Check for source NSG, value by NSG object
    if ($PSCmdlet.ParameterSetName -eq 'NSG' -or $PSCmdlet.ParameterSetName -eq 'NewNSG')
    {
        if ($SourceNSG -is [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup])
        {
            Write-Host ("Info: Source NSG '{0}' has {1} following security rules...`n{2}" -f $SourceNSG.Name, $SourceNSG.SecurityRules.Count, ($SourceNSG.SecurityRules.Name -join ', ') ) -ForegroundColor Green
        }
        else
        {
            Write-Host "Error: Please enter a valid Source Network Security Group" -ForegroundColor Red
            return
        }
    }

    if ($SourceNSG.SecurityRules.Count -le 0)
    {
        # When source NSG doesn't have any security rules
        Write-Host ("Error: No security rules found on source NSG {0}" -f $SourceNSG.Name ) -ForegroundColor Red
        return
    }

    # Check for target NSG, value by name
    if ($PSCmdlet.ParameterSetName -eq 'Name')
    {
        try 
        { 
            Write-Host "Info: Checking for target NSG '$TargetNSGName'..." -ForegroundColor Green
            $TargetNSG = Get-AzNetworkSecurityGroup -ResourceGroupName $TargetResourceGroupName -Name $TargetNSGName -ErrorAction Stop 
            Write-Host "Info: Target NSG '$TargetNSGName' is found and ready to copy security rules from source NSG." -ForegroundColor Green
        }
        catch
        { 
            Write-Host "Error: Since there is no NSG with the name '$TargetNSGName' in '$TargetResourceGroupName', please specify '-TargetLocation' parameter to create a new NSG and copy the security rules." -ForegroundColor Red 
            return
        }
    }

    # When target NSG doesn't exist, value by name and NSG object
    if ($PSCmdlet.ParameterSetName -eq 'CreateNew' -or $PSCmdlet.ParameterSetName -eq 'NewNSG')
    {
        # Check for target NSG, if it doesn't exist then create new else continue
        if ($null -eq ($TargetNSG = Get-AzNetworkSecurityGroup -ResourceGroupName $TargetResourceGroupName -Name $TargetNSGName -ErrorAction SilentlyContinue))
        { 
            Write-Host "Info: Target NSG '$TargetNSGName' doesn't exist in '$TargetResourceGroupName' and will be creating new NSG..."
            # Create Resource Group if it doesn't exist 
            try 
            { 
                Write-Host "Info: Checking for Resource Group '$TargetResourceGroupName'..."
                $null = Get-AzResourceGroup -Name $TargetResourceGroupName -Location $TargetLocation -ErrorAction Stop 
                Write-Host "Info: Found an existing Resource Group '$TargetResourceGroupName', and skiping the Resource Group creation."
            }
            catch 
            { 
                Write-Host "Info: Resource Group '$TargetResourceGroupName' doesn't exist and will be creating new Resource Group."
                $null = New-AzResourceGroup -Name $TargetResourceGroupName -Location $TargetLocation 
                Write-Host "Info: Resource Group '$TargetResourceGroupName' has been created in $TargetLocation location."
            }
            $TargetNSG = New-AzNetworkSecurityGroup -ResourceGroupName $TargetResourceGroupName -Name $TargetNSGName -Location $TargetLocation
            Write-Host ("Info: New NSG '{0}' has been created in resource group '{1}' in '{2}' location." -f $TargetNSGName, $TargetResourceGroupName, $TargetLocation ) -ForegroundColor Green
        }
        else 
        {
            Write-Host ("Warning: The NSG '{0}' is already existed, so vomiting the '-TagetLocation' parameter value and skiping the NSG creation." -f $TargetNSGName) -ForegroundColor Yellow
        }
    }

    # For all scenarios incluing when NSG objects are provided
    try
    {
        # Add source NSG security rules to target NSG
        if ($TargetNSG -is [Microsoft.Azure.Commands.Network.Models.PSNetworkSecurityGroup])
        {
            $RulesCopied = @()
            Write-Host ("Info: Copying security rules from the source nsg '{0}' to target nsg '{1}'..." -f $SourceNSG.Name, $TargetNSG.Name) -ForegroundColor Green
            if ($PSCmdlet.ParameterSetName -ne 'NSG' -or ($PSCmdlet.ParameterSetName -eq 'NSG' -and $Overwrite))
            {
                # Overwrites all the existing rules when `-Overwrite` falg is used with NSG parameterset or for any other parametersets
                $TargetNSG.SecurityRules = $SourceNSG.SecurityRules
                $RulesCopied = $TargetNSG.SecurityRules.Name
            }
            else
            {
                # Get the maxmum priority number or assign new
                if ($TargetNSG.SecurityRules.Count -gt 0)
                {
                    $RulePriority = ($TargetNSG.SecurityRules.Priority | Measure-Object -Maximum | ForEach-Object Maximum)
                }
                else 
                {
                    $RulePriority = 990
                }

                # Compare each rule and if that doens't exist then add it to target nsg
                foreach ($Rule in $SourceNSG.SecurityRules)
                {
                    $IsRuleExist = $TargetNSG.SecurityRules | Where-Object { $_.DestinationPortRange -eq $Rule.DestinationPortRange -and $_.Access -eq $Rule.Access -and $_.Direction -eq $Rule.Direction } 
                    if (-not $IsRuleExist)
                    {
                        $Rule.Priority = $RulePriority + 10
                        $TargetNSG.SecurityRules += $Rule
                        $RulesCopied += $Rule.Name
                    }
                    else 
                    {
                        Write-Host ( "Warning: Skipping {0} rule, since it is already exists in the target NetworkSecurityGroup." -f $Rule.Name) -ForegroundColor DarkYellow
                    }
                }
            }
            # Update target NSG
            $null = Set-AzNetworkSecurityGroup -NetworkSecurityGroup $TargetNSG -ErrorAction Stop  # $null used to supress the output
            
            # Success information
            if ($RulesCopied.Count -gt 0)
            {
                Write-Host ("Info: Following {0} security rule(s) is/are copied from source NSG '{1}\{2}' to target NSG '{3}\{4}'" -f $RulesCopied.Count, $SourceNSG.ResourceGroupName, $SourceNSG.Name, $TargetNSG.ResourceGroupName, $TargetNSG.Name) -ForegroundColor Green
                Write-Host ($RulesCopied -join ', ') -ForegroundColor Green
            }
        }
        else 
        {
            Write-Host "Error: Please enter a valid Target Network Security Group" -ForegroundColor Red
            return
        }
    }
    catch
    {
        # Throw error on the host
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red 
    }
}