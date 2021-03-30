#PasswordNeverExpires $True for ISE Site; only on Template user, default for new-aduser will be generate a password
#ChangePasswordAtLogon $True for non-ISE sites; use the PasswordExpired Attribute to determine if this needs set to $True

function New-AdAccountFromTemplate
{ 
        [CmdletBinding()]
        [Alias()]
        Param
        (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $TemplateUserObject,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $Name,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $SamAccountName,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $GivenName,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $Surname,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $UserPrincipalName,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        #[Security.SecureString]    #using SecureString encrypts the string in memory so that cleartext credentials are not sent accross the network
        $AccountPassword,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $Description,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $EmailAddress,
        
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
        $AccountExpirationDate,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
        $Server,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential] #Type Definition; will not pass correctly if not declared
        [System.Management.Automation.Credential()] #allows username to passed in param and prompt for password
        $Credential


        )
####get the Parent Container of the AD Template User       
$Path = ([adsi]"LDAP://$($TemplateUserObject.DistinguishedName)").Parent

####Splatting the Mandatory Fields for a new AD user
$NewADUserVars = @{
Name                  = $Name
SamAccountName        = $SamAccountName
GivenName             = $GivenName
Surname               = $Surname
DisplayName           = $Name
UserPrincipalName     = $UserPrincipalName
AccountPassword       = $AccountPassword
Path                  = $Path.Replace("LDAP://",'') #remove the LDAP portion of the string
EmailAddress          = $EmailAddress
Description           = $Description 
AccountExpirationDate = $AccountExpirationDate
}
####Splatting the fields that may be blank
$SetADUserSplat = @{
ScriptPath = $TemplateUserObject.ScriptPath 
employeeID = $TemplateUserObject.EmployeeID
}
####Create a new Splat with keys that are not blank
$SetADUserVars = @{
Identity = $SamAccountName 
}
     $SetADUserSplat.GetEnumerator() | Foreach-Object {
            if($_.Value.Length -gt 0)
            {$SetADUserVars.Add($_.Key,$_.Value)}
            }
<#
Splatting fields that need to use the -add switch
These cannot be passed on the main Set-ADuser, and must be done seperately
#>
$SetAduserVars2 = @{
extensionAttribute2 = $TemplateUserObject.extensionAttribute2
otherMobile         = $TemplateUserObject.otherMobile
otherPager          = $TemplateUserObject.otherPager
}

#Pass on Params if specified to this function
$CredSplat = @{}
'Server', 'Credential' | Foreach-Object {
    $Parameter = $_
        if($PSBoundParameters.ContainsKey($Parameter))
            {
            $CredSplat.Add($Parameter, $PSBoundParameters[$Parameter])
            }
}
####DEBUG####

#$NewADUserVars
#$SetADUserVars
#$SetAduserVars2
#$CredSplat

####Create the user
New-ADUser @NewADUserVars @CredSplat
####Set the additional Attributes from the Template User
Set-ADuser @SetADUserVars @CredSplat
####Set the -Add Attributes
    $SetAduserVars2.GetEnumerator() | ForEach-Object {
        $Key = $_.Key
        $Value = $_.Value
        if($Value.length -gt 0)
        {
        Set-ADUser $SamAccountName -Add @{$key = "$Value"} @CredSplat
        }
    }
####Expire the Password for non-ISE Sites
    If ($TemplateUserObject.PasswordExpired)
    {
    Set-ADUser $SamAccountName -ChangePasswordAtLogon $true @CredSplat
    }
####Enable the Account
Enable-ADAccount -Identity $SamAccountName @CredSplat
####Copy Group Memberships from Template user to New AD user
    $templateuserobject.MemberOf.GetEnumerator() | ForEach-Object {
    Add-ADGroupMember -Identity $_ -Members $SamAccountName -Confirm:$false @CredSplat
    }
}


####TESTING   #####Need to add Acct Expiration
#$AdTemplate = Get-ADUserTemplate -SearchBase 
#New-AdAccountFromTemplate -TemplateUserObject $AdTemplate -Name "user, test" -SamAccountName testuser -GivenName Test -Surname user -UserPrincipalName test.user@contoso.com -Description "test desc" -EmailAddress test.user@contoso.com -AccountExpirationDate "11/14/2018" -Credential (Get-Credential) -AccountPassword $AccountPassword