##Remove user from Cloud DL's

$request = "SET"
$aduser = $useradinfo
$syncObjectId = $aduser.sid.Value
$enabled = "false"
$displayname = "group name"
$customerName = "CN"

$Script:check = @"
<?xml version="1.0" encoding="utf-8" ?>
<request action="$request" version="1.0">
  <customer>
    <name>$customerName</name>
    <service>
      <name>HE</name>
      <distributiongroups>
        <distributiongroup>
          <displayname>$displayname</displayname>
          <path>CN=Distribution FH $displayname,OU=Distribution Groups,OU=FH Global(FH),OU=Agencies,DC=CDSmail,DC=pvt</path>
          <members>
            <member>
              <syncobjectid>$syncObjectId</syncobjectid>
              <enabled>$enabled</enabled>
            </member>
          </members>
        </distributiongroup>
      </distributiongroups>
    </service>
  </customer>
</request>
"@
# get user's current distribution groups
$Script:CPSMDLQuery = $client.uploadString($apiurl,$check)
