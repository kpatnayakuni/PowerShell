Function Wish-HappyNewYear
{
    Clear-Host
    $Message = 'Happy New Year'
    $Year = '2020'.PadLeft(($Message.Length - 1) * 2)
    $Line = "*" * $($Message.Length + 3)
    $WebSite = 'artii.herokuapp.com'
    $CurPos = $host.UI.RawUI.CursorPosition

    try 
    {
        $Wishes = @()
        $Line, $Message, $Year, $Line | ForEach-Object {
            $EncodeMessage = [uri]::EscapeDataString($_)    
            $uri = "http://$WebSite/make?text=$EncodeMessage&font=5lineoblique"
            $Wishes += Invoke-RestMethod -Uri $uri -ErrorAction Stop
        }
    
        [System.Enum]::GetValues([System.ConsoleColor]) | ForEach-Object {
            $host.UI.RawUI.CursorPosition = $CurPos
            Write-Host $Wishes -ForegroundColor $_
            Start-Sleep 1
        }
    }
    catch
    {
        Write-Host -ForegroundColor DarkRed "Error connecting to '$WebSite'. Please check your internet connection" 
    }
}
