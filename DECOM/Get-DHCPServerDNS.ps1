Function Get-DHCPServerDNS {
#get dns addresses from all DHCP scopes on server. Can be fed pipeline of multiple server names
    [CmdletBinding()]
    Param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ComputerName
    )

    Begin {
    } # End Begin

    Process {
        Foreach ($Computer in $ComputerName) {

            Try {
                $scopes = Get-DhcpServerv4Scope –ComputerName $Computer -ErrorAction Stop
                $DefaultScopeOption = Get-DhcpServerv4OptionValue –ComputerName $Computer -ErrorAction Stop |
                    Where-Object optionid -EQ "6" -ErrorAction ignore
           


                foreach ($scope in $scopes ) {
                    try {
                        $temp = Get-DhcpServerv4OptionValue -ComputerName $Computer -ScopeId $scope.ScopeId.IPAddressToString -OptionId "6" -ErrorAction Stop

                        if ($temp.optionid -eq 6) {

                            [pscustomobject]@{
                                Server    = $Computer
                                ScopeID   = $scope.ScopeID
                                ScopeName = $scope.Name
                                DNSIP     = $temp.value
                                Type      = 'Explicit'
                            }

                        }

                    }
                    catch { 
                        [pscustomobject]@{
                            Server    = $Computer
                            ScopeID   = $scope.ScopeId
                            ScopeName = $scope.Name
                            DNSIP     = $DefaultScopeOption.value
                            Type      = 'Inherited'
                            }
                    } 
                }
                
            }
            Catch {
                Write-Warning "$Computer Failed to Connect"
            }
        }
    }
}