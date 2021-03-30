Function Test-ForExistingADUser-Popup($SamAccountName,$UserPrincipalName,$Email,$Name){

$TestForUserSplat = @{Samaccountname   = $SamAccountName
                     UserPrincipalName = $UserPrincipalName
                     Email             = $Email
                     Name              = $Name
                     WarningVariable   = 'userVarWarnings'}

$v = Test-ForExistingADUser @TestForUserSplat

if ($v){
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Values in use'
    $form.Size = New-Object System.Drawing.Size(375,190)
    $form.FormBorderStyle = 'Fixed3D'
    $form.MaximizeBox = $false
    $form.StartPosition = 'CenterScreen'
    
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = New-Object System.Drawing.Point(120,120)
    $OKButton.Size = New-Object System.Drawing.Size(75,23)
    $OKButton.Text = 'OK'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.AcceptButton = $OKButton
    $form.Controls.Add($OKButton)
    
    $CancelButton = New-Object System.Windows.Forms.Button                        
    $CancelButton.Location = New-Object System.Drawing.Point(195,120)
    $CancelButton.Size = New-Object System.Drawing.Size(75,23)
    $CancelButton.Text = 'Cancel'
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $CancelButton
    $form.Controls.Add($CancelButton)
    
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(10,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = 'WARNING:'
    $form.Controls.Add($label)
    
    $listBox = New-Object System.Windows.Forms.Listbox
    $listBox.Location = New-Object System.Drawing.Point(10,40)
    $listBox.Size = New-Object System.Drawing.Size(335,20)
       
    ForEach($v in $userVarWarnings){$listBox.Items.Add($v)}
    
    $listBox.Height = 70
    $form.Controls.Add($listBox)
    $form.Topmost = $true
    
    $result = $form.ShowDialog()
    
    if ($result -eq [System.Windows.Forms.DialogResult]::OK)
    {
    Write-host "PlaceHolder for Confirm Details Box" -ForegroundColor Green
    }
}
}