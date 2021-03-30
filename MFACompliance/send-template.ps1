#Email Template for Registering MFA
Set-Location '.\MFACompliance\Templates'
$htm = Get-Content -Path '.\Template.htm' -Raw

Send-MailMessage -From noreply@contoso.com -To test@contoso.com -Body $htm -BodyAsHtml -Subject 'Action Required: Enroll in MFA' -SmtpServer smtp.contoso.com