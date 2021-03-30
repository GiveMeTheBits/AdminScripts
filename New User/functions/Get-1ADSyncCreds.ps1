function Get-1ADSyncCreds {
$Target ="adsync@contoso.com"
if ((Get-StoredCredential -Target adsync@contoso.com) -eq $null)
    {New-StoredCredential -Target $Target -UserName $Target -Password (Unprotect-CmsMessage -Path C:\Scripts\account-Encrypted.txt -To cn=cert) -Comment 'CPSM Service Account' -Persist Enterprise | Out-Null}
$ADSyncCreds = Get-StoredCredential -Target $Target ##get the cred
return $ADSyncCreds
}
