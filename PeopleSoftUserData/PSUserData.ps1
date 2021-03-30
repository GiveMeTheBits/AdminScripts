Measure-Command{
    $Database = "DB1" #Specify which DB to connect to
    
    ##Add the ODP.net oracle data provider DLL.
    ##
    Set-Location -Path $PSScriptRoot
    Start-Transcript -path ".\logs\$((get-date).GetDateTimeFormats()[5])_console.log" -Force #console log
    Add-Type -Path .\ODP.NET_Managed_ODAC122cR1\odp.net\managed\common\Oracle.ManagedDataAccess.dll
    #Add-Type -Path "$PSScriptRoot\Scripts\PeopleSoftUserData\ODP.NET_Managed_ODAC122cR1\odp.net\managed\common\Oracle.ManagedDataAccess.dll"
    
    #$SPCred = Get-Credential
    #Get Credentials
    If(!(Get-Module CredentialManager)){Install-Module CredentialManager -Scope CurrentUser}
    $Target = @{
        DB1 = @{User = "pssvcsp";DataSource = "DB1.contoso.local/DB1"};
        DB2 = @{User = "pssvcsp";DataSource = "DB2.contoso.local/DB2"};
        DB3 = @{User = "pssvcsp";DataSource = "DB3.contoso.local/DB3"};
        }
    $DataSource = $Target.$Database.DataSource
    
    if (!(Get-StoredCredential -Target $Database)){
        $CredSplat = @{
            Target   = $Database
            UserName = $Target.$Database.User
            Password = (Get-Credential -UserName $Target.$Database.User -Message $Database).GetNetworkCredential().Password
            Comment = $Database
            Persist = "Enterprise"
            }
        New-StoredCredential @CredSplat > $Null
        Remove-Variable CredSplat
        }
    if (!(Get-StoredCredential -Target 2NAdmin)){
        $CredSplat = @{
            Target   = '2NAdmin'
            UserName = 'global\testscri'
            Password = (Get-Credential -UserName 'global\testscri' -Message '2N Admin').GetNetworkCredential().Password
            Comment = '2N Admin'
            Persist = "Enterprise"
            }
        New-StoredCredential @CredSplat > $Null
        Remove-Variable CredSplat
        }
    
    $PSCred = Get-StoredCredential -Target $Database
    $2NCred = Get-StoredCredential -Target 2NAdmin
    $2N = @{
        Server     = 'Global.contoso.local'
        Credential = $2NCred
        }
 
    ##build connection string and test it.
    ##
    $ConnectionString = "User Id=$($PSCred.Username);Password=$($PSCred.GetNetworkCredential().Password);Data Source=$DataSource"
    
    #Function for Hashtable Creation
    Function ConvertTo-Hashtable ($Key,$Table){
        $array = @{}
        Foreach ($Item in $Table)
            {
            $array[$Item.$Key.ToString()] = $Item
            }
        $array
    }
    ##Function for Oracle Records
    Function Invoke-OracleQuery($ConnectionString,$Query){
    $array = [System.Collections.ArrayList]@()
    
    try {
        $Connection = [Oracle.ManagedDataAccess.Client.OracleConnection]($ConnectionString)
        $Connection.open()
        Write-Verbose "Connected to database: $($Connection.DatabaseName) running on host: $($Connection.HostName) – Servicename: $($Connection.ServiceName) – Serverversion: $($Connection.ServerVersion)” -Verbose
    }
    catch
    {
        Write-Error ("Can’t open connection: {0}`n{1}” -f `
            $Connection.ConnectionString, $_.Exception.ToString())
        break
    }
    ##
    $Command = $Connection.CreateCommand()
    $Command.CommandText = $Query
    $Reader = $Command.ExecuteReader()
    $columnNames = $Reader.GetSchemaTable().ColumnName
    
    while ($Reader.Read())
        {
        $result = @{}
        for ($i=0; $i -lt $Reader.FieldCount; $i++)
            {
            $result.Add($columnNames[$i], $Reader.GetOracleValue($i)) > $null
            }
        $array.Add([pscustomobject]$result) > $null
        }
    $Connection.Close()
    $array
    }
    
    # Get ISO Country Codes so we can convert Alpha-3 to Alpha-2 and store on the c Attribute in AD later in the script
    # Get from online source, if the rest call fails, then use last stored file and wrte to log
    Try{
        $ISOCountries  = Invoke-RestMethod "https://restcountries.eu/rest/v2/all" -ErrorAction Stop 
        $ISOCountries | ConvertTo-Json | Out-File -FilePath  .\assets\ISOCountries.json -Force
        $ISOCountriesHash = ConvertTo-Hashtable -Key alpha3Code -Table $ISOCountries
        }
    Catch{
        Write-Error $_
        $ISOCountries = Get-Content .\assets\ISOCountries.json | ConvertFrom-Json
        $ISOCountries | ConvertTo-Json | Out-File -FilePath  .\assets\ISOCountries.json -Force
        $ISOCountriesHash = ConvertTo-Hashtable -Key alpha3Code -Table $ISOCountries
        }


    ###Oracle queries below
    $Query1 = "
    SELECT
        ps_contoso_employeevw.EMPLID,
        ps_contoso_employeevw.BUSINESS_UNIT,
        ps_contoso_employeevw.LAST_NAME,
        ps_contoso_employeevw.FIRST_NAME,
        ps_contoso_employeevw.PREF_FIRST_NAME,
        ps_contoso_employeevw.BIRTHDAY,
        ps_contoso_employeevw.HIRE_DT,
        ps_contoso_employeevw.ps_BUSINESS_PHONE1,
        ps_contoso_employeevw.ADDRESS1,
        ps_contoso_employeevw.ADDRESS2,
        ps_contoso_employeevw.ADDRESS3,
        ps_contoso_employeevw.ADDRESS4,
        ps_contoso_employeevw.CITY,
        ps_contoso_employeevw.DESCR_2 AS STATE,
        ps_contoso_employeevw.POSTAL,
        ps_contoso_employeevw.COUNTRY,
        ps_contoso_employeevw.ps_HOME_PHONE,
        ps_contoso_employeevw.ps_BUSINESS_PAGER1,
        ps_contoso_employeevw.ps_CELL_PHONE,
        ps_contoso_employeevw.ps_BUSINESS_FAX,
        ps_contoso_title_vw.DESCR150_MIXED AS TITLE,
        ps_contoso_employeevw.COUNSELOR_TYPE,
        ps_contoso_employeevw.DEPTID,
        ps_contoso_employeevw.COMPANY,
        ps_contoso_employeevw.SUPERVISOR,
        ps_contoso_office_vw.ATTN_TO as OFFICE,
        ps_contoso_office_vw.ps_BUSINESS_PHONE1 as OFFICE_TELEPHONE
    FROM
        ps_contoso_employeevw
    LEFT OUTER JOIN ps_contoso_title_vw
    ON (ps_contoso_employeevw.ps_FUNC_TITLE_KEY = ps_contoso_title_vw.TITLE_KEY
        AND ps_contoso_employeevw.BUSINESS_UNIT = ps_contoso_title_vw.BUSINESS_UNIT)
    LEFT OUTER JOIN ps_contoso_office_vw
    ON (ps_contoso_employeevw.LOCATION = ps_contoso_office_vw.LOCATION
        AND ps_contoso_employeevw.BUSINESS_UNIT = ps_contoso_office_vw.BUSINESS_UNIT)
    "  #Employee Personal Data
    $Query2 = "
    SELECT
        TRIM(AS_REACH_ID) AS REACHID,
        EMPLID
    FROM
        psadm.PS_PERSONAL_DATA
    WHERE
        TRIM(AS_REACH_ID) IS NOT NULL
        AND EMPLID IN (SELECT EMPLID FROM ps_contoso_employeevw)
    "  #Reach ID, EmployeeID
    $Query5 = "
    SELECT
        company AS CompanyNumber,
        NVL(descr50, ' ') AS Company
    FROM
        ps_contoso_BRAND_VW
    "  #Company Number to Name
    
    ##Run Query Functions
    $EmployeePII        = Invoke-OracleQuery -ConnectionString $ConnectionString -Query $Query1 #Most Emp Data
    $ReachIDs           = Invoke-OracleQuery -ConnectionString $ConnectionString -Query $Query2 #Just ReachIDs
    $Brands             = Invoke-OracleQuery -ConnectionString $ConnectionString -Query $Query5 #Company Number to Agency Name
    ##
    #Group/Sort Table(s)
    $ManagerArray = [System.Collections.ArrayList]@()
    $Managers = $EmployeePII | Group-Object -Property SUPERVISOR
    Foreach ($Manager in $Managers)
        {
        $Object = [PSCustomObject]@{
            SUPERVISOR     = $Manager.Name
            DIRECT_REPORTS = $Manager.Group.EMPLID.Value
            }
        $ManagerArray.Add($Object) > $null
        }
    ##
    #Build HashTables
    $EmployeePIIHash = ConvertTo-Hashtable -Key EMPLID -Table $EmployeePII
    $ReachIDsHash = ConvertTo-Hashtable -Key EMPLID -Table $ReachIDs
    $BrandsHash = ConvertTo-Hashtable -Key COMPANYNUMBER -Table $Brands
    $ManagersHash = ConvertTo-Hashtable -Key SUPERVISOR -Table $ManagerArray
    ##User Classification Table
    $UserClassificationTable = @{
        EMPL2 = 'Secondary'
        EMPL  = 'Employee'
        FRLAN = 'Temporary'
        PRTTM = 'Employee'
        IDPNT = 'Temporary'
        ASSOC = 'Employee' #contoso changing some employees couns types to EMPL2.
        TEMP  = 'Employee'
        STFSV = 'Temporary'
        INTRN = 'Employee'
        VNDR  = 'Temporary'
        ALUM  = 'Secondary'
        OTHER = 'Secondary'
        }
    
    ##Manipulate AD and PS Data
    $PSUserDataHash = @{}
    foreach ($Employee in $EmployeePII.EMPLID)
        {
        $SAM = $Employee.ToString()
        #Build user Table with Values to sync ##Possible look into Hash table here too!
        $PSUserData = [PSCustomObject]@{
            EMPLID           = $SAM;
            ReachID          = if($ReachIDsHash.ContainsKey($sam)){$ReachIDsHash[$sam].REACHID.ToString().trim()};         #$ADUser.EmployeeID  #Needed if() to prevent Null Error Stop Action
            EmpType          = $EmployeePIIHash[$SAM].COUNSELOR_TYPE.ToString().trim();     #SPO Property #Need to have a table lookup for classifications
            EmpClass         = $UserClassificationTable[$EmployeePIIHash[$SAM].COUNSELOR_TYPE.ToString().trim()];  ##$ADUser.otherFacsimileTelephoneNumber
            LastName         = $EmployeePIIHash[$SAM].LAST_NAME.ToString().trim();          #$ADUser.Surname                       ##do we want names to be forced as PS values?
            FirstName        = if  ($EmployeePIIHash[$SAM].PREF_FIRST_NAME.ToString().trim())
                                   {$EmployeePIIHash[$SAM].PREF_FIRST_NAME.ToString().trim()}         #$ADUser.GivenName                     ##do we want names to be forced as PS values?
                               Else{$EmployeePIIHash[$SAM].FIRST_NAME.ToString().trim()}
            DOB              = $EmployeePIIHash[$SAM].BIRTHDAY.ToString().trim();           #$ADUser.????       Currently no builtin attribute. could use ExtensionAttribute#. how to sync to SPO?
            HireDate         = $EmployeePIIHash[$SAM].HIRE_DT.ToString().trim();            #$ADUser.????       Currently no builtin attribute. could use ExtensionAttribute#. how to sync to SPO?
            Telephone        = $EmployeePIIHash[$SAM].ps_BUSINESS_PHONE1.ToString().trim(); #$ADUser.telephoneNumber
            Address1         = $EmployeePIIHash[$SAM].ADDRESS1.ToString().trim();           #$ADUser.StreetAddress
            Address2         = $EmployeePIIHash[$SAM].ADDRESS2.ToString().trim();           #$ADUser.StreetAddress
            Address3         = $EmployeePIIHash[$SAM].ADDRESS3.ToString().trim();           #$ADUser.StreetAddress
            Address4         = $EmployeePIIHash[$SAM].ADDRESS4.ToString().trim();           #$ADUser.StreetAddress
            Address          = @();
            City             = $EmployeePIIHash[$SAM].CITY.ToString().trim();               #$ADUser.City
            State            = $EmployeePIIHash[$SAM].STATE.ToString().trim();              #$ADUser.State
            ZIP              = $EmployeePIIHash[$SAM].POSTAL.ToString().trim();             #$ADUser.PostalCode
            CountryinPS      = $EmployeePIIHash[$SAM].COUNTRY.ToString().trim();            #$not used for setting, only for lookup
            Country          = $ISOCountriesHash[$EmployeePIIHash[$SAM].COUNTRY.ToString().trim()].alpha2Code            #$ADUser.Country
            CountryCode      = [int]$ISOCountriesHash[$EmployeePIIHash[$SAM].COUNTRY.ToString().trim()].numericCode           #$ADuser.CountryCode 
            Home             = $EmployeePIIHash[$SAM].ps_HOME_PHONE.ToString().trim();      #$ADUser.HomePhone
            Pager            = $EmployeePIIHash[$SAM].ps_BUSINESS_PAGER1.ToString().trim(); #$ADUser.Pager
            Mobile           = $EmployeePIIHash[$SAM].ps_CELL_PHONE.ToString().trim();      #$ADUser.MobilePhone
            fax              = $EmployeePIIHash[$SAM].ps_BUSINESS_FAX.ToString().trim();    #$ADUser.Fax
            Office           = $EmployeePIIHash[$SAM].OFFICE.ToString().trim();             #$ADUser.Office          ##might need lookup table for abbreviated.
            Office_Telephone = $EmployeePIIHash[$SAM].OFFICE_TELEPHONE.ToString().trim();   #Alt telephonenumber if null in ps          ##might need lookup table for abbreviated.
            Title            = $EmployeePIIHash[$SAM].TITLE.ToString().trim();              #$ADUser.Title
            Department       = $EmployeePIIHash[$SAM].DEPTID.ToString().trim();             #$ADUser.Department
            Company          = $BrandsHash[$EmployeePIIHash[$SAM].Company.ToString().trim()].COMPANY.ToString().trim();            #$ADUser.Company
            Manager          = $EmployeePIIHash[$SAM].SUPERVISOR.ToString().trim();         #$ADUser.Manager        ## need to get DN of Value
            DirectReports    = $ManagersHash[$SAM].DIRECT_REPORTS;                       #$ADUser.directReports  ## need to get DN values, and then foreach check. need to only modify values that are in both tables
            Business_Unit    = $EmployeePIIHash[$SAM].Business_Unit.ToString().trim();  #used for something in SPO User Profile
            }
        Foreach ($Value in $($PSUserData.psobject.Properties.name))
            {
            if ($PSUserData.$Value -eq "null"){$PSUserData.$Value = $Null}
            }
        If($PSUserData.Address1){$PSUserData.Address += $PSUserData.Address1}
        If($PSUserData.Address2){$PSUserData.Address += $PSUserData.Address2}
        If($PSUserData.Address3){$PSUserData.Address += $PSUserData.Address3}
        If($PSUserData.Address4){$PSUserData.Address += $PSUserData.Address4}
        $PSUserDataHash[$SAM] = $PSUserData
        }
    #Boolean compare PS Values to AD Values per user and set new values if $false
    Function Set-ADUserProperty
        {
        [CmdletBinding(SupportsShouldProcess=$True)]
        [Alias()]
        Param
            (
            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$false)]
            $Server,
            [Parameter(Mandatory=$false)]
            [ValidateNotNullorEmpty()]
            [System.Management.Automation.PSCredential] #Type Definition; will not pass correctly if not declared
            [System.Management.Automation.Credential()] #allows username to passed in param and prompt for password
            $Credential
            )
    
        $CredSplat = @{}
        'Server', 'Credential' | Foreach-Object {
            $Parameter = $_
                if($PSBoundParameters.ContainsKey($Parameter))
                    {
                    $CredSplat.Add($Parameter, $PSBoundParameters[$Parameter])
                    }
                }
        $ADProperties = (    #Build property table for all AD User lookup, then rebuild it below off of PSuser keys.
            'SamAccountName',
            'EmployeeID',
            'OfficePhone',
            'MobilePhone',
            'Office',
            'Title',
            'Department',
            'Company',
            'otherFacsimileTelephoneNumber',
            'Country',
            'CountryCode'
            )
        $ExcludedMembers = Get-ADGroupMember -Identity 'PSUserDataSync-Exclude-otherFacsimileTelephoneNumber' #members in this group will not have Otherfax synced for learning site.
        $AllADUsers = Get-ADUser -Filter *  -Properties $ADProperties @CredSplat
        $HashAllADUsers = ConvertTo-Hashtable -Key SamAccountName -Table $AllADUsers
        $Log = [System.Collections.ArrayList]@()
        Foreach ($PSUser in $PSUserDataHash.Values)
            { #Create Splat and Array with AD User Properties
            $SAM = $PSUser.EMPLID.ToString()
            if ($ADUser = $HashAllADUsers[$SAM])
                {
                $UserSplat = @{
                    SamAccountName = $PSUser.EMPLID
                    EmployeeID     = $PSUser.ReachID
                    OfficePhone    = $PSUser.Telephone
                    MobilePhone    = $PSUser.Mobile
                    Office         = $PSUser.Office
                    Title          = $PSUser.Title
                    Department     = $PSUser.Department
                    Company        = $PSUser.Company
                    Country        = $PSUser.Country
                    }
                $ExcludedBool = $SAM -in $ExcludedMembers.SamAccountName  #bool used to switch if otherfax gets set or not
                If (!($UserSplat.OfficePhone)){$UserSplat.OfficePhone = $PSUser.Office_Telephone} #if the desk phone is not in Peoplesoft, we force the Physical_office_telephone. This is a placeholder until TD has complete and accurate records. ¯\_(ツ)_/¯
                If($UserSplat.EmployeeID -eq $Null){$UserSplat.EmployeeID = "EMPTY"} #the ad attr must have a string in place, or Reach is unable to be used by the employee. This is a placeholder until TD has complete and accurate records. ¯\_(ツ)_/¯
                If (!($UserSplat.Office)){$UserSplat.Office = $Null} #if the Peoplesoft record is blank, it doesn't cast to null correctly and won't allow the set-aduser to run
                Try{ 
                    $New = $UserSplat | ConvertTo-Json | ConvertFrom-Json
                    Add-Member -InputObject $New -MemberType NoteProperty -Name "otherFacsimileTelephoneNumber" -Value $PSUser.EmpClass #add -replace properties to the new log array
                    Add-Member -InputObject $New -MemberType NoteProperty -Name "CountryCode" -Value $PSUser.CountryCode #add -replace properties to the new log array
                    $New = $New | Select-Object $ADProperties
                    $Old = $ADUser | Select-Object $ADProperties | ConvertTo-Json | ConvertFrom-Json
                    If($ExcludedBool)
                        {
                        $old.psobject.Properties.Remove('otherFacsimileTelephoneNumber')
                        $New.psobject.Properties.Remove('otherFacsimileTelephoneNumber')
                        }
                    Else{$Old.otherFacsimileTelephoneNumber = $Old.otherFacsimileTelephoneNumber[0]}       #########################################         
                    if (Compare-Object $New.psobject.Properties $Old.psobject.Properties)
                        {
                        If(-not $ExcludedBool) {$ADuser | Set-ADUser @CredSplat @UserSplat -Replace @{'otherFacsimileTelephoneNumber' = $PSUser.EmpClass} -ErrorAction Stop}
                        $ADuser | Set-ADUser @CredSplat @UserSplat -Replace @{'CountryCode' = $PSUser.CountryCode} -ErrorAction SilentlyContinue
                        Add-Member -InputObject $New -MemberType NoteProperty -Name "ChangeState" -Value "New"
                        Add-Member -InputObject $Old -MemberType NoteProperty -Name "ChangeState" -Value "Old"
                        $log.Add($New) > $Null
                        $log.Add($Old) > $Null
                        }
                    }
                Catch{ #log error if User is not found in Domain
                    Write-Error -Message "$SAM not found in $((Get-ADDomain @CredSplat).dnsroot)" -ErrorAction SilentlyContinue
                    }
                }
            }
        $Log | ConvertTo-Json | Out-File -FilePath  ".\logs\$((get-date).GetDateTimeFormats()[5]).$((Get-ADDomain @CredSplat).dnsroot)_Changes.json" -Force 
        }
    #Run Set-ADUser as Jobs and output to log files
    Write-Verbose "Corp AD" -Verbose
    Set-ADUserProperty
    Write-Verbose "Global AD" -Verbose
    Set-ADUserProperty @2N

}

$date = $(get-date).GetDateTimeFormats()[5]

$CorpPath   = ".\logs\$date.corp.contoso.com_Changes.json"
$GlobalPath = ".\logs\$date.global.contoso.local_Changes.json"

If (!(Test-Path -Path .\logs)){New-Item .\logs -ItemType Directory}
$CorpLog   = Get-Content $CorpPath -ErrorAction SilentlyContinue   | ConvertFrom-Json
$GlobalLog = Get-Content $GlobalPath -ErrorAction SilentlyContinue | ConvertFrom-Json
If ($CorpLog)
    {
        $CorpLog   | Export-Csv -Path ".\logs\$date.corp.contoso.com_Changes.csv" -NoTypeInformation -Force
    }
If ($GlobalLog)
    {
        $GlobalLog | Export-Csv -Path ".\logs\$date.global.contoso.local_Changes.csv" -NoTypeInformation -Force
    }
$logs = Get-ChildItem -path ".\logs" -Include "$date*.csv" -Recurse
If ($logs)
    {
    #SMTP Relay Settings
    $smtpServer  = "smtp.contoso.com"
    $from        = "PSUserDataSync <noreply@contoso.com>"
    $to          = "PortalHelp@contoso.com","ADSync.Notifications@contoso.com"
    $subject     = "PeopleSoft to AD DataSync Results"
    $body        = "This report is the daily changes of syncing PeopleSoft counselor data to AD. ChangeState indicates the row for Old and New values. Best viewed in Excel. Errors and 'Users not found' are NOT recorded in this log."
    $attachments = $logs
    Send-Mailmessage -smtpServer $smtpServer -from $from -to $To -subject $subject -Body $body -Attachments $attachments -ErrorAction Stop
    }