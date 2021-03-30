Function New-Search ($Thing){
    $SearchThing = Get-ADObject -Filter {samaccountname -eq $Thing} -Properties objectSid,sAMAccountName
    [PSCustomObject]@{
        DN = $SearchThing.DistinguishedName
        SID = $SearchThing.objectSid
        SAM = $SearchThing.sAMAccountName
        }
}
Function Get-ADDelegations{
    $DC = $env:LOGONSERVER.Split('\\')[2]
    $filter = "(|(objectClass=domain)(objectClass=organizationalUnit)(objectClass=group)(sAMAccountType=805306368)(objectCategory=Computer)(objectCategory=contact)(objectClass=inetOrgPerson))" #Search common delegation targets
    $RootDN = (Get-ADDomain).DistinguishedName
    #$filter = "(|(objectClass=organizationalUnit)(objectClass=group))" #Search just OUs and Groups
    #More filters can be found here: http://www.ldapexplorer.com/en/manual/109050000-famous-filters.htm
    
    #$bSearch = New-Object System.DirectoryServices.DirectoryEntry("LDAP://DOMAINCONTROLLER/LDAP"), "USERNAME", "PASSWORD") #connect to DOMAINCONTROLLER using LDAP path, USERNAME and PASSWORD
    $bSearch = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$DC/$RootDN") #connect to DOMAINCONTROLLER using LDAP path
    
    $dSearch = New-Object System.DirectoryServices.DirectorySearcher($bSearch)
    $dSearch.SearchRoot = $bSearch
    $dSearch.PageSize = 1000
    $dSearch.Filter = $filter #comment out to look at all object types
    $dSearch.SearchScope = "Subtree"
    
    $extPerms = ` #List of extended permissions available here: https://technet.microsoft.com/en-us/library/ff405676.aspx
            '00299570-246d-11d0-a768-00aa006e0529', #reset password
            'ab721a54-1e2f-11d0-9819-00aa0040529b', #send as
            '0'
    
    
    foreach ($objResult in $dSearch.FindAll())
    {
        $obj = $objResult.GetDirectoryEntry()
    
        #Write-Host "Searching... " $obj.distinguishedName
    
        $permissions = ($obj.PsBase.ObjectSecurity.GetAccessRules($true,$false,[Security.Principal.NTAccount])).Where({ `
                $_.AccessControlType -eq 'Allow' -and ($_.ObjectType -in $extPerms) -and $_.IdentityReference -notin ('NT AUTHORITY\SELF', 'NT AUTHORITY\SYSTEM', 'S-1-5-32-548') `
                })
        if ($permissions){
            [pscustomobject]@{
                Object     = $obj.distinguishedName
                Account    = $permissions.IdentityReference
                Permission = $permissions.ActiveDirectoryRights
                }
            }
    }
}
$results = Get-ADDelegations

$Search = New-Search -Thing (read-host -Prompt "sam of thing")
$Search
$results | Where {($_.Account -eq $SearchSID) -or ($_.Account -like "*$($Search.SAM)*")} | Out-GridView