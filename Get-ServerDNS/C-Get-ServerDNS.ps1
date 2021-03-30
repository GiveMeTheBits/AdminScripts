$IP = [ipaddress]'10.30.9.4'
$servers = Get-ADComputer -SearchBase "OU=Servers,DC=corp,DC=contoso,DC=com" -Filter * | ? name -ne bruacct1
$dc = Get-ADComputer -SearchBase "OU=Domain Controllers,DC=corp,DC=contoso,DC=com" -Filter *

$1 = Get-ServerDNS -ComputerName $servers.name | where {$_.DNS -ilike "*$($IP.IPAddressToString)*"}
$2 = Get-ServerDNS -ComputerName $dc.name | where {$_.DNS -ilike "*$($IP.IPAddressToString)*"}
$servers = $1+$2
$servers | Out-GridView


#TESTING HOW TO SET VIA CIM SESSIONS - WORKS ON 2012+, servers on 2008 do not have the needed module
$newIP = [ipaddress]'10.30.9.6'
foreach ($server in $servers) {
$array = @()
$Cimsession = New-CimSession -ComputerName $server.Hostname
$test = Get-NetIPConfiguration -CimSession $Cimsession | ? {$_.DNSServer.serveraddresses -contains $IP}
$serveraddresses = $test.DNSServer.serveraddresses | ? {$_ -notcontains $ip}
$array += $serveraddresses
$array += $newIP.IPAddressToString
Write-Verbose -Message $server.Hostname -Verbose
$test
$array
Set-DnsClientServerAddress -InterfaceIndex $test.InterfaceIndex -ServerAddresses $array -CimSession $Cimsession -WhatIf
}



foreach ($server in $servers) {
$Cimsession = New-CimSession -ComputerName $server.Hostname
$Cimsession
}