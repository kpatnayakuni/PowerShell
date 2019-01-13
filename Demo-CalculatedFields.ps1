Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property Caption, TotalVisibleMemorySize, LastBootUpTime

Get-Service -Name App* | Select-Object 