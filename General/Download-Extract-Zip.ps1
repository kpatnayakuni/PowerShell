$Url        = 'https://download.sysinternals.com/files/BGInfo.zip'
$ZipFile    = 'C:\ZipFolder\' + $(Split-Path -Path $Url -Leaf)
$Destination= 'C:\Extracted\'

Invoke-WebRequest -Uri $Url -OutFile $ZipFile

$ExtractShell   = New-Object -ComObject Shell.Application
$Files          = $ExtractShell.Namespace($ZipFile).Items()
$ExtractShell.NameSpace($Destination).CopyHere($Files)
Start-Process $Destination