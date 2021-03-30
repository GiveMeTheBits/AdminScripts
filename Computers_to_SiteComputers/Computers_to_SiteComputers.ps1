#############################################################################################################################
#            Computers_to_SiteComputers                                                                                     #
#    Finds Win Clients ADComputer Object in the BaseComputers CN and places them in the site Container for that site.       #
#    Created By: GiveMeTheBits                                                                                #
#    Created On: 6/12/2018                                                                                                  #
#    Notes: Uses first 3 letters of computers in 'computers' to lookup proper site OU.                                      #
#           Windows client machines with names greater than 12 characters will be moved                                     # 
#           Site ou's or subOU's will have a 3 letter code in the description for matching                                  #
#                                                                                                                           #
#############################################################################################################################

$ComputersOU = 'CN=Computers,DC=corp,DC=contoso,DC=com'
$Computers = Get-ADComputer -SearchBase $ComputersOU -Filter {(OperatingSystem -notlike "*Server*") -and (OperatingSystem -like "*Windows*")} -Properties OperatingSystem | select Name,OperatingSystem,DistinguishedName | where {$_.name.length -ge 12}
$Array = @()
Foreach ($C in $Computers)
    {
    $CompSite = $c.name.substring(0,3)
    $SiteOU = Get-ADOrganizationalUnit -filter {Description -like $CompSite}
    $Win7OU = Get-ADOrganizationalUnit -SearchBase $SiteOU.DistinguishedName -Filter {OU -eq 'Win7'}
    $ComputersOU = Get-ADOrganizationalUnit -SearchBase $SiteOU.DistinguishedName -Filter {OU -eq 'Computers'}
    If ($SiteOU -eq $null){$NewOU = $SiteOU} #if no site code is found for an OU, such as test or other purpose machines
        elseif ($Win7OU -ne $null){$NewOU = $Win7OU} #Win7 OU in each site is preferred because the Win7 to Win10 OU script Task will move them
            elseif ($ComputersOU -ne $null){$NewOU = $ComputersOU} #some sites don't have a win7 ou, so it will use site\computers
                else {$NewOU = $SiteOU} #if Site\computers doesn't exist it will use the OU that the code is in the description of. GMS and GMW are examples. this is because some sites use different codes for the site and for Machine naming (it's dumb, I know.)

    $Object = New-Object PSObject -Property @{ #build custom object for the array with the properties we want in it
        Name = $C.Name
        OperatingSystem = $C.OperatingSystem
        Site = $CompSite
        DistinguishedName = $C.DistinguishedName
        NewOU = $NewOU.DistinguishedName
    } 
    $Array += $Object
    Clear-Variable -Name NewOU #needs to be cleared on each iteration to make sure it doesn't add the previous result to the next object
    }

Foreach ($O in $Array)
    {
    Move-ADObject -Identity $O.DistinguishedName -TargetPath $O.NewOU
    }