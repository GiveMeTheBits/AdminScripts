$CSVPath = "$env:TEMP\MSOLMFAStatus.csv" ####Location of Output CSV. you can change this to something else if you prefer
$cred = Get-StoredCredential -Target O365admin
Connect-MsolService -Credential $cred

$users = Get-MsolUser -all | 
Where {$_.isLicensed -eq $true} |
select  DisplayName,
        UserPrincipalName,
        @{N="MFAStatus"; 
            E={ if( $_.StrongAuthenticationRequirements.State -ne $null)
                { $_.StrongAuthenticationRequirements.State} else { "Disabled"}}},
        @{N="MFAType"; 
            E={ $_.StrongAuthenticationMethods.MethodType }},
        @{N="MFADefaultFlag"; e={($_.StrongAuthenticationMethods).IsDefault} }

$Results = @()

Foreach ($u in $users)
    {
    If ($u.MFADefaultFlag.count -eq 1)
        {$DefaultType = $u.MFAType}
    elseif ($u.MFADefaultFlag -ne $null) 
        {
        $count = -1
        Do {$count++}
        While ($u.MFADefaultFlag[$count] -ne $true)
        $DefaultType = $u.MFAType[$count]
        }
    elseif ($u.MFADefaultFlag -eq $null)
        {$DefaultType = $null}


$object = [PSCustomObject] @{
    DisplayName       = $u.DisplayName
    UserPrincipalName = $u.UserPrincipalName
    MFAStatus         = $u.MFAStatus
    MFADefaultType    = $DefaultType
    }
$Results += $object
}
$Results | Select DisplayName,UserPrincipalName,MFAStatus,MFADefaultType | 
Export-Csv -Path $CSVPath -NoTypeInformation
start $CSVPath