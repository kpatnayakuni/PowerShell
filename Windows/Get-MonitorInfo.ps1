Function Get-MonitorInfo
{
    [CmdletBinding(DefaultParameterSetName = 'OnScreen')]

    param
    (
        [parameter(Mandatory = $false, ParameterSetName = 'OnScreen')]
        [parameter(Mandatory = $false, ParameterSetName = 'Export')]
        [Alias('CN')]
        [string[]] $ComputerName = 'localhost',

        [parameter(Mandatory = $true, ParameterSetName = 'Export')]
        [switch] $ExportToCSV,

        [parameter(Mandatory = $true, ParameterSetName = 'Export')]
        [string] $ExportFileName
    )
    
    Begin
    {
        $DoNotRun = $false
        if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
        { 
            Write-Host -ForegroundColor Red -Object "!!! Please run as Administrator !!!"
            $DoNotRun = $true
        }
    }
    Process
    { 
        if ($DoNotRun) { return }
        $NameSpace = 'ROOT/wmi'
        $ClassName = 'WmiMonitorID'
        $MonitorInfo = Get-CimInstance -Namespace $NameSpace -ClassName $ClassName -ComputerName $ComputerName 
        $Output = ForEach ($Monitor in $MonitorInfo)  
        {
            New-Object -TypeName psobject -Property @{
                ComputerName = $Monitor.PSComputerName
                Manufacturer = ($Monitor.ManufacturerName -notmatch '^0$' | ForEach-Object { [char]$_ }) -join ""
                Name         = ($Monitor.UserFriendlyName -notmatch '^0$' | ForEach-Object { [char]$_ }) -join ""
                Serial       = ($Monitor.SerialNumberID -notmatch '^0$' | ForEach-Object { [char]$_ }) -join ""
                Year         = $Monitor.YearOfManufacture
            }
        }
    }
    End
    {
        if ($DoNotRun) { return }
        if ($ExportToCSV)
        {
            if (-not (Test-Path -Path $ExportFileName))
            {
                $null = New-Item -Path $ExportFileName -ItemType File -Force
            }
            $Output | Select-Object -Property ComputerName, Manufacturer, Name, Serial, Year | Export-Csv -Path $ExportFileName
        }
        else
        {
            $Output | Select-Object -Property ComputerName, Manufacturer, Name, Serial, Year | Format-Table -AutoSize
        }  
    }
}