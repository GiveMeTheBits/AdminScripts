#add Hashtable create function
Function ConvertTo-Hashtable ($Key,$Table){
    $Hashtable = @{}
    Foreach ($Item in $Table)
        {
        $Hashtable[$Item.$Key.ToString()] = $Item
        }
    $Hashtable
}
#Get Domain Controllers for current domain
$DCs = Get-ADGroupMember "Domain Controllers"
#Initiate the clients array
Foreach ($DC in $DCs) {
    #Define the netlogon.log path
    $NetLogonFilePath = "\\" + $DC.Name + "\C$\Windows\debug\netlogon.log"
    #Reading the content of the netlogon.log file
    try {
        $NetLogonLog = Import-Csv "$env:SystemRoot\Debug\netlogon.log" -Delimiter " " -Header Date,Time,Pid,Domain,Message,ComputerName,IpAddress
}
    catch {"Error reading $NetLogonFilePath"}
    

$hash = ConvertTo-Hashtable -Key IpAddress -Table $NetLogonLog
$NoClientSite = $hash.Values.Where({$_.Message -eq "NO_CLIENT_SITE:"})
$NoClientSite.count
        #Creating the client object
        $ClientObject = New-Object -TypeName PSObject
        Add-Member -InputObject $ClientObject -MemberType NoteProperty -Name 'Hostname' -Value $ClientData[5]
        Add-Member -InputObject $ClientObject -MemberType NoteProperty -Name 'IP' -Value $ClientData[6]
        Add-Member -InputObject $ClientObject -MemberType NoteProperty -Name 'DomainController' -Value $DC.Name
        Add-Member -InputObject $ClientObject -MemberType NoteProperty -Name 'Date' -Value $ClientData[0]
        $Clients += $ClientObject
     }
}
$UniqueClients = $Clients | Sort-Object -Property IP -Unique
$UniqueClients | Out-GridView -Title "Clients which are not mapped to any AD sites ($($UniqueClients.Count) in total)"


