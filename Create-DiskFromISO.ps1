#requires -Module DISM
#requires -Version 5.0

$ISOFile = 'C:\Workspace\ISO\en_windows_server_2019_x64_dvd_4cb967d8.iso'
$WimImagePath = 'C:\Workspace\WimImage'
$ExtractPath = 'C:\Workspace\Extracted'
$PackagesPath = 'C:\Workspace\Packages'



$MountPoint = (Mount-DiskImage -ImagePath $ISOFile | Get-Volume).DriveLetter
$WimInISO = ($MountPoint, '\sources\install.wim') -join ':'
Copy-Item -Path $WimInISO -Destination $WimImagePath
$WimImage = ($WimImagePath, 'install.wim') -join '\'
Set-ItemProperty -Path $WimImage -Name IsReadOnly -Value $false
$null = Dismount-DiskImage -ImagePath $ISOFile

Get-WindowsImage -ImagePath $WimImage | Select-Object ImageIndex, ImageName, ImageSize
<#
ImageIndex ImageName                                             ImageSize
---------- ---------                                             ---------
         1 Windows Server 2019 Standard                         7988658984
         2 Windows Server 2019 Standard (Desktop Experience)   14175225224
         3 Windows Server 2019 Datacenter                       7983593326
         4 Windows Server 2019 Datacenter (Desktop Experience) 14175533121
#>

# Let's keep Windows Server 2019 Datacenter Core edition and remove other editions from the image
$null = Get-WindowsImage -ImagePath $WimImage | `
Where-Object -FilterScript {$_.ImageName -ne 'Windows Server 2019 Datacenter'} | `
ForEach-Object {Remove-WindowsImage -ImagePath $WimImage -Name $_.ImageName}

# Verify the required edition is exist in the image
Get-WindowsImage -ImagePath $WimImage | Select-Object ImageIndex, ImageName, ImageSize
<#
ImageIndex ImageName                                             ImageSize
---------- ---------                                             ---------
         1 Windows Server 2019 Datacenter                       7983593326
#>

$null = Mount-WindowsImage -ImagePath $WimImage -Index 1 -Path $ExtractPath

Get-WindowsPackage -Path $ExtractPath

Add-WindowsPackage -Path $ExtractPath -PackagePath $PackagesPath

