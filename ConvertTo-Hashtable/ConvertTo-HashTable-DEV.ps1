function ConvertTo-HashTable {
    [CmdletBinding()]Param(
        [Parameter(Mandatory)]
        $Key,

        [Parameter(Mandatory,ValueFromPipeline)]
        [Object[]]
        $Table,

        [Parameter()]
        [Switch]
        $NonUniqueAsList
    )

    begin {
        $hash = @{}
        $property = $Key.ToString()
    }

    process {
        foreach ($t in $table) {
            Write-Verbose $t.$property
            if ($hash.ContainsKey($t.$property) -eq $false) {
                Write-Verbose ' Adding new key'
                $hash[$t.$property] = $t
            }
            elseif ($NonUniqueAsList) {
                if ($hash[$t.$property].Count -gt 1) {
                    Write-Verbose ' Appending'
                    $hash[$t.$property].Add($t)
                }
                else {
                    Write-Verbose ' Creating list'
                    $list = New-Object -TypeName System.Collections.Generic.List[object]
                    $list.Add($hash[$t.$property])
                    $list.Add($t)
                    $hash.Remove($t.$property)
                    $hash[$t.$property] = $list
                }
            }
            else {
                Write-Warning ('{0} is not unique!' -f $t.$property)
            }
        }
    }

    end {
        Write-Output $hash
    }
}
#$table = Get-ADUser -Filter *

(Measure-Command{ $hash = ConvertTo-Hashtable -Key SamAccountName -Table $table }).TotalMilliseconds