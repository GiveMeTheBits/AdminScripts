#########################################################################
#                        Load Main Panel                                #
#########################################################################
$WarningPreference = "SilentlyContinue:"
Add-Type -AssemblyName PresentationFramework
# return the directory of source files
Set-Location -Path $PSScriptRoot
$pathPanel = $PSScriptRoot

###############
#Load Additional function
###############
$GetCred = $pathPanel + "\GetCred.ps1"
.$GetCred

# function to load the xaml
function LoadXaml ($filename){
    $XamlLoader = (New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($filename)
    return $XamlLoader
} 
 
$XamlMainWindow = LoadXaml($pathPanel + "\MainWindow.xaml")
$readerMainWindow = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
$Form = [Windows.Markup.XamlReader]::Load($readerMainWindow)

###############################
#Actions Logic
###############################

$btn_POSH    = $Form.Findname("btn_POSH")
$btn_POSH.Add_Click({
    #[System.Diagnostics.Process]::Start('powershell.exe', '-NoProfile -noExit -command "& {Set-Location $env:systemroot}"', $credential.GetNetworkCredential().username, $Credential.Password, $credential.GetNetworkCredential().domain)
    Start-Process powershell.exe -Credential $credential -WorkingDirectory $env:ALLUSERSPROFILE
})

$btn_ISE    = $Form.Findname("btn_ISE")
$btn_ISE.Add_Click({
    #[System.Diagnostics.Process]::Start('powershell_ISE.exe', $credential.GetNetworkCredential().username, $Credential.Password, $credential.GetNetworkCredential().domain)
    Start-Process powershell_ISE.exe -Credential $credential -WorkingDirectory $env:ALLUSERSPROFILE

})

$btn_VSCODE    = $Form.Findname("btn_VSCODE")
$btn_VSCODE.Add_Click({
    $VSCode = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
    #[System.Diagnostics.Process]::Start($VSCode, $credential.GetNetworkCredential().username, $Credential.Password, $credential.GetNetworkCredential().domain)
    Start-Process $VSCode -Credential $credential -WorkingDirectory $env:ALLUSERSPROFILE
})

$btn_AddUserContext   = $Form.Findname("btn_AddUserContext")
$btn_AddUserContext.Add_Click({
    $Credential = GetCred;
    New-StoredCredential -Target $Credential.UserName -UserName $Credential.UserName -Password $Credential.GetNetworkCredential().Password -Persist Enterprise | Out-Null;
    $Credential = "";
    $combo_usercontexts.Items.Clear()
    (Get-StoredCredential).ForEach({$combo_usercontexts.AddChild($_.UserName)});
})

$combo_usercontexts   = $Form.Findname("combo_usercontexts")
(Get-StoredCredential).ForEach({$combo_usercontexts.AddChild($_.UserName)})
$combo_usercontexts.add_SelectionChanged({
    $script:credential = Get-StoredCredential -WarningAction SilentlyContinue | Where-Object {$_.UserName -eq $combo_usercontexts.SelectedValue};
})

#########################################################################
#                        Show Dialog                                    #
#########################################################################
 
$Form.ShowDialog() | Out-Null