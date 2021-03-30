$OldIP = [ipaddress]'10.254.40.2'
$NewIP = [ipaddress]'10.31.9.8'

$1 = Get-ADComputer -SearchBase "OU=Servers,DC=corp,DC=contoso,DC=com" -Filter * -Properties operatingSystem,LastLogonDate
$2 = Get-ADComputer -SearchBase "OU=Domain Controllers,DC=corp,DC=contoso,DC=com" -Filter * -Properties operatingSystem,LastLogonDate
$servers = $1 + $2


#TESTING HOW TO SET VIA CIM SESSIONS - WORKS ON machines with WSMAN working, servers on 2008 likely will not have the needed module due to being on WMF 2 or 3
$InScopeArray = @()
$failedWSman = @()
foreach ($server in $servers) {
    Try{
        #$TestCon    = Test-Connection -ComputerName $server.Name -ErrorAction Stop -Count 1 -Quiet
        $testWSMan  = Test-WSMan -ComputerName $server.name -Authentication Default -ErrorAction Stop
        $Cimsession = New-CimSession -ComputerName $server.Name -ErrorAction Stop
        $NetIPConfiguration       = Get-NetIPConfiguration -CimSession $Cimsession -ErrorAction Stop | ? {$_.DNSServer.serveraddresses -contains $OldIP}
        If ($NetIPConfiguration)
            {
            $object = [PSCustomObject]@{
                Name               = $server.name
                NetIPConfiguration = $NetIPConfiguration
                }
            $InScopeArray += $object
            }
        }
    Catch {
        $errObject = [PSCustomObject]@{
            Name = $server.Name
            OS   = $server.OperatingSystem
            LastLogon = $server.LastLogonDate
            Error     = $_.Exception.Message
            FullyQualifiedErrorId = $_.FullyQualifiedErrorId
            }
        $failedWSman += $errObject        
        }
}

Foreach ($server in $InScopeArray){
    $Cimsession = Get-CimSession -ComputerName $server.Name
    $NewServerAddressesarray = @()
    $serveraddresses = $server.NetIPConfiguration.DNSServer.serveraddresses | ? {$_ -notcontains $OldIP}
    $NewServerAddressesarray += $serveraddresses
    $NewServerAddressesarray += $newIP.IPAddressToString
    Write-Verbose -Message $server.Name -Verbose
    #Write-Verbose old -Verbose
    #$serveraddresses
    #Write-Verbose new -Verbose
    #$NewServerAddressesarray
    Set-DnsClientServerAddress -InterfaceIndex $server.NetIPConfiguration.InterfaceIndex -ServerAddresses $NewServerAddressesarray -CimSession $Cimsession #$Cimsession
    #pause
    }
    
    Get-CimSession | Remove-CimSession