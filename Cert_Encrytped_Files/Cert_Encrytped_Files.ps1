$CertName = "name"
##Run As Admin required for Certreq
#if on win10, you can use the PKI module cmdlets instead, new-selfsignedcert
#set Var for SubjectName of Cert
$subject = "cn=$CertName"

# Create .INF file for certreq
#more info https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/certreq_1
#MachinekeySet to $true installs to Local Computer, instead of user

{[Version]
Signature = "$Windows NT$"

[Strings]
szOID_ENHANCED_KEY_USAGE = "2.5.29.37"
szOID_DOCUMENT_ENCRYPTION = "1.3.6.1.4.1.311.80.1"

[NewRequest]
Subject = "$subject"
MachineKeySet = true
KeyLength = 2048
KeySpec = AT_KEYEXCHANGE
HashAlgorithm = Sha1
Exportable = true
RequestType = Cert
KeyUsage = "CERT_KEY_ENCIPHERMENT_KEY_USAGE | CERT_DATA_ENCIPHERMENT_KEY_USAGE"
ValidityPeriod = "Years"
ValidityPeriodUnits = "1000"

[Extensions]
%szOID_ENHANCED_KEY_USAGE% = "{text}%szOID_DOCUMENT_ENCRYPTION%"
} | Out-File -FilePath DocumentEncryption.inf

# After you have created your certificate file, run the following command to add the certificate file to the certificate store.Now you are ready to encrypt and decrypt content with the next two examples.
Certreq -new DocumentEncryption.inf DocumentEncryption.cer

##
#get-childitem to find your cert
Get-ChildItem -Path Cert:\LocalMachine\My -DocumentEncryptionCert #-documentencryptioncert only appears to be avail on win10
#next 2 commands will encrypt and decrypt using the cert.
#you will need to change the ACL on the private key in the certstore to allow users to read the private key, for some reason built-in\adminstrators doesn't allow it. I used Authenticated Users.
#More info in comments here; https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/unprotect-cmsmessage?view=powershell-5.1
"string to encrypt" | Protect-CmsMessage -OutFile C:\Scripts\account-Encrypted.txt -To $subject #-to is the CN of the certificate, you can also use the thumbprint or path. I have only been able to get it to work when the cert is installed in Personal (Cert:\LocalMachine\My)
Unprotect-CmsMessage -Path C:\Scripts\account-Encrypted.txt -To $subject
