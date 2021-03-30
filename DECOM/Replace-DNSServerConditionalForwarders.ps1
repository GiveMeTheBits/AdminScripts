
$1 = Get-ADComputer -SearchBase "OU=Servers,DC=corp,DC=contoso,DC=com" -Filter * -Properties operatingSystem,LastLogonDate
$2 = Get-ADComputer -SearchBase "OU=Domain Controllers,DC=corp,DC=contoso,DC=com" -Filter * -Properties operatingSystem,LastLogonDate
$servers = $1 + $2

$DNSServers = @()
foreach ($server in $servers)
    {
    $DNSBool = Test-NetConnection -ComputerName $server.dnshostname -Port 53 -InformationLevel Quiet
    If ($DNSBool){$DNSServers += $server}
    }


$DNSArray = @() #INIT

$OldIP = [ipaddress]'10.31.9.5'
$NewIP = [ipaddress]'10.31.9.8'

Foreach ($Server in $DNSServers)
    {
    Try{
        $DNSServer = Get-DnsServerForwarder -ComputerName $server.Name -ErrorAction Stop
        $Object = [PSCustomObject]@{
            Server     = $server.Name
            IP         = (Resolve-DnsName $server.Name).IPAddress
            Forwarders = $DNSServer.IPAddress
            OS         = $server.OperatingSystem
            LastLogon  = $server.LastLogonDate
            }
        $DNSArray += $Object
        }
    Catch{$_}
    }



foreach($server in $DNSArray)
    {
    if ($server.Forwarders -contains $OldIP)
        {
        $NewArray = ($server.Forwarders.IPAddressToString).replace($OldIP,$NewIP)
        Set-DnsServerForwarder -ComputerName $server.server -IPAddress $NewArray -Verbose
        }
    }
