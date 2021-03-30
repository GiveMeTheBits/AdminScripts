#Inspired by http://hillside.no/cpsm-api-functions/
#$ccc = Get-Credential
$apiUsername = $ccc.UserName
$apiPassword = $ccc.Password
$apiUrl = "https://portal.teamcds.com/cortexapi/default.aspx"

Function DoRequest()
{
Param(
[string]$request = $(throw "request required")
)

$client = new-object System.Net.WebClient
$client.Encoding = [System.Text.Encoding]::UTF8
$client.Credentials = New-Object System.Net.NetworkCredential($apiUsername,$apiPassword)
$response = $client.UploadString($apiUrl,$request);
return $response;
}
#End DoRequest#

Function GetCustomers()
{

$apiRequest = @"
<?xml version="1.0" encoding="utf-8" ?>
<request action="FIND" version="1.0">
  <customer/>
</request>
"@;

$req = DoRequest -request $apiRequest;
$req = [xml]$req;
return $req.response.customer
}
#End GetCustomers#

Function GetCustomer()
{
Param(
[string]$customerName = $(throw "customerName required")
)

$apiRequest = @"
<?xml version="1.0" encoding="utf-8" ?>
<request action="GET" version="1.0">
  <customer>
    <name>$customerName</name>
  </customer>
</request>
"@;

$req = DoRequest -request $apiRequest;
$req = [xml]$req;
return $req.response.customer
}
#End GetCustomer#

Function GetCustomerServices()
{
Param(
[string]$customerName = $(throw "customerName required")
)
$apiRequest = @"
<?xml version="1.0" encoding="utf-8" ?>
<request action="FIND" version="1.0">
  <customer>
    <name>$customerName</name>
    <service/>
  </customer>
</request>
"@;

$req = DoRequest -request $apiRequest;
#$req | Out-File C:\Service\test.log -Encoding utf8
$req = [xml]$req;
return $req.response.customer.service
}
#End GetCustomerServices#

Function GetCustomerService()
{
Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$customerName,
        [Parameter(Mandatory=$true,
         ValueFromPipelineByPropertyName=$true,
         Position=1)]
        [string]$serviceName
)
$apiRequest = @"
<?xml version="1.0" encoding="utf-8" ?>
<request action="GET" version="1.0">
  <customer>
    <name>$customerName</name>
    <service>
        <name>$serviceName</name>
    </service>
  </customer>
</request>
"@;

$req = DoRequest -request $apiRequest;
$req = [xml]$req;
return $req.response.customer.service
}
#End GetCustomerService#

#GetAllUsers – Finds all the users for a specific customer#

Function GetallUsers()
{
Param(
[string]$customerName = $(throw "customerName required")
)

$apiRequest = @"
<?xml version="1.0" encoding="utf-8" ?>
<request action="FIND" version="1.0">
  <customer>
    <name>$customerName</name>
    <user/>
  </customer>
</request>
"@;
$req = DoRequest -request $apiRequest;
$req = [xml]$req;

$fullName = $req.response.customer.name;
if($fullName -eq $customerName)
{
return $req.response.customer.user;
}
else
{
Write-Warning -Message "Something Went Wrong";}
}
#End GetAllUsers#

#GetUserInfo - Get's all information about a specific user

Function GetUserInfo()
{
Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$customerName,
        [Parameter(Mandatory=$True,
                   ValueFromPipelineByPropertyName=$true)]
        [string]$UPN
)

$apiRequest = @"
<?xml version="1.0" encoding="utf-8" ?>
<request action="GET" version="1.0">
  <customer>
    <name>$customerName</name>
    <user>
        <upn>$UPN</upn>
    </user>
  </customer>
</request>
"@;
$req = DoRequest -request $apiRequest;
$req = [xml]$req;

$fullName = $req.response.customer.name;
if($fullName -eq $customerName)
{
return $req.response.customer.user;
}
else
{
Write-Warning -Message "Something Went Wrong";}
}
#End GetAllUsers#