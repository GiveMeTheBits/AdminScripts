#Relies on WinRM
$cred = Get-Credential -Message "SuperUser"
$server = Read-Host -Prompt "Server"
$session = New-PSSession -ComputerName $server -Credential $cred
Enter-PSSession $session

#Check for Reg entry and Hotfix  ####Expand on this next time it's needed
get-itemproperty HKLM:\software\microsoft\windows\CurrentVersion\Policies\System\CredSSP\Parameters\
get-hotfix | ? {$_.hotfixid -eq "kb4056564"}

#Create a download location
md c:\temp


##Download the KB file
$source = "http://download.windowsupdate.com/d/msdownload/update/software/secu/2018/04/windows6.0-kb4056564-v2-x64_173bf5ef3e4cfba4c43899d8db9f25c6dcccab22.msu" #server 2008 x64
$destination = "c:\temp\windows6.0-kb4056564-v2-x64_173bf5ef3e4cfba4c43899d8db9f25c6dcccab22.msu"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($source,$destination)

#Install the KB
expand -F:* $destination C:\temp\
pkgmgr /ip /m:c:\temp\Windows6.0-kb4056564-v2-x64.cab /quiet /norestart /l:log.log

#Add the vulnerability key to allow unpatched clients
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters\"
New-ItemProperty -Path $RegPath -Name AllowEncryptionOracle -Value 2 -PropertyType DWORD -Force
#//TODO add test condition to ensure it installed. goto line 9
#Restart the VM to complete the installations/settings
shutdown /r /t 0 /f