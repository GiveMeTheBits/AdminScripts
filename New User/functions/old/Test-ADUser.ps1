    <#
    .Synopsis
       Used to test if a user already exists in AD
    .DESCRIPTION
       Retrieve an AD User Object by querying AD Attributes.
    .EXAMPLE
       Test-ADUser -Identity rogersk -UPN kenny.rogers@constoso.com -Email kenny.rogers@constoso.com -Name "rogers, kenny"
    Test for a user on the current domain
    .EXAMPLE
       Test-ADUser -Identity rogersk -UPN kenny.rogers@constoso.com -Email kenny.rogers@constoso.com -Name "rogers, kenny" -Server constoso.com -Credential (Get-Credemtial)
    Test for a user on a different domain
    #>
    Function Test-ADUser
    {
        [CmdletBinding()]
        [Alias()]
        [OutputType([int])]
        Param
        (
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            Position=0)]
        $Identity,
    
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            Position=1)]
        $UPN,
    
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            Position=2)]
        $Email,
    
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            Position=3)]
        $Name,
    
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            Position=4)]
        $Server,
    
        [Parameter(Mandatory=$false, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true, 
            Position=5)]
        $Credential
        )
    $Filter = "
        (SamAccountName -eq '$Identity')
        -or (UserPrincipalName -eq '$UPN')
        -or (Mail -eq '$Email')
        -or (Name -eq '$Name')
        "
    if ($Server -eq $null)
        {
        $U = Get-ADUser -Filter $Filter -Properties mail
        }
    else
        {
        $U = Get-ADUser -Filter $Filter -Properties mail -Server $Server -Credential $Credential
        }
    
    $UIdentity = $U.SamAccountName
    $UUPN      = $U.UserPrincipalName
    $UEmail    = $U.mail
    $UName     = $U.Name
    
    $result = @()
            if($UIdentity -match $Identity)
                {$result += Write-Warning "SamAccountName $Identity already exists"}
            if($UUPN -match $UPN)
                {$result += Write-Warning "UserPrincipalName $UPN already exists"}
            if($UEmail -match $Email)
                {$result += Write-Warning "Email $Email already exists"}
            if($UName -match $Name)
                {$result += Write-Warning "Name $Name already exists"}
    
    return $result
    }