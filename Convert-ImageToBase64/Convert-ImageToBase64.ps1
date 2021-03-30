Function Convert-ImageToBase64 {
    Param (
        [Parameter(Mandatory=$true)]
        [String]$Path,
        [Parameter(Mandatory=$true)]
        [ValidateSet("png", "jpg", "img", "bmp", "gif")]
        [String]$Filetype
        )
Set-Location $Path
$files = Get-ChildItem -Filter "*.$Filetype"
$Type = "data:image/$Filetype;base64"
foreach ($file in $files)
    {
    $base64Img = [convert]::ToBase64String(($file | get-content -encoding byte))
    $body = "<img src=$Type,$base64Img>"
    $body | Out-File -FilePath "$($file.BaseName).txt"
    }
}




Convert-ImageToBase64 -path 'C:\folder\' -Filetype png