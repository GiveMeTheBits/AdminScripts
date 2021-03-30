If($PSVersionTable.PSVersion)
    {Write-Host "PSVersion is $($PSVersionTable.PSVersion)" -ForegroundColor Cyan}
Else
    {Write-Host 'PSVersion is 1.0' -ForegroundColor Cyan}

if ($ScriptPath = $PSScriptRoot) #Works in Version 3+
    {
    Write-Host '$PSScriptRoot Works' -ForegroundColor Green
    $ScriptPath
    }
if ($ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent)
    {
    Write-Host '$MyInvocation.MyCommand.Path Works' -ForegroundColor Green
    $ScriptPath
    }
if ($ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)
    {
    Write-Host '$MyInvocation.MyCommand.Definition Works' -ForegroundColor Green
    $ScriptPath
    }
if ({$Path = $psISE.CurrentFile.FullPath
    $ScriptPath = Split-Path -Parent -Path $Path})
    {
    Write-Host '$psISE.CurrentFile.FullPath Works' -ForegroundColor Green
    $ScriptPath
    }
if ($ScriptPath = (Get-ChildItem -Path .\Test-ScriptRootPath.ps1).DirectoryName) #Needs to know the relative path to the running script
    {
    Write-Host 'Get-ChildItem Works' -ForegroundColor Green
    $ScriptPath
    }
if ($ScriptPath = (dir | select-object Directory -unique).directory.fullname)
    {
    Write-Host 'Dir | Select-object Works' -ForegroundColor Green
    $ScriptPath
    }

if (!($ScriptPath)){
    Write-Host 'Cannot resolve script file path' -ForegroundColor red
    sleep 3
    exit 1
    }

