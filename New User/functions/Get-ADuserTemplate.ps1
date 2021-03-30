    <#
    .Synopsis
       Get AD User Template objects in a Searchbase
    .DESCRIPTION
       Retrieve AD User Template Objects by specifying a SearchBase. All Attribute Values are returned.
    .EXAMPLE
       Get-ADUserTemplate -SearchBase 'DC=Contoso, DC=Local'

       Server and Credential Parameters are available

       Get-ADUserTemplate -SearchBase 'DC=Contoso, DC=Local' -Server constoso.local -Credential (Get-Credential)
    #>
    Function Get-ADUserTemplate
    {
        [CmdletBinding()]
        [Alias()]
        Param
        (
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory=$false)]
        $SearchBase,
        
        [Parameter(Mandatory=$false)]
        $Server,
    
        [Parameter(Mandatory=$false)]
        [ValidateNotNullorEmpty()]
        [System.Management.Automation.PSCredential] #Type Definition; will not pass correctly if not declared
        [System.Management.Automation.Credential()] #allows username to passed in param and prompt for password
        $Credential
        )
       
        #Define the filter to query ad with
        $Filter = "(surname -eq 'Template')"
            
        #Define the splat to pass to get-aduser
        $ADSplat = @{Filter      = $Filter
                     Properties  = '*'}
    
        #Pass on properties that were specified to this function
        'Server', 'Credential', 'SearchBase' | Foreach-Object {
            $Parameter = $_
            if($PSBoundParameters.ContainsKey($Parameter))
            {
                $ADSplat.Add($Parameter, $PSBoundParameters[$Parameter])
            }
        }
        #Query AD
        $ADUser = Get-ADUser @ADSplat
        #Outut
        $ADUser
    }
