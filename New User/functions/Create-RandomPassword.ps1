function Create-RandomPassword {
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateRange(14,120)]
        [Int]
        $PasswordLength
    )

$textInfo = (Get-Culture).TextInfo
$rand = new-object System.Random
$words = import-csv .\assets\dict.csv
$word1 = ($words[$rand.Next(0,$words.Count)]).Word
$word2 = ($words[$rand.Next(0,$words.Count)]).word
$word3 = ($words[$rand.Next(0,$words.Count)]).Word
$phrase = $textInfo.ToTitleCase($word1) + $textInfo.ToTitleCase($word2) + $textInfo.ToTitleCase($word3)
    
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