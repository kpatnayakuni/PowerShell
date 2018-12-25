$SQLServerObject = New-Object -TypeName psobject

$SQLServerObject | Add-Member -MemberType NoteProperty -Name ServerName -Value 'SQLServer'
$SQLServerObject | Add-Member -MemberType NoteProperty -Name DefaultPort -Value 1433
$SQLServerObject | Add-Member -MemberType NoteProperty -Name Database -Value 'master'
$SQLServerObject | Add-Member -MemberType NoteProperty -Name ConnectionTimeOut -Value 15
$SQLServerObject | Add-Member -MemberType NoteProperty -Name QueryTimeOut -Value 15
$SQLServerObject | Add-Member -MemberType NoteProperty -Name SQLQuery -Value ''
$SQLServerObject | Add-Member -MemberType NoteProperty -Name SQLConnection -Value ''

$SQLServerObject | Add-Member -MemberType ScriptMethod -Name ConnectSQL -Value {
    
    [string] $ServerName= $this.ServerName
    [int] $Port         = $this.DefaultPort
    [string] $Database  = $this.Database
    [int] $TimeOut      = $this.ConnectionTimeOut

    $SQLConnection = New-Object -TypeName System.Data.SqlClient.SqlConnection
    $SQLConnection.ConnectionString = "Server = $ServerName,$Port; Database = $Database; Integrated Security = True;Connection Timeout=$TimeOut;"
    $SQLConnection.Open()

    $this.SQLConnection = $SQLConnection
}

$SQLServerObject | Add-Member -MemberType ScriptMethod -Name ExecuteSQL -Value {

    if ([string]::IsNullOrEmpty($this.SQLQuery))
    {
        Write-Host "Please add sql query to this object, by using .SQLQuery property." -ForegroundColor Red
    }
    else
    {
        if ($this.SQLConnection.State -eq 'Open')
        {
            $SQLCommand = New-Object System.Data.SqlClient.SqlCommand
            $SQLCommand.CommandText = $this.SQLQuery
            $SQLCommand.CommandTimeout = $this.QueryTimeOut
            $SQLCommand.Connection = $this.SQLConnection

            $SQLAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SQLAdapter.SelectCommand = $SQLCommand

            $DataSet = New-Object System.Data.Dataset
            $SQLAdapter.Fill($DataSet) | Out-Null
            return $DataSet.Tables[0]
        }
        else
        {
            Write-Host "No open connection found, run .ConnectSQL()" -ForegroundColor Red
        }
    }
}

$SQLServerObject | Add-Member -MemberType ScriptMethod -Name TestConnection -Value {
    Test-Connection -ComputerName $this.ServerName -ErrorAction SilentlyContinue
} 

return, $SQLServerObject