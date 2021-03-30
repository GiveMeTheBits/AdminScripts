Function Get-ADDomainAllObjects
    {
#Get All Objects ever created that are still in the directory
    $PSArray = [System.Collections.ArrayList]@()
    $AllObjects = Get-ADObject -Filter 'objectclass -eq "user" -or objectclass -eq "computer" -or objectclass -eq "group"' -properties objectclass,samaccountname,whencreated,objectsid,uSNCreated -includeDeletedObjects
    $AllObjects.ForEach(
        {
        $PSArray.Add($_) > $null
        }
    )
    $PSArray
    }##