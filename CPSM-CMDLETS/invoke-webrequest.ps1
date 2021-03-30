Clear-Variable -Name cloudinfo
Clear-Variable -Name cloudmembership
Clear-Variable -Name groupname
Clear-Variable -Name DLgroup
Clear-Variable -Name CPSMDLGroups
Clear-Variable -Name cloud
Clear-Variable -Name CPSMDLQuery
$URL = "https://portalendpoint
$script:credcheck = @"
<?xml version="1.0" encoding="utf-8"?>
<request version="1.0" action="FIND">
<customer/>
</request>
"@
$script:credTest = $client.UploadString($apiUrl,$credcheck)


(get-date).AddDays(-1).ToString("M/dd/yyy")


$date = Get-Date
$date.ToString("M/dd/yyy")
$date.AddDays(-1).ToString("M/dd/yyy")
Set-ADAccountExpiration -identity $SamAccountName -DateTime 12/31/2013 | Out-Null
Write-Host "AD account expiration date set to 12/31/2013" -foregroundcolor Green


Invoke-WebRequest -Uri "$URL/cortexapi/default.aspx" -Credential (Get-Credential) -SessionVariable 'Cortex'
$request = Invoke-WebRequest -Uri "$URL/cortexapi/default.aspx" -WebSession $Cortex -Body $credcheck -Method Post -ContentType "application/xml"
[xml]$content = $request.Content

New-WebServiceProxy -Uri "$URL/" -Credential (Get-Credential)


$data = Get-ChildItem -Path $env:APPDATA -Recurse