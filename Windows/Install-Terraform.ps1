Function Install-Terraform
{
    
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    
    param
    (

        # Local path to download the terraform zip file
        [parameter(Mandatory = $false, ParameterSetName = 'Install')]
        [string] $DownloadPath = 'C:\Terraform\',
    
        # To update terraform 
        [parameter(Mandatory = $true, ParameterSetName = 'Update')]
        [switch] $Update,

        # To install/update with force
        [parameter(Mandatory = $false, ParameterSetName = 'Install')]
        [parameter(Mandatory = $false, ParameterSetName = 'Update')]
        [switch] $Force

    )

    # Verify the OS and exit if it is not Windows
    if (-not ($IsWindows)) 
    { 
        Write-Host "This script is valid only on Windows Operating System." 
        return
    }

    # Ensure to run the function with administrator privilege 
    if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
    { 
        Write-Host -ForegroundColor Red -Object "!!! Please run as Administrator !!!"
        return 
    }
    
    $IsInstallationRequired = $false
    $IsPathSetRequired = $false
    $IsUpdateRequired = $false
    $IsItToFail = $false

    # Terrafrom download Url/Link and remote filename
    $Url = 'https://www.terraform.io/downloads.html'
    $Web = Invoke-WebRequest -Uri $Url
    $FileInfo = $Web.Links | Where-Object href -match windows_amd64
    $DownloadLink = $FileInfo.href
    
    # Teraform latest version from https://terrafrom.io
    $TerraformCurrentVersions = [version]$DownloadLink.Split('/')[-2]
    Write-Verbose -Message $("Terrafrom latest version availble: {0}" -f $TerraformCurrentVersions.ToString())

    # Check the installed version if the terraform is already installed
    Write-Verbose -Message "Checking for existing Terraform installation..."
    $IsTerraformInstalled = Get-Command -Name terraform.exe -ErrorAction SilentlyContinue
    if ($IsTerraformInstalled)
    {
        $TerraformInstalledVersion = [version](@(terraform version)[0]).split(" ")[-1].replace("v", "")
        Write-Verbose -Message $("Found an existing installation, terraform version: {0}" -f $TerraformInstalledVersion.ToString())
        if ($TerraformInstalledVersion -eq $TerraformCurrentVersions)
        {
            $IsInstallationRequired = $false
            $IsUpdateRequired = $false
        }
        elseif ($TerraformInstalledVersion -lt $TerraformCurrentVersions)
        {
            $IsUpdateRequired = $true
            $IsInstallationRequired = $false
        }
        $DownloadPath = Split-Path -Path $IsTerraformInstalled.Source -Parent
    }
    else 
    {
        $IsInstallationRequired = $true
        $IsPathSetRequired = $true
        Write-Verbose -Message "No existing terraform installation detected."    
        # Create the local folder if it doesn't exist
        if ((Test-Path -Path $DownloadPath) -eq $false) 
        { 
            $null = New-Item -Path $DownloadPath -ItemType Directory -Force 
        }
    }

    if ($IsInstallationRequired -ne $IsUpdateRequired)
    {
        # Download the Terraform exe in zip format
        $FileName = Split-Path -Path $DownloadLink -Leaf
        $DownloadFile = Join-Path -Path $DownloadPath -ChildPath $FileName
        Invoke-RestMethod -Method Get -Uri $DownloadLink -OutFile $DownloadFile

        # Extract & delete the zip file
        try
        {
            Expand-Archive -Path $DownloadFile -DestinationPath $DownloadPath -Force:$($Force.IsPresent) -ErrorAction Stop
        }
        catch
        {
            Write-Host -ForegroundColor Red $_.Exception.Message
            $IsItToFail = $true
        }
        finally
        {
            Remove-Item -Path $DownloadFile -Force:$($Force.IsPresent)  
        }
    }
    else 
    {
        $IsItToFail = $true    
    }

    if ($IsItToFail)
    {
        return
    }

    if ($IsPathSetRequired)
    {
        # Reg Key to set the persistent PATH 
        $RegPathKey = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'

        # Setting the persistent path in the registry if it is not set already
        if ($DownloadPath -notin $($ENV:Path -split ';'))
        {
            $PathString = (Get-ItemProperty -Path $RegPathKey -Name PATH).Path
            $PathString += ";$DownloadPath"
            Set-ItemProperty -Path $RegPathKey -Name PATH -Value $PathString

            # Setting the path for the current session
            $ENV:Path += ";$DownloadPath"
        }
    }
    
    # Verify the download
    Invoke-Expression -Command "terraform version"
}