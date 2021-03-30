Function Get-RemoteSMBShares ($ServerName,$SearchString){
$i = 1
$ServerArray = [System.Collections.ArrayList]@()
$ServerArray.Add($ServerName) > $null
foreach ($Server in $ServerName)
    {
    Write-Progress -Activity "Current Server: $($Server)" -Id 1 -Status "Checking $i of $($ServerName.Count) Servers" -PercentComplete (($i / $ServerName.Count) * 100)
    $path = "\\$($server)"
    Try{$SMBTest = Test-NetConnection -ComputerName $Server -CommonTCPPort SMB -InformationLevel Quiet -WarningAction SilentlyContinue}
    Catch{Out-Null}
    if ($SMBTest)
        {
        Try{$Shares = Get-CimInstance -ClassName Win32_share -ComputerName $Server -ErrorAction SilentlyContinue | Where-Object {($_.Name -NotLike '*$*') -and ($_.Path -like '*:*')}}
        Catch{Out-Null}
        If ($SearchString)
            {
            $Shares = $Shares | Where-Object {$_.Name -like "*$SearchString*"}
            }
        $j = 1
        $SharesArray = New-Object System.Collections.ArrayList
        $SharesArray.Add($Shares) > $null
        Foreach ($Share in $Shares)
            {
            Write-Progress -Activity "Current Folder: $($Share.Name)" -Id 2 -Status "Checking $j of $($SharesArray.Count) Folders" -PercentComplete (($j / $SharesArray.Count) * 100)
            Try{$Folders = [System.IO.Directory]::EnumerateDirectories("\\$($Server)\$($Share.Name)")}
            Catch{Out-Null}
            Foreach ($Folder in $Folders)
                {
                $Object = [pscustomobject]@{
                    Server    = $Server
                    Folder    = $Share.Name
                    SubFolder = $Folder.Split("\")[4]
                    Path      = $Folder
                    }
                $Object
                }
            $j++            
            }
        }
    $i++
    }
}