function Get-LoggedOnUser
 {
     [CmdletBinding()]
     param
     (
         [Parameter()]
         [ValidateScript({ Test-Connection -ComputerName $_ -Quiet -Count 1 })]
         [ValidateNotNullOrEmpty()]
         [string[]]$ComputerName = $env:COMPUTERNAME
     )
     foreach ($comp in $ComputerName)
     {
         $output = @{ 'ComputerName' = $comp }
         $output.UserName = (Get-WmiObject -Class win32_computersystem -ComputerName $comp).UserName
         [PSCustomObject]$output
     }
 }

 $comps = Get-ADComputer -SearchBase "OU=New York,OU=United States,OU=NA,DC=corp,DC=contoso,DC=com" -Filter *
 $array = @()
 foreach ($c in $comps) {
 $name = $c.name
 $user = Get-LoggedOnUser -ComputerName $name
 $array += $user
 }
 $array
