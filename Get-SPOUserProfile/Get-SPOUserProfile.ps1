Function Get-SPOUserProfile()
{
    param
    (
        [Parameter(Mandatory=$true)] [string] $AdminSiteURL,
        [Parameter(Mandatory=$true)] [string] $UserAccount,
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
            $UserProfile = $PeopleManager.GetPropertiesFor($targetUser)
            $Context.Load($UserProfile)
            $Context.ExecuteQuery()
            If ($UserProfile.Email -ne $null)
            {
                $UserProfile.UserProfileProperties | ConvertTo-Json | ConvertFrom-Json
            }
    }
    Catch {
        write-host -f Red "Error Getting User Profile Properties!" $_.Exception.Message
    }
}

$UserProfile = Get-SPOUserProfile -AdminSiteURL $AdminSiteURL -UserAccount $UPN -Property $Property -Credential $SPOAdmin
$UserProfile 