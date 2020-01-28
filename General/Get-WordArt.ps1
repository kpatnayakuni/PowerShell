param
(
    [string] $Message = 'Hello World',
    [string] $Font,
    [string] $Color
)

$WebSite = 'artii.herokuapp.com'
$EncodeMessage = [uri]::EscapeDataString($Message)    
$uri = "http://$WebSite/make?text=$EncodeMessage"
if ($Font) { $uri += "&font=$Font" }
$IsSuccess = $false

try 
{
    $WordArt = Invoke-RestMethod -Uri $uri -ErrorAction Stop
    $IsSuccess = $true
}

catch
{
    $IsSuccess = $false    
}

finally
{
    if ($IsSuccess)
    {
        if ($Color) { Write-Host $WordArt -ForegroundColor $Color } else { Write-Host $WordArt }
    }
    else
    {
        Write-Host -ForegroundColor DarkRed "Error connecting to '$WebSite'. Please check your internet connection" 
    }
}