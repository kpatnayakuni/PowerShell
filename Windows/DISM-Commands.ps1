break

$imagepath = 'C:\workspace\wimfile\install.wim'
$bootpath = 'C:\workspace\wimfile\boot.wim'
$logpath = 'C:\workspace\logs'
$offlinepath = 'C:\workspace\offline'
$updatespath = 'C:\workspace\updates'
$driverspath = 'C:\workspace\drivers'
$vhdspath = 'C:\workspace\vhds'

Import-Module -Name DISM

Get-WindowsImage -ImagePath $imagepath -Index 1
# 9,17,56,96,563 bytes

Get-WindowsImage -ImagePath $imagepath -Index 3
# 9,36,00,47,298 bytes

Remove-WindowsImage -ImagePath $imagepath -Index 1

Mount-WindowsImage -ImagePath $imagepath -Index 3 -Path $offlinepath

Add-WindowsPackage -Path $offlinepath -PackagePath $updatespath
Get-WindowsPackage -Path $offlinepath

Add-WindowsDriver -Path $offlinepath -Driver $driverspath -Recurse
Get-WindowsDriver -Path $offlinepath
Get-WindowsDriver -Path $offlinepath -All

Get-WindowsOptionalFeature -Path $offlinepath -FeatureName Microsoft-Hyper-V

Enable-WindowsOptionalFeature -Path $offlinepath -FeatureName Microsoft-Hyper-V -All

Dismount-WindowsImage -Path $offlinepath -Save

Dismount-WindowsImage -Path $offlinepath -Discard

New-VHD -Path "$vhdspath\server.vhdx" -SizeBytes 127GB -Dynamic

Mount-VHD -Path "$vhdspath\server.vhdx" 

$disk = Get-VHD -Path "$vhdspath\server.vhdx"

Initialize-Disk -Number $disk.DiskNumber
New-Partition -DiskNumber $disk.DiskNumber -UseMaximumSize -DriveLetter Z

Format-Volume -FileSystem NTFS -NewFileSystemLabel OS -DriveLetter Z

Expand-WindowsImage -ImagePath $imagepath -Index 3 -ApplyPath Z:\ 

Dismount-VHD -Path "$vhdspath\server.vhdx"

.\bcdboot.exe F:\Windows

New-WindowsImage -ImagePath 'C:\workspace\wimfile\win2012.wim' -CapturePath F:\ -Name Win2K12

Get-WindowsImage -ImagePath 'C:\workspace\wimfile\win2012.wim' 

Set-WindowsProductKey -Path $offlinepath -ProductKey ''