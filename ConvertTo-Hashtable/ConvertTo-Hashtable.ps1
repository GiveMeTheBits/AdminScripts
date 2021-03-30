    #Add this function to any script that needs fast filtering or lookups
    Function ConvertTo-Hashtable ($Key,$Table){
        $Hashtable = @{}
        Foreach ($Item in $Table)
            {
            $Hashtable[$Item.$Key.ToString()] = $Item
            }
        $Hashtable
    }

    #$table = Get-ADUser -Filter *
(Measure-Command{ $hash = ConvertTo-Hashtable -Key SamAccountName -Table $table }).TotalMilliseconds