function GetCred {
#########################################################################
#                        Load Main Panel                                #
#########################################################################
Add-Type -AssemblyName PresentationFramework
# return the directory of source files
Set-Location -Path $PSScriptRoot
$pathPanel = $PSScriptRoot

# function to load the xaml
function LoadXaml ($filename) {
    $XamlLoader = (New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
}

$XamlGetCred = LoadXaml($pathPanel + "\GetCred.xaml")
$readerGetCred = (New-Object System.Xml.XmlNodeReader $XamlGetCred)
$Form_getCred = [Windows.Markup.XamlReader]::Load($readerGetCred)

#########################################################################
#                        Logic Actions                                  #
#########################################################################
$Username = $Form_getCred.Findname("Textbox_UserName")

$Password = $Form_getCred.Findname("PasswordBox")

$btn_Submit = $Form_getCred.Findname("btn_SUBMIT")
$btn_Submit.Add_Click( {
        $SecureString = ConvertTo-SecureString $Password.Password -AsPlainText -Force
        $Script:Credential = New-Object System.Management.Automation.PSCredential ($username.Text, $SecureString);
        $Form_getCred.close()
    })

$btn_Submit = $Form_getCred.Findname("btn_CANCEL")
$btn_Submit.Add_Click( {
        $Form_getCred.close()
    })

#########################################################################
#                        Show Dialog                                    #
#########################################################################

$Form_getCred.ShowDialog() | Out-Null
$Credential
}