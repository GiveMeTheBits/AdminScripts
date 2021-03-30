function New-LocalAdmin ($name){
    Try {
        Get-LocalUser -Name $name -ErrorAction Stop
    }
    Catch {
        Write-Verbose -Message "Creating $name" -Verbose
        #Load "System.Web" assembly in PowerShell console 
        [Reflection.Assembly]::LoadWithPartialName("System.Web")
        $PW = [System.Web.Security.Membership]::GeneratePassword(24,5)
        $SecurePass = $PW | ConvertTo-SecureString -AsPlainText -Force
        New-LocalUser -Name $name -Password $SecurePass -AccountNeverExpires -Description 'LAPS Managed Local Admin' -UserMayNotChangePassword -PasswordNeverExpires
        Add-LocalGroupMember -Group Administrators -Member $name
    }
}