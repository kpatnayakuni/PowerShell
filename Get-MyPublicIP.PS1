Param
(
    [Parameter(Mandatory=$True,ParameterSetName = 'IP')]
    [System.Net.IPAddress]$IP,
    [Parameter(Mandatory=$True,ParameterSetName = 'Info')]
    [switch]$Info
)

if ($ParameterSetName = 'IP')
{
    Invoke-RestMethod http://ipinfo.io/$IP
}

if ($ParameterSetName = 'Info')
{
    Invoke-RestMethod http://ipinfo.io/json
}