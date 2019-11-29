function Test-ADCredential 
{
    $Credentials = Get-Credential -Message 'Enter your domain credentials'
    $UserName = $Credentials.UserName
    $Password = $Credentials.GetNetworkCredential().Password
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('domain')
    try 
    {
        $Status = $DS.ValidateCredentials($UserName, $Password)
        if ($Status) { Write-Host -ForegroundColor Green "Credentials authenticated successfully!" }
        else { Write-Host -ForegroundColor Red "Credentials authentication failed!" }
    }
    catch { Write-Host -ForegroundColor Red "Credentials authentication failed!" }
}

Test-ADCredential 