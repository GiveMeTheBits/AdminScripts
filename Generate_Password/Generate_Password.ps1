 #Generate the password on the client running this script, not on the remote machine. System.Web.Security isn't available in the .NET Client profile. Making this call
    #    on the client running the script ensures only 1 computer needs the full .NET runtime installed (as opposed to every system having the password rolled).
    function Create-RandomPassword
    {
        Param(
            [Parameter(Mandatory=$true)]
            [ValidateRange(14,120)]
            [Int]
            $PasswordLength
        )

        $Password = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, $PasswordLength / 4)

        #This should never fail, but I'm putting a sanity check here anyways
        if ($Password.Length -ne $PasswordLength)
        {
            throw ("Password returned by GeneratePassword is not the same length as required. Required length: $($PasswordLength). Generated length: $($Password.Length)")
        }

        return $Password
    }

$pw = Create-RandomPassword 16
$pw