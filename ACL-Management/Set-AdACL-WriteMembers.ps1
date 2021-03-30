Import-Module ActiveDirectory

#### Get the Object that we want to modify permissions on
$GroupDN = "CN=Object,OU=Container,DC=corp,DC=contoso,DC=com"

#### Get the object which will be assigned the new permission
$Group = Get-ADGroup "AD Group" -Properties * #get the group object which will be assigned with Full Control permission within an OU

#### Parameters for new ACE
$identity = new-object System.Security.Principal.NTAccount($group.SamAccountName)
$WritePropertiesObject = [System.DirectoryServices.ActiveDirectoryRights]::"WriteProperty"
$AllowObject = [System.Security.AccessControl.AccessControlType]::"Allow"
$WriteMembersGUID = [GUID]'BF9679C0-0DE6-11D0-A285-00AA003049E2' #This guid is for Write Members permission ACL

#### Create ACE with Constructor
$NewAccessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule ($identity,$WritePropertiesObject,$AllowObject,$WriteMembersGUID)

#### Apply ACL
$path = "AD:\$GroupDN"
$ACL = Get-Acl -Path $path
$ACL.SetAccessRule($NewAccessRule)
Set-Acl -Path $path -AclObject $ACL