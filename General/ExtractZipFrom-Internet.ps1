Param
(
    [Parameter(Mandatory = $false)]
    [String]$url = 'https://download.sysinternals.com/files/BGInfo.zip',
    [Parameter(Mandatory = $false)]
    [String]$Destination = 'C:\Extracted'
)
Function Download-File
{
    Param
    (
        [Parameter(Mandatory = $true)]
        [String]$url,
        [Parameter(Mandatory = $false)]
        [String]$ZipFileLocation = "$($env:TEMP)\$(Split-Path -Path $url -Leaf)"
    )
    $WebClient = New-Object -TypeName System.Net.WebClient
    $WebClient.DownloadFile($url,$ZipFileLocation)
    return, $ZipFileLocation
}

Function Extract-ZipFile
{
    Param
    (
        [Parameter(Mandatory = $True)]
        [String]$ZipFileLocation,
        [Parameter(Mandatory = $True)]
        [String]$Destination
    )
    $ExtractShell = New-Object -ComObject Shell.Application
    $files = $ExtractShell.Namespace($ZipFileLocation).Items()
    $ExtractShell.NameSpace($Destination).CopyHere($files)
    Start-Process $Destination
}

$ZipFileLocation = Download-File -url $url
Extract-ZipFile -ZipFileLocation $ZipFileLocation -Destination $Destination