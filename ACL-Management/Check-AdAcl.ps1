#Get Member WriteProperty  
$GroupDN = "DC=corp,DC=contoso,DC=com"
$path = "AD:\$GroupDN"
$MemberGuid = "BF9679C0-0DE6-11D0-A285-00AA003049E2" #This guid is for Write Members permission ACL

(Get-Acl -Path $path).access |
Where-Object {($_.ActiveDirectoryRights -eq "WriteProperty") -and ($_.ObjectType -eq $MemberGuid)} |
Format-Table IdentityReference,AccessControlType,IsInherited,ActiveDirectoryRights,@{n="Property";e={((Get-Variable -Name MemberGuid).Name -Split "Guid")[0]}}