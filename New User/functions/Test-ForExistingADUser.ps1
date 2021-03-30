    <#
    .Synopsis
       Used to test if a user already exists in AD
    .DESCRIPTION
       Retrieve an AD User Object by querying AD Attributes. If any of the Values are existing, a Warning will be displayed showing which attribute and value are in conflict, even across multiple user objects. 
    .EXAMPLE
       Test-ForExistingADUser -SamAccountName rogersk -UserPrincipalName kenny.rogers@constoso.com -Email kenny.rogers@constoso.com -Name "rogers, kenny"
    Test for a user on the current domain
    .EXAMPLE
       Test-ForExistingADUser -SamAccountName rogersk -UserPrincipalName  kenny.rogers@constoso.com -Email kenny.rogers@constoso.com -Name "rogers, kenny" -Server constoso.com -Credential (Get-Credential)
    Test for a user on a different domain
    #>
    Function Test-ForExistingADUser
    {
        [CmdletBinding()]
        [Alias()]
        [OutputType([boolean])]
        Param
        (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $Samaccountname,
    
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $UserPrincipalName,
    
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $Email,
    
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$true)]
        $Name,
    
        [Parameter(Mandatory=$false)]
        $Server,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential] #Type Definition; will not pass correctly if not declared
        [System.Management.Automation.Credential()] #allows username to passed in parm and prompt for password
        $Credential
        )
    
        #Used for output
        [boolean]$FoundMatch = $False
    
        #Define the filter to query ad with
        $Filter = "
        (SamAccountName -eq '$SamAccountName')
        -or (UserPrincipalName -eq '$UserPrincipalName')
        -or (Mail -eq '$Email')
        -or (Name -eq '$Name')
        "
    
        #Define the splat to pass to get-aduser
        $ADSplat = @{Filter      = $Filter
                     Properties  = 'Mail'
                     ErrorAction = 'SilentlyContinue'}
    
        #Pass on properties that were specified to this function
        'Server', 'Credential' | Foreach-Object {
            $Parameter = $_
            if($PSBoundParameters.ContainsKey($Parameter))
            {
                $ADSplat.Add($Parameter, $PSBoundParameters[$Parameter])
            }
        }
    
        #Query AD
        $ADUser = Get-ADUser @ADSplat
        #Define the tests to run
        $Tests = @{SamAccountName    = $ADUser.SamAccountName
                   UserPrincipalName = $ADUser.UserPrincipalName
                   Email             = $ADUser.Mail
                   Name              = $ADUser.Name}
        #Run the tests, if match found set the FoundMatch
    
        $Tests.GetEnumerator() | ForEach-Object {
            if($PSBoundParameters[$_.Key] -in $_.Value)
            {
                $FoundMatch = $True
                Write-Warning "$($_.Key): $($PSBoundParameters[$_.Key]) already exists" #$($PSBoundParameters[$_.Key] returns the input value instead of the returned $test values. This is to account for multiple User objects being returned.
            }
        }
        #Output - returns true or false
        $FoundMatch    
    }