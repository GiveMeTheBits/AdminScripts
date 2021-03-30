<#
.DESCRIPTION
   Set the MFA Default and Alternate Method for MSOL Users. 
   Changing the -DefaultMethod expires the current OAuth Ticket and will require the End-user to reconfirm their 2nd factor.
    
        -DefaultMethod will not be modified if not specified
        -AltMethod support setting multiple values, or single, or none.

    Available MethodType options;

        PhoneAppOTP: Show a one-time code in the application. Only if pre-configured by User.
        PhoneAppNotification: Notify through the application. Only if pre-configured by User.
        TwoWayVoiceOffice: Call office phone. Only if Populated in Azure AD User Object.
        OneWaySMS: Text code to mobile phone. Only if pre-configured by User.
        TwoWayVoiceMobile: Call mobile phone. Only if pre-configured by User.
        TwoWayVoiceAlternateMobile: Call Alternate mobile phone. Only if pre-configured by User.


    Detailed Information for Admins;
        https://docs.microsoft.com/en-us/azure/active-directory/authentication/concept-authentication-methods
    Register MFA settings for End users
        https://aka.ms/mfasetup 
.EXAMPLE
   Set-MSOLMFADefaultMethod -UserPrincipalName Zapp.Branigan@Constoso.com -DefaultMethod OneWaySMS -AltMethod PhoneAppNotification,PhoneAppOTP,TwoWayVoiceAlternateMobile,TwoWayVoiceMobile,TwoWayVoiceOffice

.NOTES
    I wanted to added the option to set $User.StrongAuthenticationUserDetails AlternativePhoneNumber and PhoneNumber,
    but these are read-only and Microsoft has not published intent to change it. This must be done by end-users at https://aka.ms/mfasetup.

        https://github.com/MicrosoftDocs/azure-docs/issues/11625

#>
Function Set-MSOLUserMFAMethod 
{
        [CmdletBinding()]
        Param
        (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $UserPrincipalName,
        
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
        [ValidateSet("OneWaySMS","PhoneAppNotification","PhoneAppOTP","TwoWayVoiceMobile","TwoWayVoiceAlternateMobile","TwoWayVoiceOffice")]
        [String[]]$DefaultMethod,

        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
        [ValidateSet("OneWaySMS","PhoneAppNotification","PhoneAppOTP","TwoWayVoiceMobile","TwoWayVoiceAlternateMobile","TwoWayVoiceOffice")]
        [String[]]$AltMethod 

        )

Try 
    {
    $User = Get-MSolUser -UserPrincipalName $UserPrincipalName -ErrorAction Stop
    }
Catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException] 
    {
    If ($_.FullyQualifiedErrorId -eq 'Microsoft.Online.Administration.Automation.UserNotFoundException,Microsoft.Online.Administration.Automation.GetUser')
        {
        Write-Warning -Message "$UserPrincipalName not Found"
        break
        }
    }

$DefaultMFAMethod = $User.StrongAuthenticationMethods | Where-Object {$_.isDefault}

$DefaultMeth = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$DefaultMeth.IsDefault  = $true
$DefaultMeth.MethodType = $DefaultMethod

$AltMeths = @()
Foreach ($Method in $AltMethod)
    {
    $v = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
    $v.IsDefault  = $false
    $v.MethodType = $Method
    $AltMeths += $v
    }

$m = @()
If ($DefaultMeth.MethodType)
    {
    $m += $DefaultMeth
    }
    else 
        {
        $DefaultMeth.MethodType = $DefaultMFAMethod.MethodType
        $m += $DefaultMeth
        }
If ($AltMeths.MethodType)
    {
    $m += $AltMeths
    }


Try {
    Set-MsolUser -Userprincipalname $UserPrincipalName -StrongAuthenticationMethods $m -ErrorAction Stop
    }
Catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException] {
    If ($_.FullyQualifiedErrorId -eq "Microsoft.Online.Administration.Automation.UniquenessValidationException,Microsoft.Online.Administration.Automation.SetUser")
        {Write-Warning -Message "$MethodType is already Default"}
        Else {$_}
    }
Finally {
    $output = Get-MSolUser -UserPrincipalName $UserPrincipalName 
    $output | Select-Object -Property UserPrincipalName -ExpandProperty StrongAuthenticationMethods
    }
}