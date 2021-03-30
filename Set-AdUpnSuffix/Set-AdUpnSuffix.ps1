$Suffix = Read-Host -Prompt "New Suffix"

$thisUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$WinPrincipal = New-Object System.Security.Principal.WindowsPrincipal($thisUser)
If( ($WinPrincipal.IsInRole("Enterprise Admins")) )
    {
    $UPNSuffixes = (Get-ADForest).UPNSuffixes | where {$_ -eq $Suffix}
    If($UPNSuffixes){Write-Verbose -Message "$Suffix already added" -Verbose;break}
    Else{
        Write-Verbose -Message "Confirming if you want to add $Suffix" -Verbose
        Get-ADForest | Set-ADForest -UPNSuffixes @{add=$suffix} -Confirm:$true 
        Write-Verbose -Message "$Suffix has been added" -Verbose
        }
    }
Else {Write-Warning -Message "$thisUsername is not an Enterprise Admin"}