#Must Run Interactive for 1st Run as user running the script; Recommended in Test Mode
#Test mode Switch, $true or $false. Use this to run this Script in Information only mode.
#No changes to MSOLUsers will be made. $TestTo will receive all emails.
$Test = $true
$TestTo = "Steve.Lattina@fleishman.com"

#Logo Branding for Admin Report
##Good source for Logos; https://www.omnicomprgroup.com/agencies/
$RightLogo = "C:\Scripts\MFACompliance\FH-Logo.png"  #Resized to 375 x 120
$LeftLogo  = "C:\Scripts\MFACompliance\PRG-Logo.png" #Resized to 549 x 60

#Admin Email Address for Weekly Report
##This user will be responsible for Auditing Compliance
$Admin = "Steve.Lattina@fleishman.com"

#MFA Exclusion Group Name
##Group of users that are not enforced by this script, but still added to report for audit
$MFAExclusionGroupStr = 'MFA' #'MFA-Exclusion-Group-OPRG'

#SMTP Relay Settings
$smtpServer = "smtpfh.fleishman.com"
$from       = "Service Desk <noreply@omnicomprgroup.com>"

#Email Template for Registering MFA
$MFARegSubject = "Action Required: Enroll your MFA Settings"
$MFARegBody = "
<P>Omnicom and its agencies encounter cyber security threats daily from hostile parties trying to steal valuable information about our company and clients. An effective form of defense is Multi-Factor Authentication (MFA) which adds an additional layer of security when accessing email and other tools.</P>
<P>It's time for you to enroll in MFA to ensure your account is secured.  Once enrolled, MFA will be enabled within 24 hours and you will be notified via email.</P>
<P>Please visit <a href='https://aka.ms/MFAsetup'><em>This Link</em></a> to enroll in Multi-Factor Authentication.</P>
<P>For general information about Multi-Factor Authentication and enrollment options please see <a href='https://fhsharedstorageaccount.blob.core.windows.net/fh-public/mfa/MFA.pdf'><em>This Document</em></a>. The MIS department recommends utilizing the Microsoft Authenticator app as your primary method of MFA.  For step-by-step instructions on setting this up, please see <a href='https://fhsharedstorageaccount.blob.core.windows.net/fh-public/mfa/Pre-Registering Multi-Factor Authentication.pdf'><em>This Document</em></a>.</P>
<P>If you have technical issues with registration, please contact Paige at 888-697-2443 or contact your regional support team in international markets.</P>
"
$MFAEnabSubject = "Notice: MFA has been enabled on your account"
$MFAEnabBody = "
<P>Thank you for Registering your Multi-Factor Authentication (MFA). MFA has been enabled on your account and you will be prompted to finish logging in shortly.</P>
<P>if you need to change your settings at any time, please visit <a href='https://aka.ms/MFAsetup'><em>This Link</em></a> to modify your Multi-Factor Authentication.</P>
<P>For general information about Multi-Factor Authentication and enrollment options please see <a href='https://fhsharedstorageaccount.blob.core.windows.net/fh-public/mfa/MFA.pdf'><em>This Document</em></a>. The MIS department recommends utilizing the Microsoft Authenticator app as your primary method of MFA.  For step-by-step instructions on setting this up, please see <a href='https://fhsharedstorageaccount.blob.core.windows.net/fh-public/mfa/Pre-Registering Multi-Factor Authentication.pdf'><em>This Document</em></a>.</P>
<P>If you have technical issues with MFA, please contact Paige at 888-697-2443 or contact your regional support team in international markets.</P>
"
#############################
#DO NOT EDIT BELOW THIS LINE#
#############################
Start-Transcript -Path "$PSScriptRoot\Log.Log" -Force -Append
#SMTP Encoding
$textEncoding = [System.Text.Encoding]::UTF8 

#Required Modules
##Auto install if not present
If (!(Get-InstalledModule ReportHTML)) #used for Admin Report
    {Install-Module ReportHTML -MinimumVersion 1.4.1.1 -Scope CurrentUser -Force}
if(!(Get-InstalledModule CredentialManager)) #used for O365 Admin Cred storage and recall
    {Install-Module CredentialManager -MinimumVersion 2.0 -Scope CurrentUser -Force}
If (!(Get-InstalledModule MSOnline)) #used for MSOL actions
    {Install-Module MSOnline -Scope CurrentUser -Force}


#Credentials for Office365
##Microsoft says 'Global Admin' is needed to administratively manage MFA, but I use an account with 'User Account Administrator' successfully
##Securely Store creds in Windows Credential Manager
If (!(Get-StoredCredential -Target O365Admin))
    {
    $target = Get-Credential -Message "Login as O365 Admin to store it in Windows Credential Manager."
    New-StoredCredential -Target O365Admin -UserName $Target.UserName -Password $target.GetNetworkCredential().Password -Comment 'O365 Admin' -Persist Enterprise | Out-Null
    }
$Cred = Get-StoredCredential -Target O365Admin

try
{
    Connect-MsolService -Credential $Cred -ErrorAction Stop
    $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Cred -Authentication Basic -AllowRedirection
    Import-PSSession $Session -DisableNameChecking -AllowClobber

}
catch #If error, email Admin with enough info to identify issue. Stored Cred will need stored again
{
    Write-Warning "O365 Credentials Failed. Run Script again to Update Stored Credentials"
    #force user to re-enter cred if it fails
    Remove-StoredCredential -Target O365Admin
    $ErrorBody = "
    <p>Host: $env:COMPUTERNAME</p>
    <p>Script: $PSScriptRoot</p>
    <p>Username: $($cred.username)</p>
    <p>$($error[0].exception.Message)</p>
    <p><strong>Run Test-MFACompliance.ps1 script interactively to update password</strong></p>
    "
    Send-Mailmessage -smtpServer $smtpServer -from $from -to $Admin -subject "MFACompliance Script O365 Credentials Failed" -Body $ErrorBody -BodyAsHtml -priority High -Encoding $textEncoding -ErrorAction Stop

    Break
}
    Write-Verbose "Connected to MSOL Service as $($cred.username)" -Verbose

#Function to Set User's MFA state to enabled, which will prompt them to finish the MFA setup and change them to enforced.
Function Enable-MSOLUserMFA ($UserPrincipalName)
{
    $st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $st.RelyingParty = "*"
    $st.State = "Enabled"
    $sta = @($st)
    Set-MsolUser -UserPrincipalName $UserPrincipalName -StrongAuthenticationRequirements $sta
}
#Get all MSOL users with their MFA Attributes
$MsolUsers = Get-MsolUser -All | 
    where {$_.isLicensed -eq $true} | 
    select  DisplayName,
        UserPrincipalName,
        WhenCreated,
        @{N="MFAStatus"; 
            E={ if( $_.StrongAuthenticationRequirements.State -ne $null)
                { $_.StrongAuthenticationRequirements.State} else { "Disabled"}}},
        @{N="MFAType"; 
            E={ $_.StrongAuthenticationMethods.MethodType }},
        @{N="MFADefaultFlag"; e={($_.StrongAuthenticationMethods).IsDefault} }

#Store Members of the MFA Exclusion group so we can reference them in lower sections
$MFAExclusionGroup = Get-MsolGroup -SearchString $MFAExclusionGroupStr
$MFAExclusionGroupMembers = $MFAExclusionGroup | ForEach-Object {Get-MsolGroupMember -GroupObjectId $_.ObjectId}

#create Arrays
$Results = @()
$ExclusionResults = @()

#Main Logic for Filtering users into arrays
Foreach ($u in $MsolUsers)
    {
    #Build custom array with MSOL user info, and MFA details.
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
        
        #Define Custom object and store it in Array
        $object = [PSCustomObject] @{
            DisplayName       = $u.DisplayName
            UserPrincipalName = $u.UserPrincipalName
            'Account Created' = $u.WhenCreated.GetDateTimeFormats()[64]
            MFAStatus         = $u.MFAStatus
            MFADefaultType    = $DefaultType
            }
        If ($MFAExclusionGroupMembers.EmailAddress -match $u.UserPrincipalName)
            {$ExclusionResults += $object}
        Else 
            {$Results += $object}
    }
#Filter arrays for users that need MFA registered, and enabled for use in later steps.
$UsersMFANotSet          = $Results | Where-Object { ($_.MFAStatus -eq 'Disabled') -and ($_.MFADefaultType) -eq $null }
$UsersMFANotEnabled      = $Results | Where-Object { ($_.MFAStatus -eq 'Disabled') -and ($_.MFADefaultType) -ne $null }

###############################
# AdminLog and Object Actions#
###############################
$AdminLogArray = @()
$AdminLogDIR = "C:\Scripts\MFACompliance"
If ($test) {$AdminLogFile = "$AdminLogDIR\TestMFAComplianceAdminLog.json"}
Else {$AdminLogFile = "$AdminLogDIR\MFAComplianceAdminLog.json"}
if(!(Test-Path -Path $AdminLogFile )){
    New-Item -ItemType Directory -Path $AdminLogDIR -ErrorAction SilentlyContinue -Verbose
    New-Item -ItemType File -Path $AdminLogFile -ErrorAction SilentlyContinue -Verbose
}
$AdminLog = Get-Content -Raw -Path $AdminLogFile | ConvertFrom-Json
$AdminLogMFAEnabUsers = $AdminLog | Where-Object State -eq Enabled

foreach ($user in $UsersMFANotSet)
    {
    If ($Test){  
        Write-Verbose -Message "Pretend Mail $($user.UserPrincipalName)" -Verbose
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $TestTo -subject $MFARegSubject -body $MFARegBody -bodyasHTML -priority High -Encoding $textEncoding -ErrorAction Stop
        }
    Else {
        Write-Verbose -Message "Notifying $($user.UserPrincipalName) to Enroll MFA" -Verbose
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $($user.UserPrincipalName) -subject $MFARegSubject -body $MFARegBody -bodyasHTML -priority High -Encoding $textEncoding -ErrorAction Stop
        }
    #write to log to keep track of how many times they have been notified for admin report
    $EOUser = Get-User -Identity $user.UserPrincipalName | select Manager,office
    $EOUserManagerEmail = if ($EOUser.Manager){Get-User -Identity $EOUser.manager | select WindowsEmailAddress}
    $object = [PSCustomObject] @{
        'Display Name'    = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        'Notices Sent'    = 1
        'Account Created' = $user.'Account Created'
        Manager           = $EOUserManagerEmail.WindowsEmailAddress
        Office            = $EOUser.office
        State             = $user.MFAStatus
        }
    if ($AdminLog.UserPrincipalName -contains $user.UserPrincipalName)
        {
        $v = $AdminLog | Where-Object UserPrincipalName -EQ $user.UserPrincipalName
        $object.'Notices Sent'=$object.'Notices Sent'+$v.'Notices Sent'
        $AdminLogArray += $object
        }
    Else
        {$AdminLogArray += $object}
    }

foreach ($user in $UsersMFANotEnabled)
    {
    ##send an email to user letting them know to expect a MFA prompt shortly
    if ($Test){
        Write-Verbose -Message "Pretend Enable $($user.UserPrincipalName)" -Verbose
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $TestTo -subject $MFAEnabSubject -body $MFAEnabBody -bodyasHTML -priority High -Encoding $textEncoding -ErrorAction Stop
        }
    Else {
        Write-Verbose -Message "Enable MFA on $($user.UserPrincipalName); Emailed Notice to expect login Prompt" -Verbose
        Enable-MSOLUserMFA -UserPrincipalName $($user.UserPrincipalName)
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $($user.UserPrincipalName) -subject $MFAEnabSubject -body $MFAEnabBody -bodyasHTML -priority High -Encoding $textEncoding -ErrorAction Stop

        }
    #write to log to show date MFA Status was enabled for admin report
    $object = [PSCustomObject] @{
        'Display Name'       = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        'Notices Sent'     = $AdminLog.'Notices Sent' | Where-Object UserPrincipalName -EQ $user.UserPrincipalName
        'Date Enabled'  = (get-date).GetDateTimeFormats()[64]
        State             = 'Enabled'
        }
    $AdminLogArray += $object
    }

$AdminLogArray += $AdminLogMFAEnabUsers

$AdminLogArray | ConvertTo-Json | Out-File -FilePath $AdminLogFile

######################################################
# AdminReport
######################################################
$ReportName = "MFA Status Report"
$ReportOutputPath = "$AdminLogDIR\Reports"
if(!(Test-Path -Path $ReportOutputPath )){
    New-Item -ItemType Directory -Path $ReportOutputPath -ErrorAction SilentlyContinue -Verbose
    }


#Test ReportHTML Report
Function Create-Report
{
    param ($Report)
    $rptFile = join-path $ReportOutputPath ($ReportName.replace(" ","") + "-$Report" + ".html")
    $rpt | Set-Content -Path $rptFile -Force
    $rptFile
}
#HTMLReport
$DateRangeStart = (get-date).AddDays(-7).ToShortDateString()
# Create an empty array for HTML strings
$rpt = @()
  
# note from here on we always append to the $rpt array variable.
# First, let's add the HTML header information including report title
$rpt += Get-HTMLOpenPage -TitleText $ReportName -LeftLogoString $LeftLogo -RightLogoString $RightLogo
    #$rpt += Get-HTMLContentOpen -HeaderText "Microsoft Online Users"
        #$rpt += Get-HTMLColumnOpen -ColumnNumber 1 -ColumnCount 2
            $rpt += Get-HTMLContentOpen -HeaderText "Users with no MFA Default Method. Registration Instructions Emailed"
                $rpt += Get-HTMLContentDataTable ($AdminLogArray | Where-Object State -eq "Disabled")
            $rpt += Get-HTMLContentClose
        #$rpt += Get-HTMLColumnClose
        #$rpt += Get-HTMLColumnOpen -ColumnNumber 2 -ColumnCount 2
            $rpt += Get-HTMLContentOpen -HeaderText "Users with MFA that were  Enabled in Date Period: $DateRangeStart to $((get-date).ToShortDateString())"
                $rpt += Get-HTMLContentDataTable ($AdminLogArray | Where-Object State -eq "Enabled")
            $rpt += Get-HTMLContentClose
        #$rpt += Get-HTMLColumnClose

    #$rpt += Get-HTMLContentClose
    $rpt += Get-HTMLContentOpen -HeaderText "$MFAExclusionGroupStr Members"
        $rpt += Get-HTMLContentDataTable $ExclusionResults
    $rpt += Get-HTMLContentClose
  
#  This HTML close adds HTML footer 
$rpt += Get-HTMLClosePage
  
# Manage how report is sent
If ($Test) 
    {
    $MfaReport = Create-Report -Report Test
    Send-Mailmessage -smtpServer $smtpServer -from $from -to $TestTo -subject "Test MFA Admin Report" -Body "TEST: See attached report for $date" -Attachments $MfaReport -priority High -Encoding $textEncoding -ErrorAction Stop
    Invoke-Item $MfaReport
    sleep 1
    }
Else 
    {
    $date = get-date    
    If ($date.DayOfWeek -eq "Friday")
        {
        Write-verbose -Message "Do Admin report stuff" -Verbose
        $RptDate = $date.GetDateTimeFormats()[6]
        $MfaReport = Create-Report -Report $RptDate
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $Admin -subject "MFA Admin Report" -Body "See attached report for $date" -Attachments $MfaReport -priority High -Encoding $textEncoding -ErrorAction Stop
        #Remove enabled users from log file
        $AdminLog = Get-Content -Raw -Path $AdminLogFile | ConvertFrom-Json
        $newAdminLog = $AdminLog | ? {$_.State -ne 'Enabled'}
        $newAdminLog | ConvertTo-Json | Out-File -FilePath $AdminLogFile -Force
        }
    }
    Stop-Transcript
    Remove-PSSession $Session