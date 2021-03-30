function Get-2AdCreds {
if ((Get-StoredCredential -Target global) -eq $null)
    {
    $target = Get-Credential -Message "Enter you GLOBAL SU to store it in Credential Manager. IE: GLOBAL\REDACTED" #specify the Legacy name type in comment, specifically for REDACTED. :)
    New-StoredCredential -Target global -UserName $Target.UserName -Password $target.GetNetworkCredential().Password -Comment '2N AD Account' -Persist Enterprise | Out-Null
    }
$2nCred = Get-StoredCredential -Target global  ##get the cred
Try {Get-ADUser -Identity minstra -Server global.contoso.local -Credential $2ncred | Out-Null} 
Catch [System.Security.Authentication.AuthenticationException]
    {
    $target = Get-Credential -Message "Your Credentials didn't work. Enter you GLOBAL SU to update it in Credential Manager. IE: GLOBAL\REDACTED" #specify the Legacy name type in comment, specifically for REDACTED. :)
    New-StoredCredential -Target global -UserName $Target.UserName -Password $target.GetNetworkCredential().Password -Comment '2N AD Account' -Persist Enterprise | Out-Null
    $2nCred = Get-StoredCredential -Target global ##get the cred
    }
Return $2ncred
}
