$GroupList = @{}
$indent = ""
function Get-GroupHierarchy
{
    param
        (
            [Parameter(Mandatory=$true)]
            [String]$searchGroup
        )
    $groupMember = get-adgroupmember $searchGroup | sort-object objectClass -descending
    foreach ($member in $groupMember)
    {
        Write-Host $indent $member.objectclass,":", $member.name;
        if (!($GroupList.ContainsKey($member.name)))
        {
            if ($member.ObjectClass -eq "group")
            {
                 $GroupList.add($member.name,$member.name)
                 $indent += "`t"
                 Get-GroupHierarchy $member.name
                 $indent = "`t" * ($indent.length - 1)  
            }
        }
        Else
        {
            Write-Host $indent "Group:" $member.name "has already been processed, or there is loop... Please verify."  -Fore DarkYellow
        }
    }
}
Get-GroupHierarchy -searchGroup cis-lc  | ? $_ -like "*group*"