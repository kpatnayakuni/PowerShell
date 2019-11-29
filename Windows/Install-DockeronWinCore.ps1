$FeatureName = 'Containers'
$ModuleName = 'DockerMsftProvider'
$PackageName = 'Docker'
$RepositoryName = 'PSGallery'

if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host -ForegroundColor Red -BackgroundColor Yellow -Object "!!!Please run as Administrator!!!" 
    return
}

Set-PSRepository -Name $RepositoryName -InstallationPolicy Trusted

$IsFeatureInstalled = Get-WindowsOptionalFeature -FeatureName $FeatureName -Online
if ($IsFeatureInstalled.State -eq 'Disabled')
{
    $FeatureStatus = Enable-WindowsOptionalFeature -FeatureName $FeatureName -Online
    if ($FeatureStatus.RestartNeeded -eq $true)
    {
        Write-Host "Feature installation is completed, and it requires a system reboot." 
        Write-Host "Please run this script again after the system reboot to continue further."
        return
    }
}

$IsModuleInstalled = Get-Module -Name $ModuleName -ListAvailable
if($null -eq $IsModuleInstalled)
{
    Install-Module -Name $ModuleName -Repository PSGallery -Force
}

$IsPackageInstalled = Get-Package -Name $PackageName -ErrorAction SilentlyContinue
if ($null -eq $IsPackageInstalled)
{
    Install-Package -Name $PackageName -ProviderName $ModuleName
}

Set-PSRepository -Name $RepositoryName -InstallationPolicy Untrusted

Get-Service -Name $PackageName
Invoke-Expression "docker version"