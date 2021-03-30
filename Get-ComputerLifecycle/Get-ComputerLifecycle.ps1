#https://support.microsoft.com/en-us/help/13853/windows-lifecycle-fact-sheet
$comps = Get-ADComputer -Filter {operatingsystem -like "*windows 10*"} -Properties description,operatingsystem,OperatingSystemVersion
$Versions = @{
    '10.0 (18363)' = 'Windows 10 (1909)' 
    '10.0 (18362)' = 'Windows 10 (1903)' 
    '10.0 (17763)' = 'Windows 10 (1809)' 
    '10.0 (17134)' = 'Windows 10 (1803)' 
    '10.0 (16299)' = 'Windows 10 (1709)' 
    '10.0 (15063)' = 'Windows 10 (1703)' 
    '10.0 (14393)' = 'Windows 10 (1607)' 
    '10.0 (10586)' = 'Windows 10 (1511)' 
    '10.0 (10240)' = 'Windows 10 (1507)'	    
    }
$Lifecycle = @{
    '10.0 (18363)' = "5-11-2021"
    '10.0 (18362)' = "12-8-2020"
    '10.0 (17763)' = "5-12-2020"
    '10.0 (17134)' = "11-12-2019"
    '10.0 (16299)' = "4-9-2019"
    '10.0 (15063)' = "10-9-2018"
    '10.0 (14393)' = "4-10-2018"
    '10.0 (10586)' = "10-10-2017"
    '10.0 (10240)' = "5-9-2017"
    }
$array = @()
Foreach ($comp in $comps)
    {
    $Version = $Versions[$comp.OperatingSystemVersion].ToString()
    $EOL     = (Get-Date $Lifecycle[$comp.OperatingSystemVersion]).GetDateTimeFormats()[5]
    $object  = [PSCustomObject]@{
        'OperatingSystem'   = $Version
        'EOL'               = $EOL
        'DistinguishedName' = $comp.DistinguishedName
        'Description'       = $comp.Description
        }
    $array += $object
    }
$array |  Out-GridView