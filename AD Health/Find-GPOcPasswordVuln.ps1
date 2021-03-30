Function Find-GPOcPasswordVuln {
    #Requires -Version 3
    <#
.SYNOPSIS
  Find GPO Preferences with the CPassword Attribute.
.DESCRIPTION
  https://docs.microsoft.com/en-us/security-updates/SecurityBulletins/2014/ms14-025?redirectedfrom=MSDN
  Passwords stored in GPP xml files as the cPassword Attribute can be easily decrypted. Microsoft has patched GPP so that no new attributes can be created, but existing XML files may still contain decrypted passwords. This function will identify affected GPO's.
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.INPUTS
  None
.OUTPUTS
  None
.NOTES
  Version:        1.0
  Author:         GiveMeTheBits
  Creation Date:  9/26/2019
  Purpose/Change: Initial script development
  
.EXAMPLE
  Find-GPOcPasswordVuln
#>

    $Path = "\\corp.contoso.com\SYSVOL\corp.contoso.com\Policies\"

    # Get all GPO XMLs
    $XMLs = Get-ChildItem $Path -recurse -Filter *.xml

    # GPO's containing cpasswords
    $cPasswordGPOs = @()
    # Loop through all XMLs and use regex to parse out cpassword
    # Return GPO display name if it returns
    Foreach ($XMLFile in $XMLs) {
        $Content = Get-Content -Raw -Path $XMLFile.FullName
        if ($Content.Contains("cpassword")) {
            [string]$CPassword = [regex]::matches($Content, '(cpassword=).+?(?=\")')
            $CPassword = $CPassword.split('(\")')[1]
            if ($CPassword) {
                [string]$GPOguid = [regex]::matches($XMLFile.DirectoryName, '(?<=\{).+?(?=\})')
                $GPODetail = Get-GPO -guid $GPOguid
                $cPasswordGPOs+= $GPODetail
            }
        }
    }
    $cPasswordGPOs | Format-Table -AutoSize
}