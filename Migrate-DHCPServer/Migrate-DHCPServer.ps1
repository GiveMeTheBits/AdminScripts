#Run Elevated on New DHCP Server
#Declare Vars
$OldDHCPServer = 'old'
$OldDHCPServerIP = 'ip'
$NewDHCPServer = 'new'
$NewDHCPServerIP = 'ip'
$NewDNSIP = 'ip'
#Install DHCP Role and Management Tools
Add-WindowsFeature -IncludeManagementTools DHCP
#Create local DHCP security groups (DHCP Administrators and DHCP Users)
Add-DhcpServerSecurityGroup 
#Restart the DHCP Service for settings to take effect
Restart-Service DHCPServer 
#Authorize New DHCP Server
Add-DhcpServerInDC  $NewDHCPServer $NewDHCPServerIP.RemoteAddress.IPAddressToString 
#Set DHCP Post-Deployment Status as complete (Server Manager)
Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles –Name ConfigurationState –Value 2
#Create Folder to hold Export
New-Item -Path C:\DHCP -ItemType Directory 
#Export the DHCP Server Settings and Leases to the new Folder
Export-DhcpServer -ComputerName $OldDHCPServer -Leases -File "C:\DHCP\OldDHCPConf.xml" –Verbose 
#Modify the Export to replace the old Server IP with the New Server IP for DNS
(Get-Content C:\DHCP\OldDHCPConf.xml).replace($OldDHCPServerIP, $NewDNSIP) | Set-Content C:\DHCP\OldDHCPConf.xml 
#Import the Modified DHCP Settings to the new DHCP Server
Import-DhcpServer -Leases –File "C:\DHCP\OldDHCPConf.xml" -BackupPath "C:\DHCP\Backup\" –Verbose 
Write-Warning -Message 'Inform Networking Contact to Update DHCP Relay (IP Helper)'