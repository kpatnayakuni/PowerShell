Function Get-AzVMImageReferance
{
    [CmdletBinding(DefaultParameterSetName = 'Version')]
    param 
    (
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Skus')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [ArgumentCompleter( { return @(Get-AzLocation | ForEach-Object Location) })]
        [string] $Location,

        [Parameter(Mandatory = $true, ParameterSetName = 'Skus')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [ArgumentCompletions('MicrosoftWindowsServer', 'Canonical')]
        [string] $PublisherName,

        [Parameter(Mandatory = $true, ParameterSetName = 'Skus')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [ArgumentCompleter( {
                param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
                if ($FakeBoundParameters.ContainsKey('PublisherName') -and $FakeBoundParameters.ContainsKey('Location'))
                {
                    return @(Get-AzVMImageOffer -Location $($FakeBoundParameters.Location) -PublisherName $($FakeBoundParameters.PublisherName) | Where-Object Offer -like "$WordToComplete*" | ForEach-Object Offer)
                }
            })]
        [string] $OfferName, 

        [Parameter(Mandatory = $false, ParameterSetName = 'Skus')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Version')]
        [ArgumentCompleter( {
                param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
                if ($FakeBoundParameters.ContainsKey('PublisherName') -and $FakeBoundParameters.ContainsKey('Location') -and $FakeBoundParameters.ContainsKey('OfferName'))
                {
                    return @(Get-AzVMImageSku -Location $($FakeBoundParameters.Location) -PublisherName $($FakeBoundParameters.PublisherName) -Offer $($FakeBoundParameters.OfferName) | Where-Object Skus -like "$WordToComplete*" | ForEach-Object Skus)
                }
            })]
        [string] $SkuName,

        [Parameter(Mandatory = $false, ParameterSetName = 'Skus')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Version')]
        [ArgumentCompleter( {
                param ( $CommandName, $ParameterName, $WordToComplete, $CommandAst, $FakeBoundParameters )
                if ($FakeBoundParameters.ContainsKey('PublisherName') -and $FakeBoundParameters.ContainsKey('Location') -and $FakeBoundParameters.ContainsKey('OfferName') -and $FakeBoundParameters.ContainsKey('SkuName'))
                {
                    return @(Get-AzVMImage -Location $($FakeBoundParameters.Location) -PublisherName $($FakeBoundParameters.PublisherName) -Offer $($FakeBoundParameters.OfferName) -Skus $($FakeBoundParameters.SkuName) | Where-Object Version -like "$WordToComplete*" | ForEach-Object Version)
                }
            })]
        [string] $Version

    )

    if ($SkuName -and ! $Version)
    {
        Get-AzVMImage -Location $Location -PublisherName $PublisherName -Offer $OfferName -Skus $SkuName
    }
    elseif ($SkuName -and $Version)
    {
        Get-AzVMImage -Location $Location -PublisherName $PublisherName -Offer $OfferName -Skus $SkuName -Version $Version
    }
    elseif (! $SkuName -and ! $Version)
    {
        Get-AzVMImageSku -Location $Location -PublisherName $PublisherName -Offer $OfferName
    }

}