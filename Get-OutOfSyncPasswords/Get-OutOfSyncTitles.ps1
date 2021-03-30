#password sync issues

#Function for Hashtable Creation
    Function ConvertTo-Hashtable ($Key,$Table){
        $array = @{}
        Foreach ($Item in $Table)
            {
            $array[$Item.$Key.ToString()] = $Item
            }
        $array
    }

#connect to msol
If(!(Get-Module CredentialManager)){Install-Module CredentialManager -Scope CurrentUser}
$Target ="ptadmin@contoso.com"
if ((Get-StoredCredential -Target ptadmin@contoso.com) -eq $null)
    {New-StoredCredential -Target $Target -UserName $Target -Password (Unprotect-CmsMessage -Path C:\Scripts\New-SelfSignedCertCreds\ptadmin\ptadmin-pw.txt -To cn=ptadmin-PSScriptCipherCert) -Comment 'O365 Admin' -Persist Enterprise | Out-Null} #Certificate in Computer Personal store created by new-selfsignedcertcreds
$cred = Get-StoredCredential -Target "ptadmin@contoso.com"
Connect-MsolService -Credential $cred

#get all msol users
$MsolUsers = Get-MsolUser -All | 
    where {$_.isLicensed -eq $true} | 
    select  DisplayName,
        UserPrincipalName,
        LastPasswordChangeTimestamp,
        Title,
        Manager


##get all adsync members
#$ADSyncMembers   = Get-ADGroupMember -Identity "ADsync"
#$ADSyncMembers2n = Get-ADGroupMember -Identity "ADsync" -Server global.contoso.local

#get all AD Users
$ADUsers   = Get-ADUser -Filter * -Properties Title,canonicalName
$ADUsers2n = Get-ADUser -Filter * -Properties Title,canonicalName -Server global.contoso.local
$AllAdUsers = $ADUsers + $ADUsers2n

#convert and compare hash tables, show diffs
$AdUserHash    = ConvertTo-Hashtable -Key UserPrincipalName -Table $AllAdUsers
$MsolUsersHash = ConvertTo-Hashtable -Key UserPrincipalName -Table $MsolUsers

#init array
$Compare = @()

foreach ($u in $MsolUsers)
    {
    if ($AdUserHash[$u.UserPrincipalName].SamAccountName)
        {
        $Object = [Pscustomobject]@{
            SamAccountName                     = $AdUserHash[$u.UserPrincipalName].SamAccountName
            UserPrincipalName                  = $u.UserPrincipalName
            'AD-Title'               = $AdUserHash[$u.UserPrincipalName].Title
            'MSOL-Title' = $u.Title
            DistinguishedName                  = $AdUserHash[$u.UserPrincipalName].DistinguishedName
            canonicalName                      = $AdUserHash[$u.UserPrincipalName].canonicalName
            }
        $Compare += $Object
        }
    }

$effedUp = $Compare | where {$_.'AD-Title' -ne $_.'MSOL-Title'}
$effedUp | Export-Csv -Path Outofsynctitles.csv -NoTypeInformation
$csv = Get-ChildItem .\Outofsynctitles.csv

#SMTP Relay Settings
$smtpServer = "smtpfh.contoso.com"
$from       = Reports <noreply@contoso.com>"
$to         = "DL@contoso.com"

Send-Mailmessage -smtpServer $smtpServer -from $from -to $to -subject "ADSync Titles Out of Sync" -Body "Out of sync passwords. This is a list of User objects where the Active Directory and Microsoft Online Titles do not match, likley due to an issue with ADSync." -Attachments $csv -ErrorAction Stop