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
    Connect-MsolService -Credential $Cred -ErrorAction Stop
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Cred -Authentication Basic -AllowRedirection
    Import-PSSession $Session -DisableNameChecking -AllowClobber

#get all msol users
$MsolUsers = Get-MsolUser -All | 
    where {$_.isLicensed -eq $true} | 
    select  DisplayName,
        UserPrincipalName,
        LastPasswordChangeTimestamp,
        Title,
        Manager


##get EO Manager attr, build PSCustomObject to include all attrs

#get all AD Users
$ADUsers   = Get-ADUser -Filter * -Properties Manager,canonicalName
$ADUsers2n = Get-ADUser -Filter * -Properties Manager,canonicalName -Server global.contoso.local
$AllAdUsers = $ADUsers + $ADUsers2n
$AllEOUsers = Get-User -ResultSize unlimited | select Identity,WindowsEmailAddress,Manager


#convert and compare hash tables, show diffs
$AdUserHash    = ConvertTo-Hashtable -Key UserPrincipalName -Table $AllAdUsers
$MsolUsersHash = ConvertTo-Hashtable -Key UserPrincipalName -Table $MsolUsers
$ADmanagerHash = ConvertTo-Hashtable -Key DistinguishedName -Table $AllAdUsers
$EOmanagerHash = ConvertTo-Hashtable -Key Identity -Table $AllEOUsers
$EOUserHash    = ConvertTo-Hashtable -Key WindowsEmailAddress -Table $AllEOUsers

#init array
$Compare = @()

foreach ($u in $MsolUsers)
    {
    if ($AdUserHash[$u.UserPrincipalName].SamAccountName)
        {

        $Object = [Pscustomobject]@{
            SamAccountName                     = $AdUserHash[$u.UserPrincipalName].SamAccountName
            UserPrincipalName                  = $u.UserPrincipalName
            'AD-Manager'                       = $ADmanagerHash[$AdUserHash[$u.UserPrincipalName].Manager].UserPrincipalName
            'MSOL-Manager'                     = $EOmanagerHash[$EOUserHash[$u.UserPrincipalName].Manager].WindowsEmailAddress
            DistinguishedName                  = $AdUserHash[$u.UserPrincipalName].DistinguishedName
            canonicalName                      = $AdUserHash[$u.UserPrincipalName].canonicalName
            }

        $Compare += $Object
        }
    }

$effedUp = $Compare | where {$_.'AD-Manager' -ne $_.'MSOL-Manager'}
$effedUp | Export-Csv -Path OutofsyncManagers.csv -NoTypeInformation
$csv = Get-ChildItem .\OutofsyncManagers.csv

#SMTP Relay Settings
$smtpServer = "smtp.contoso.com"
$from       = Reports <noreply@contoso.com>"
$to         = "Distro_list@contoso.com"

Send-Mailmessage -smtpServer $smtpServer -from $from -to $to -subject "ADSync Managers Out of Sync" -Body "Out of sync passwords. This is a list of User objects where the Active Directory and Microsoft Online Managers do not match, likley due to an issue with ADSync." -Attachments $csv -ErrorAction Stop