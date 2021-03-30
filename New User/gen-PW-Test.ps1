function Create-RandomPassword {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateRange(14,120)]
        [Int]
        $PasswordLength,
        [ValidateRange(3,4)]
        [Int]
        $MinWordLength = 3,
        [ValidateRange(3,6)]
        [Int]
        $MaxWordLength = 4,
        [ValidateRange(1,10)]
        [Int]
        $WordCount = 3

    )

        #GENERATE RANDOM LENGTHS FOR EACH WORD
        $WordLengths =  @()
        For( $Words=1; $Words -le $WordCount; $Words++ ) 
            {
            [System.Security.Cryptography.RNGCryptoServiceProvider]  $Random = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
            $RandomNumber = new-object byte[] 1
            $WordLength = ($Random.GetBytes($RandomNumber))
            [int] $WordLength = $MinWordLength + $RandomNumber[0] % 
            ($MaxWordLength - $MinWordLength + 1) 
            $WordLengths += $WordLength 
            }

$WordLengths

        #PICK WORD FROM DICTIONARY MATCHING RANDOM LENGTHS
        $RandomWords = @()
        ForEach ($WordLength in $WordLengths)
            {
            $DictionaryPath = "$psscriptroot\assets\dict.csv"
            $Dictionary = Import-Csv -Path $DictionaryPath
            $MaxWordIndex = $Dictionary.Count
            $RandomBytes = New-Object -TypeName 'System.Byte[]' 4
            $Random = New-Object -TypeName 'System.Security.Cryptography.RNGCryptoServiceProvider'
            #I don't know why but when the below line is commented out, the function breaks and returns the same words each time.
            $RandomSeed = $Random.GetBytes($RandomBytes)
            $RNG = [BitConverter]::ToUInt32($RandomBytes, 0)
            $WordIndex = ($Random.GetBytes($RandomBytes))
            [int] $WordIndex = 0 + $RNG[0] % 
            ($MaxWordIndex - 0 + 1)
            $RandomWord = $Dictionary | Select -Index $WordIndex
            $RandomWords += $RandomWord
            }

$RandomWords 

$textInfo = (Get-Culture).TextInfo
foreach ($word in $RandomWords)
    {
$Tword = $textInfo.ToTitleCase($word.word)
$Phrase += $Tword
}
    
    $Num = Get-Random -Minimum 0 -Maximum 9

    $padding = $PasswordLength-$phrase.length-1
    If($padding -ne 0){
        $spChars = '!','@','#','$','%','^','&','*'
        do {
        $x = Get-Random -InputObject $spChars -Count 1
        $end += $x
        }
        until ($end.Length -eq $padding)
        }
    Else {$end = $null}
$Password = $phrase+$num+$end
$Password
}