If(!(Get-Module Microsoft.Online.SharePoint.PowerShell))
    {Install-Module Microsoft.Online.SharePoint.PowerShell -Scope CurrentUser}

if (!(Get-StoredCredential -Target SPOAdmin)){
    $CredSplat = @{
        Target   = 'SPOAdmin'
        UserName = 'ptadmin@contoso.com'
        Password = (Get-Credential -UserName 'ptadmin@contoso.com' -Message 'SPOAdmin').GetNetworkCredential().Password
        Comment = 'SPOAdmin'
        Persist = "Enterprise"
        }
    New-StoredCredential @CredSplat > $Null
    Remove-Variable CredSplat
    }
$SPOAdmin = Get-StoredCredential -Target SPOAdmin
Connect-SPOService -Url https://$orgName-admin.sharepoint.com -Credential $SPOAdmin
#
#
$UPN = 'user@contoso.com'
#
$SPOSites = Get-SPOSite -Limit All -IncludePersonalSite:$true -Filter { Url -like "/personal/" };
$HashSPOSite = ConvertTo-Hashtable -Key Owner -Table $SPOSites
$SPOUser = Get-SPOUser -LoginName $UPN -Site $HashSPOSite[$UPN].Url
#
#
#Load SharePoint CSOM Assemblies
Set-Location -Path $PSScriptRoot
Add-Type -Path .\SPO-CSOM-DOTNET45\Microsoft.SharePoint.Client.dll
Add-Type -Path .\SPO-CSOM-DOTNET45\Microsoft.SharePoint.Client.Runtime.dll
Add-Type -Path .\SPO-CSOM-DOTNET45\Microsoft.SharePoint.Client.UserProfiles.dll
 
Function Get-SPOUserProfile()
{
    param
    (
        [Parameter(Mandatory=$true)] [string] $AdminSiteURL,
        [Parameter(Mandatory=$false)] [string] $UserAccount,
        [Parameter(Mandatory=$false)] [string] $Property,
        [Parameter(Mandatory=$true)] $Credential
    )    
    Try {
        #Specify tenant admin and URL
        $User = $Credential.UserName
        #Configure Site URL and User
        $SiteURL = $AdminSiteURL
        $Password =  $Credential.Password
        $Creds = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($User,$Password)
        #Bind to Site Collection
        $Context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
        $Context.Credentials = $Creds
        #Identify users in the Site Collection
        $Users = $Context.Web.SiteUsers
        $Context.Load($Users)
        $Context.ExecuteQuery()
        #Create People Manager object to retrieve profile data
        $PeopleManager = New-Object Microsoft.SharePoint.Client.UserProfiles.PeopleManager($Context)
            $UserProfile = $PeopleManager.GetPropertiesFor($UserAccount)
            $Context.Load($UserProfile)
            $Context.ExecuteQuery()
            If ($UserProfile.Email -ne $null)
            {
                $UserProfile.UserProfileProperties | ConvertTo-Json | ConvertFrom-Json
            }
    }
    Catch {
        $_.Exception.Message
    }
}

$UserAccount  = "i:0#.f|membership|$UPN"
$orgName      = "Contosocloud"
$AdminSiteURL = "https://$orgName-admin.sharepoint.com"

$UserProfile = Get-SPOUserProfile -AdminSiteURL $AdminSiteURL -UserAccount $UserAccount -Credential $SPOAdmin
$UserProfile