$User = Read-Host -Prompt "Enter User Name to Check Password Health"
$LogDays = Read-Host -Prompt "How many days of ADsync Logs to check? (40 is max, less is faster)"
$DCSearch = Read-Host -Prompt "Search all DC's (y/n) (no is faster, yes is more comprehensive)?"
If(!(Get-Module CredentialManager)){Install-Module CredentialManager -Scope CurrentUser}
$Target ="ptadmin@contoso.com"
if ((Get-StoredCredential -Target ptadmin@contoso.com) -eq $null)
    {New-StoredCredential -Target $Target -UserName $Target -Password (Unprotect-CmsMessage -Path C:\Scripts\account-Encrypted.txt -To cn=credential) -Comment 'O365 Admin' -Persist Enterprise | Out-Null}
$cred = Get-StoredCredential -Target "ptadmin@contoso.com"
Connect-MsolService -Credential $cred
$Array = @()
If ($User -like "*@*")
    {
    $ADUser = Get-ADUser -Filter {UserPrincipalName -eq $User} -Properties PasswordLastSet
    If (!($ADUser))
        {
        Write-Warning -Message "$User does not exist in AD"
        Exit
        }
    }
Else
    {
    Try{$ADUser = Get-ADUser -Identity $User -Properties PasswordLastSet}
    Catch
        {
        Write-Warning -Message "$User does not exist in AD"
        Exit
        }
    }
$MSOLUser = Get-MsolUser -UserPrincipalName $ADUser.Userprincipalname
$Object = [Pscustomobject]@{
    SamAccountName                     = $ADUser.SamAccountName
    UserPrincipalName                  = $ADUser.UserPrincipalName
    'AD-PasswordLastSet'               = $ADUser.PasswordLastSet.AddHours(7).GetDateTimeFormats()[104]
    'MSOL-LastPasswordChangeTimestamp' = $MSOLUser.LastPasswordChangeTimestamp.GetDateTimeFormats()[104]
    }
$Object | Format-List
$DCs = @()
If ($DCSearch -eq "y")
    {$DCList = Get-ADDomainController -Filter *}
else
    {$DCList = Get-ADDomainController (Get-ADDomain).PDCEmulator}
$DCs += $DCList
Write-Verbose "Checking ADSync Logs" -Verbose
#ADSync Logs
$i = 1
Foreach ($DC in $DCs)
    {
    Write-Progress -Activity "Checking last 7 days of ADsync Logs on $($DC.name)" -Status "DC $i of $($DCs.Count)" -PercentComplete (($i / $DCs.Count) * 100)
    $path = "\\$($DC.name)\c$\Program Files\AD Sync\Logs"
    $logs = Get-ChildItem -Path $path -File | Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays(-7)}
    $j = 1
    $Array2 = @()
    foreach ($Log in $logs)
        {
        Write-Progress -Id 1 -Activity "$($Log.FullName)" -Status "File $j of $($logs.Count)" -PercentComplete (($j / $logs.Count) * 100)
        $CSV = import-csv -Path $($log.fullname) -Delimiter "`t" -Header Source,Level,Number,Data,TimeStamp
        $Errors = $CSV | Where-Object {($_.Data -like "*$($ADUser.SamAccountName)*") -and ($_.Level -eq "Error")}
        $j++
        If ($Errors)
            {
            Foreach ($e in $Errors)
                {
                $Object2 = [PSCustomObject]@{
                    DC        = $DC.Name
                    Error     = $e.data
                    TimeStamp = (Get-Date $e.Timestamp).GetDateTimeFormats()[104]   #this is in UTC as a string. it can be converted by using get-date $timestamp
                    }
                $Array2 += $Object2
                }
            }
        }
    $i++
    $Array2 | Format-List
    }
Write-Verbose "Checking DirSync Errors" -Verbose
Get-MsolDirSyncProvisioningError -SearchString $ADUser.UserPrincipalName | Format-List -Property DisplayName,UserPrincipalName,LastDirSyncTime,ProvisioningErrors