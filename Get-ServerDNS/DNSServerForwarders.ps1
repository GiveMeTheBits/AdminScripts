Function Get-DNSServerAllNSRecordsAllZones ($ComputerName){
$RRs = [System.Collections.ArrayList]@()
$zones = Get-DnsServerZone -ComputerName $ComputerName
foreach ($zone in $zones)
    {
    $NS = Get-DnsServerResourceRecord -ComputerName $ComputerName -ZoneName $zone.zonename -RRType "NS" -Node
    Foreach ($N in $NS)
        {
        $ZoneInfo = [PSCustomObject]@{
            ZoneName     = $zone.ZoneName
            ZoneType     = $zone.ZoneType
            DSReplicated = $zone.IsDsIntegrated
            NameServer   = $N.RecordData.NameServer
            }
        $RRs.Add($ZoneInfo) > $null
        }
    }
$RRs
}

$SERVER = 'serverName'#############################################################THIS LINE IS SERVER TO DECOM
$DNS = 'DNS Server'
$ServerA = Resolve-DnsName -Name $SERVER
$allNS = Get-DNSServerAllNSRecordsAllZones -ComputerName $DNS
Write-Verbose -Message 'NS Records. Check for removal after Demote' -Verbose
$allNS.Where({$_.nameserver -like "*$($ServerA.Name)*"})
$DCs = Get-ADDomainController -Filter *
$Unique = $allNS | Select-Object nameserver -Unique | Sort-Object nameserver
$Uniquesplit = foreach ($bbbb in $Unique){$bbbb.NameServer.substring(0,$bbbb.NameServer.length-1)} 

$checkList = $Uniquesplit.Where({$_ -notin $($DCs.name)})#####DNS servers that are not DCs

$ping = New-Object System.Net.NetworkInformation.Ping;

foreach ($check in $Uniquesplit)
    {
    Write-Verbose $check -Verbose
    if (!($ping.Send($check, 3000).Status -eq 'TimedOut'))
        {
        $dnsfor = ((Get-DnsServerForwarder -ComputerName $check -WarningAction SilentlyContinue).IPAddress.Where({$_ -ilike "*$($ServerA.IP4Address)*"})).IPAddressToString
        if ($dnsfor)
            {
            Write-Host $check -ForegroundColor Green
            $dnsfor
            }
        }
    }

Function Remove-DeadDNS {  #run this if NS records for the old DC didn't get removed during DCPROMO down
Get-DnsServerZone -ComputerName $DNS | 
%{$Name = $_.zonename ; Get-DnsServerResourceRecord -ZoneName $_.zonename -RRType NS -ComputerName $DNS| 
?{$_.RecordData.NameServer -like "*$($ServerA.Name)*"} | 
Remove-DnsServerResourceRecord -ZoneName $name -ComputerName $DNS}
}

