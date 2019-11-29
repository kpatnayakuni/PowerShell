# Create an object
$SQLServerObject = New-Object -TypeName psobject

# Basic properties
$SQLServerObject | Add-Member -MemberType NoteProperty -Name ServerName -Value 'SQLServer'  # Server Name
$SQLServerObject | Add-Member -MemberType NoteProperty -Name DefaultPort -Value 1433        # Port
$SQLServerObject | Add-Member -MemberType NoteProperty -Name Database -Value 'master'       # Database
$SQLServerObject | Add-Member -MemberType NoteProperty -Name ConnectionTimeOut -Value 15    # Connection Timeout
$SQLServerObject | Add-Member -MemberType NoteProperty -Name QueryTimeOut -Value 15         # Query Timeout
$SQLServerObject | Add-Member -MemberType NoteProperty -Name SQLQuery -Value ''             # SQL Query
$SQLServerObject | Add-Member -MemberType NoteProperty -Name SQLConnection -Value ''        # SQL Connection

# Method to ensure the server is pingable
$SQLServerObject | Add-Member -MemberType ScriptMethod -Name TestConnection -Value {
    Test-Connection -ComputerName $this.ServerName -ErrorAction SilentlyContinue
}

# Method to establish the connection to SQL Server and holds the connection object for further use
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

# Execute SQL method to execute queries using the connection established with ConnectSQL
$SQLServerObject | Add-Member -MemberType ScriptMethod -Name ExecuteSQL -Value {

    param
    (
        [Parameter(Mandatory=$false)]
        [string] $QueryText
    )

    # Select runtime query / predefined query
    [string] $SQLQuery = $this.SQLQuery
    if ([string]::IsNullOrEmpty($QueryText) -eq $false)
    {
        $SQLQuery = $QueryText
    }

    # Verify the query is not null and empty, then execute
    if ([string]::IsNullOrEmpty($SQLQuery))
    {
        Write-Host "Please add query to this object or enter the query." -ForegroundColor Red
    }
    else
    {
        if ($this.SQLConnection.State -eq 'Open')
        {
            # SQL Command
            $SQLCommand = New-Object System.Data.SqlClient.SqlCommand
            $SQLCommand.CommandText = $SQLQuery
            $SQLCommand.CommandTimeout = $this.QueryTimeOut
            $SQLCommand.Connection = $this.SQLConnection
            # SQL Adapter
            $SQLAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SQLAdapter.SelectCommand = $SQLCommand
            # Dataset
            $DataSet = New-Object System.Data.Dataset
            $SQLAdapter.Fill($DataSet) | Out-Null
            return $DataSet.Tables[0]
        }
        else
        {
            Write-Host "No open connection found." -ForegroundColor Red
        }
    }
} 

# Return the object
return, $SQLServerObject