#MUST RUN AS ADMIN
#If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
#{ Write-Warning -Message "Launch PoSh as Administrator"; break }
#{   
#    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
#    Start-Process powershell -Verb runAs -ArgumentList $arguments
#    Break
#}

$Database = "DB1" #Specify which DB to connect to

##Add the ODP.net oracle data provider DLL.
##
Set-Location -Path $PSScriptRoot
Add-Type -Path .\ODP.NET_Managed_ODAC122cR1\odp.net\managed\common\Oracle.ManagedDataAccess.dll

If (!(Get-Module CredentialManager)) { Install-Module CredentialManager -Scope CurrentUser }
$Target = @{
    DB1 = @{User = "ADMIN"; DataSource = "DB1.contoso.local/DB1" };
    DB2  = @{User = "ADMIN"; DataSource = "DB2.contoso.local/DB2" };
    DB3   = @{User = "ADMIN"; DataSource = "DB3.contoso.local/DB3" };
}
$DataSource = $Target.$Database.DataSource

if (!(Get-StoredCredential -Target $Database)) {
    $CredSplat = @{
        Target   = $Database
        UserName = $Target.$Database.User
        Password = (Get-Credential -UserName $Target.$Database.User -Message $Database).GetNetworkCredential().Password
        Comment  = $Database
        Persist  = "Enterprise"
    }
    New-StoredCredential @CredSplat > $Null
    Remove-Variable CredSplat
}

$PSCred = Get-StoredCredential -Target $Database

##build connection string and test it.
##
$ConnectionString = "User Id=$($PSCred.Username);Password=$($PSCred.GetNetworkCredential().Password);Data Source=$DataSource"
#Function for Hashtable Creation
Function ConvertTo-Hashtable ($Key, $Table) {
    $array = @{ }
    Foreach ($Item in $Table) {
        $array[$Item.$Key.ToString()] = $Item
    }
    $array
}
##Function for Oracle Records
Function Invoke-OracleQuery($ConnectionString, $Query) {
    $array = [System.Collections.ArrayList]@()

    try {
        $Connection = [Oracle.ManagedDataAccess.Client.OracleConnection]($ConnectionString)
        $Connection.open()
        Write-Verbose "Connected to database: $($Connection.DatabaseName) running on host: $($Connection.HostName) – Servicename: $($Connection.ServiceName) – Serverversion: $($Connection.ServerVersion)” -Verbose
    }
    catch {
        Write-Error ("Can’t open connection: {0}`n{1}” -f `
                $Connection.ConnectionString, $_.Exception.ToString())
        break
    }
    ##
    $Command = $Connection.CreateCommand()
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $columnNames = $Reader.GetSchemaTable().ColumnName

    while ($Reader.Read()) {
        $result = @{ }
        for ($i = 0; $i -lt $Reader.FieldCount; $i++) {
            $result.Add($columnNames[$i], $Reader.GetOracleValue($i)) > $null
        }
        $array.Add([pscustomobject]$result) > $null
    }
    $Connection.Close()
    $array
}

###Oracle queries below
$Query = "
SELECT *
FROM
    DATAVW
"  #Data View

$Data = Invoke-OracleQuery -ConnectionString $ConnectionString -Query $Query
$DataHash = ConvertTo-Hashtable -Key EMPLID -Table $Data
$Array = @()
Foreach ($EMPLID in $DataHash.Values.EMPLID.value) {
    $Object = [PSCustomObject]@{
        FIRST_NAME         = $DataHash[$EMPLID].FIRST_NAME
        LAST_NAME          = $DataHash[$EMPLID].LAST_NAME
        AS_EMPL_UNIQUE_ID  = $DataHash[$EMPLID].AS_EMPL_UNIQUE_ID
        EMAILID            = $DataHash[$EMPLID].EMAILID
        STATUS_DESCR       = $DataHash[$EMPLID].STATUS_DESCR
        COMPANY_NAME       = $DataHash[$EMPLID].COMPANY_NAME
        AS_SUPV_EMAILID    = $DataHash[$EMPLID].AS_SUPV_EMAILID
        REGION_CD          = $DataHash[$EMPLID].REGION_CD
        AS_COUNTRY_DESCR   = $DataHash[$EMPLID].AS_COUNTRY_DESCR
        LOCATION           = $DataHash[$EMPLID].LOCATION
        AS_TEAM_LVL1       = $DataHash[$EMPLID].AS_TEAM_LVL1
        AS_TEAM_LVL2       = $DataHash[$EMPLID].AS_TEAM_LVL2
        AS_TEAM_LVL3       = $DataHash[$EMPLID].AS_TEAM_LVL3
        AS_TEAM_LVL4       = $DataHash[$EMPLID].AS_TEAM_LVL4
        AS_TITLE           = $DataHash[$EMPLID].AS_TITLE
        AS_BIRTH_YEAR      = If ($DataHash[$EMPLID].AS_BIRTH_YEAR.IsNull) { '' }Else { $DataHash[$EMPLID].AS_BIRTH_YEAR }
        CMPNY_SENIORITY_DT = (get-date $DataHash[$EMPLID].CMPNY_SENIORITY_DT).ToString("yyyy/MM/dd")
        TIMEZONE           = $DataHash[$EMPLID].TIMEZONE
        TZDESCR            = $DataHash[$EMPLID].TZDESCR
        AS_SUPV_FIRST_NAME = $DataHash[$EMPLID].AS_SUPV_FIRST_NAME
        AS_SUPV_LAST_NAME  = $DataHash[$EMPLID].AS_SUPV_LAST_NAME
        EMPLID             = $DataHash[$EMPLID].EMPLID
        ORIG_HIRE_DT       = (get-date $DataHash[$EMPLID].ORIG_HIRE_DT).ToString("yyyy/MM/dd")
        SEX                = $DataHash[$EMPLID].SEX
    }
    $Array += $Object
}
$baddate = get-date 2/29/2020
break
$Array | ForEach-Object { if ( ($_.COMPANY_NAME.Value -like "*Company1*") -or ($_.COMPANY_NAME.Value -like "*Company2*")) {$_.COMPANY_NAME = 'Company3'} } 
#$Array | Where-Object { $_.ORIG_HIRE_DT -lt $baddate.ToString("yyyy/MM/dd") } | Export-Csv -Path .\03062020.csv -Force -NoTypeInformation
$Array | Export-Csv -Path .\03062020.csv -Force -NoTypeInformation
##format date to yyyy/mm/dd                           #done
##only include users where employed more than 30 days #done for first pull
##null handle to empty string on AS_BIRTH_YEAR        #done
#export csv                                           #done
##ship csv to undetermined location                   