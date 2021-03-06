<#
.Synopsis
    Sets Default New Reply Signature based on template.
.DESCRIPTION
   Copies a .Docx template to the users Outlook Signature folder, Creates the Signature Files based on the Template using ADSI lookup of the user and sets it as the default New Message option.
.EXAMPLE
   Make sure the $SigSource Variable is set to the .Docx path for the template you want to use.
   The Template Should contain FullName, Title, TelephoneNumber which are lookup strings for the ADSI Info to replace.
#>

#Custom variables
$SigSource      = Get-ChildItem ".\sig.docx" #Path to the *.docx file, i.e "c:\temp\template.docx"
$ForceSignature = '0' #Set to 1 if you don't want the users to be able to change Signature options in Outlook
$DefaultSignature = '0' #Set to 1 if you want to set the default signature to this new template, 0 if you just want it to be available for use.
 
#Environment variables
	#Get Office Version 
	$OfficeVersion = (Get-ItemProperty -Path Registry::HKEY_CLASSES_ROOT\Outlook.Application\CurVer). "(Default)".split('.')[2] + ".0"
	#Get Name of Outlook Signature Folder 
	$OutlookSigDirName = (Get-ItemProperty -Path Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Office\$OfficeVersion\Common\General). "Signatures"
	#Build Path for Outlook Signature 
    $LocalSignaturePath      = "${env:appdata}\Microsoft\$OutlookSigDirName"
    $RemoteSignaturePathFull = [System.IO.Path]::GetFullPath($SigSource)
    $SignatureName           = [System.IO.Path]::GetFileNameWithoutExtension($SigSource)
    $fullPath                = $LocalSignaturePath+'\'+$SignatureName+'.docx'


#Get Active Directory information for current user
$UserName          = $env:username
$Filter            = "(&(objectCategory=User)(samAccountName=$UserName))"
$Searcher          = New-Object System.DirectoryServices.DirectorySearcher
$Searcher.Filter   = $Filter
$ADUserPath        = $Searcher.FindOne()
$ADUser            = $ADUserPath.GetDirectoryEntry()
$ADTitle           = $ADUser.title.ToString()
$ADTelePhoneNumber = $ADUser.TelephoneNumber.ToString()
$ADModify          = [DateTime]$ADUser.whenChanged.ToString()
$ADGivenName       = $ADUser.givenName.ToString()
$ADSurname         = $ADUser.sn.ToString()
$Name              = $ADGivenName+' '+$ADSurname

#Check modified dates on template and ADUser object to determine if to proceed.
$SigTemplateAlreadyCopied = Test-Path $fullPath
$SigCopiedTemplate = Get-ChildItem $fullPath
$SigHTMFile = get-childitem "$LocalSignaturePath\$SignatureName.htm"

if (($SigHTMFile.LastWriteTime -lt $ADModify) -or ($SigCopiedTemplate.LastWriteTime -lt $SigSource.LastWriteTime) -and ($SigTemplateAlreadyCopied -eq $False)) {
    Write-Output "Signature needs updated"
}
Elseif ($SigTemplateAlreadyCopied -eq $True) {
    Write-Output "Signature is Current"
    Break
}

#Check signature path (needs to be created if a signature has never been created for the profile)
if (-not(Test-Path -path $LocalSignaturePath)) {
	New-Item $LocalSignaturePath -Type Directory
}

#Copy signature templates from source to local Signature-folder
Write-Output "Copying $SignatureName.docx to $LocalSignaturePath"
Copy-Item "$Sigsource" $LocalSignaturePath -Recurse -Force

#Word Com Object Properties
$ReplaceAll        = 2
$FindContinue      = 1
$MatchCase         = $False
$MatchWholeWord    = $True
$MatchWildcards    = $False
$MatchSoundsLike   = $False
$MatchAllWordForms = $False
$Forward           = $True
$Wrap              = $FindContinue
$Format            = $False
	
#Insert variables from ADSI lookup to signature files
$MSWord   = New-Object -ComObject word.application
$MSWord.Documents.Open($fullPath)

Write-Output "Modifying $fullPath with ADSI Lookup Values"

#User Name 
$FindText = "FullName" 
	$ReplaceText = $Name
$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)	

#Title		
$FindText = "Title"
    $ReplaceText = $ADTitle
$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
#Telephone
$FindText = "TelephoneNumber"
	$ReplaceText = $ADTelephoneNumber
$MSWord.Selection.Find.Execute($FindText, $MatchCase, $MatchWholeWord,	$MatchWildcards, $MatchSoundsLike, $MatchAllWordForms, $Forward, $Wrap,	$Format, $ReplaceText, $ReplaceAll	)
	
#Save new message signature 
Write-Output "Saving signatures"
#Save HTML
$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatHTML");
$path = $LocalSignaturePath+'\'+$SignatureName+".htm"
$MSWord.ActiveDocument.saveas([ref]$path, [ref]$saveFormat)
    
#Save RTF 
$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatRTF");
$path = $LocalSignaturePath+'\'+$SignatureName+".rtf"
$MSWord.ActiveDocument.SaveAs([ref] $path, [ref]$saveFormat)
	
#Save TXT    
$saveFormat = [Enum]::Parse([Microsoft.Office.Interop.Word.WdSaveFormat], "wdFormatText");
$path = $LocalSignaturePath+'\'+$SignatureName+".txt"
$MSWord.ActiveDocument.SaveAs([ref] $path, [ref]$SaveFormat)

#Close Active Document
$MSWord.ActiveDocument.Close()

#Set Default Signature
If ($DefaultSignature -eq '1') {
    $MSWord = New-Object -comobject word.application
        $MSWord.EmailOptions.EmailSignature.NewMessageSignature   = $SignatureName
        #$MSWord.EmailOptions.EmailSignature.ReplyMessageSignature = $SignatureName
}

#Force Signature, preventing modification of signatures except inline editing.
If ($ForceSignature -eq '1') {
    New-ItemProperty HKCU:"\Software\Microsoft\Office\$OfficeVersion\Common\MailSettings" -Name 'ReplySignature' -Value $SignatureName -PropertyType 'String' -Force
    New-ItemProperty HKCU:"\Software\Microsoft\Office\$OfficeVersion\Common\MailSettings" -Name 'NewSignature' -Value $SignatureName -PropertyType 'String' -Force
}

#Remove Word process from memory
$MSWord.Quit()