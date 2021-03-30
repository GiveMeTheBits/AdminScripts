function Get-ADDomainRIDPool
    {
<#
.SYNOPSIS
    Get RID Allocation Pool
.DESCRIPTION
    Get RID allocation Pool Information from the Active Directory RID Master. Returns the Following information;
        RID Master
            The Current FMSO holder for the RID Master Role
        RIDs Remaining
            The current Amount of Remaining RID's for the lifetime of the domain
        RIDs Issued
            The Current ammount of issued RIDs for the lifetime on the domain
.EXAMPLE
   Get-ADDomainRIDPool -domainDN 'DC=Constoso,DC=Local'
.EXAMPLE
   Get-ADDomainRIDPool -domainDN (Get-ADDomain).DistinguishedName
.LINK
    https://docs.microsoft.com/en-us/openspecs/windows_protocols/ms-adts/d142a27c-65fb-49c9-9e4b-6ede5f226c8a
.NOTES
    RIDs can never be reused. If remaining pool of RIDs is shrinking rapidily, discovery may be needed to determine what is consuming them so quickly. It may indicate faulty provisioning processes.
#>
    param 
        (
            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            $domainDN
        )
    $property = get-adobject “cn=rid manager$,cn=system,$domainDN” -property ridavailablepool -server ((Get-ADDomain $domainDN).RidMaster)
    $rid = $property.ridavailablepool   
    [int32]$totalSIDS = $($rid) / ([math]::Pow(2,32))
    [int64]$temp64val = $totalSIDS * ([math]::Pow(2,32))
    [int32]$currentRIDPoolCount = $($rid) – $temp64val
    $ridsremaining = $totalSIDS – $currentRIDPoolCount
    $RidObject = [PSCustomObject]@{
        'RID Master'     = (Get-ADDomain $domainDN).RidMaster
        'RIDs Remaining' = $ridsremaining
        'RIDs Issued'    = $currentRIDPoolCount
        }
    $RidObject
    }

$domainDN = (Get-ADDomain).DistinguishedName
Get-ADDomainRIDPool -domainDN $domainDN | Format-List