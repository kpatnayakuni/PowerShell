function Get-Meaning
{
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String] $Word
    )    
    $Uri            = http://www.dictionary.com/browse/$Word"
    $ElementTagName = 'div'
    $ClassName      = 'def-content'

    try {
        $Data       = Invoke-WebRequest -Uri $Uri
    }
    catch {
        Write-Host -ForegroundColor Red "Error: No word found! `nCheck the spelling and try again."
        break
    }

    $Elements       = ($Data.ParsedHtml.getElementsByTagName($ElementTagName) | Where-Object {$_.className -eq $ClassName}).innerText

    $OutLines       = @()
    $Elements | ForEach-Object {$OutLines += '>> ' + $_.Trim()}

    $OriginalColor  = $Host.UI.RawUI.ForegroundColor
    $Host.UI.RawUI.ForegroundColor      = 'Green'
    $OutLines | Select-Object -First 3
    $OutLines       = $OutLines | Select-Object -Skip 3
    foreach ($PrintLine in $OutLines) 
    {
        $origpos    = $Host.UI.RawUI.CursorPosition
        $Host.UI.RawUI.ForegroundColor  = $OriginalColor
        Write-Host -NoNewline '-- More -- (Ctrl+C to exit)'
        $KeyEntered = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
        if ($KeyEntered.VirtualKeyCode -eq 17)
        {
            $KeyHold = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp")
            if ($KeyHold.VirtualKeyCode -eq 67)
            {
                break
            }
        }
        $Host.UI.RawUI.CursorPosition   = $origpos
        ' ' * 40
        $Host.UI.RawUI.CursorPosition   = $origpos
        $Host.UI.RawUI.ForegroundColor  = 'DarkGreen'
        $PrintLine
    }
    $Host.UI.RawUI.ForegroundColor      = $OriginalColor
}