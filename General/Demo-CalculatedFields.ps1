# Get the total memory in GB from the local computer using the calculated property with Select-Object
Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -Property PSComputerName, `
@{Name = 'Memory in GB'; Expression = {[Math]::Round($_.TotalVisibleMemorySize/1MB)}}

<# Output
PSComputerName Memory in GB
-------------- ------------
Workstation               8
#>

# Get the services where the names are starting with App, and display IsRunning with Yes/No using the calculated property
$IsRunning = @{
    Label = "IsRunning"
    Expression = {
        if($_.Status -eq 'Running') { "Yes" }
        else { "No" }
    }
}
Get-Service -Name App* | Select-Object -Property Name, DisplayName, $IsRunning

<# Output
Name         DisplayName                       IsRunning
----         -----------                       ---------
AppIDSvc     Application Identity              No
Appinfo      Application Information           Yes
AppMgmt      Application Management            No
AppReadiness App Readiness                     No
AppVClient   Microsoft App-V Client            No
AppXSvc      AppX Deployment Service (AppXSVC) No
#>