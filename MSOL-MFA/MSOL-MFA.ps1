#Run this command and enter the O365 Creds.
#It only needs ran once.
Connect-MsolService

<#
Create a CSV with a single Column for UPN's.
No header is required.
Change the PATH in Quotes below to point at it.
#>
$USERS = Get-content -Path C:\temp\users.csv

<#
Enable-MSOLUserMFA can be run by itself and you can pass single UPN's to it.
#>
Function Enable-MSOLUserMFA ($User)
{
    $st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $st.RelyingParty = "*"
    $st.State = "Enabled"
    $sta = @($st)
    Set-MsolUser -UserPrincipalName $user -StrongAuthenticationRequirements $sta
}

<#
Disable-MSOLUserMFA can be run by itself and you can pass single UPN's to it.
#>
Function Disable-MSOLUserMFA ($User)
{
Set-MsolUser -UserPrincipalName $user -StrongAuthenticationRequirements @()
}

<#
#Run this ForEach loop to enable MFA on all UPN's in the Imported CSV
#>
Foreach ($User in $USERS)
{
    Enable-MSOLUserMFA -User $User
}

<#
#Run this ForEach loop to check MFA on all UPN's in the Imported CSV
#>
Foreach ($User in $USERS)
{
    Get-MsolUser -UserPrincipalName $User | select userPrincipalName,StrongAuthenticationRequirements
}

<#
Run this ForEach loop to disable MFA on all UPN's in the Imported CSV
#>
Foreach ($User in $USERS)
{
    Disable-MSOLUserMFA -User $User
}