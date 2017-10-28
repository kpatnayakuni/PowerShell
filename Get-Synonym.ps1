Function Get-Synonym
{
    Param
    (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [String] $Word
    )
    
    $Uri            = "http://www.thesaurus.com/browse/$Word"
    $ElementTagName = 'span'
    $ClassName      = 'text'

    try {
        $Web        = Invoke-WebRequest -Uri $Uri
    }
    catch {
        Write-Host -ForegroundColor Red "Error:No word found! `nCheckthe spelling and try again."
        break
    }

    $Elements       = $Web.ParsedHtml.getElementsByTagName($ElementTagName)
    $Synonyms       = $Elements | Where-Object { ($_.className -eq $ClassName) -and ($_.nextSibling -ne $null) }
    $Antonyms       = $Elements | Where-Object { ($_.className -eq $ClassName) -and ($_.nextSibling -eq $null) }

    $OriginalColor  = $Host.UI.RawUI.ForegroundColor
    Write-Host -ForegroundColor Yellow 'Synonyms for ' -NoNewline
    Write-Host $Word
    $Host.UI.RawUI.ForegroundColor = 'Green'
    $Synonyms | Select-Object innerText | Format-Wide -Column 6
    $Host.UI.RawUI.ForegroundColor = $OriginalColor

    Write-Host -ForegroundColor Yellow 'Antonyms for ' -NoNewline
    Write-Host $Word
    $Host.UI.RawUI.ForegroundColor = 'Red'
    $Antonyms | Select-Object innerText | Format-Wide -Column 6
    $Host.UI.RawUI.ForegroundColor = $OriginalColor
}