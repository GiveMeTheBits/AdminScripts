$GroupRef = Get-ADGroupMember -Identity "NAME OF FIRST GROUP"
$GroupCompare = Get-ADGroupMember -Identity "NAME OF SECOND GROUP"

Compare-Object $GroupRef $GroupCompare -Property name -IncludeEqual

$USERs = $GroupCompare | where {$GroupRef.name -notcontains $PSItem.name} | ForEach-Object {Get-ADUser $psitem.samaccountname -Properties description,info} | Out-GridView -PassThru

$USERs | select name,description,info | Out-GridView


Add-ADGroupMember -Identity Cis -Members $USERs -WhatIf