$Url = 'https://www.terraform.io/downloads.html'
$DownloadPath = 'C:\Terraform\'
$RegPathKey = 'HKLM:\System\CurrentControlSet\Control\Session Manager\Environment'

if ((Test-Path -Path $DownloadPath) -eq $false) { New-Item -Path $DownloadPath -ItemType Directory -Force }

$Web = Invoke-WebRequest -Uri $Url
$FileInfo = $Web.Links | Where-Object href -match windows_amd64
$DownloadLink = $FileInfo.href
$FileName = Split-Path -Path $DownloadLink -Leaf
$DownloadFile = [string]::Concat( $DownloadPath, $FileName )
Invoke-RestMethod -Method Get -Uri $DownloadLink -OutFile $DownloadFile

Expand-Archive -Path $DownloadFile -DestinationPath $DownloadPath
Remove-Item -Path $DownloadFile -Force

$PathString = (Get-ItemProperty -Path $RegPathKey -Name PATH).Path
$PathString += ";$DownloadPath"
Set-ItemProperty -Path $RegPathKey -Name PATH –Value $PathString

Invoke-Expression -Command "terraform -help"