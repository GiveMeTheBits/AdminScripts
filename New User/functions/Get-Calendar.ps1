Function Get-Calendar {
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form_Calendar = New-Object Windows.Forms.Form

$form_Calendar.Text = 'Select a Date'
$form_Calendar.Size = New-Object Drawing.Size @(243,230)
$form_Calendar.TopMost         = $false
$form_Calendar.FormBorderStyle = 'Fixed3D'
$form_Calendar.MaximizeBox = $false
$form_Calendar.StartPosition = 'CenterScreen'

$calendar = New-Object System.Windows.Forms.MonthCalendar
$calendar.ShowTodayCircle = $false
$calendar.MaxSelectionCount = 1
$form_Calendar.Controls.Add($calendar)

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(38,165)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = 'OK'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form_Calendar.AcceptButton = $OKButton
$form_Calendar.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(113,165)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form_Calendar.CancelButton = $CancelButton
$form_Calendar.Controls.Add($CancelButton)

$form_Calendar.Topmost = $true

$result = $form_Calendar.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $date = $calendar.SelectionStart
    return $date.ToShortDateString()
}
}
#