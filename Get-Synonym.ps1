Function Get-Synonym
{
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string]$Word
    )
    $Web = New-Object System.Net.WebClient
    $Web.UseDefaultCredentials = $true
    $Web.Proxy.Credentials = $Web.Credentials
    try 
    {
        $Data = $Web.DownloadString("http://www.dictionary.com/browse/$Word")
        $Data = $Data.ToString().Split("`n")
    }
    catch 
    {
        Write-Host -ForegroundColor Red "Error: No word found! `nCheck the spelling and try again."    
    }
    $Found = $false
    $OutLines = @()
    foreach($Line in $Data)
    {
        if ($Found)
        {
            $Found = $false
            $OutLine = $Line.Trim()
            While ($true)
            {
                $StartIndex = $OutLine.IndexOf("<")
                if ($StartIndex -ge 0)
                {
                    $EndIndex = $OutLine.IndexOf(">")
                    if ($EndIndex -lt 0) { Break }
                    $ReplaceLine = $OutLine.Substring($StartIndex,($EndIndex - $StartIndex) + 1)
                    $OutLine = $OutLine.Replace($ReplaceLine,'')
                }
                else 
                {
                    Break    
                }
                $OutLines += '>> ' + $OutLine.Trim()
            }
        }
        if($Line.Trim() -eq '<div class="def-content">')
        {
            $Found = $true
        }
    }
    $OriginalColor = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor = 10
    $OutLines | Select -First 3
    $OutLines = $OutLines | select -Skip 3
    foreach($PrintLine in $OutLines)
    {
        $OrigPos = $Host.UI.RawUI.CursorPosition
        $Host.UI.RawUI.ForegroundColor = $OriginalColor
        Write-Host -NoNewline " -- More -- (Ctrl+C to exit)"
        $KeyEntered = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        if ($KeyEntered.VirtualKeyCode -eq 17)
        {
            $KeyHold = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
            if ($KeyHold.VirtualKeyCode -eq 67)
            {
                Break
            }
        }
        $Host.UI.RawUI.CursorPosition = $OrigPos
        ' ' * 30
        $Host.UI.RawUI.CursorPosition = $OrigPos
        $Host.UI.RawUI.ForegroundColor = 2
        $PrintLine
    }
    $Host.UI.RawUI.ForegroundColor = $OriginalColor
}