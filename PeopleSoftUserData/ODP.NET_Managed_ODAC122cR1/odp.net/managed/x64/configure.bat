@ECHO OFF
REM
REM configure.bat
REM
REM This .bat file configures ODP.NET, Managed Driver
REM

if /i {%1} == {-h} goto :Usage
if /i {%1} == {-help} goto :Usage

REM configure machine wide or not - default is false
set MACHINE_WIDE_CONFIGURATION=false
if /i {%1} == {true} set MACHINE_WIDE_CONFIGURATION=true
  
if {%MACHINE_WIDE_CONFIGURATION%} == {true} (

REM Configure machine.config for ODP.NET, Managed Driver's configuration file section handler and client factory
echo.
echo OraProvCfg /action:config /product:odpm /frameworkversion:v4.0.30319 /providerpath:"%~dp0..\common\Oracle.ManagedDataAccess.dll" /set:settings\TNS_ADMIN:"%~dp0..\..\..\network\admin"
OraProvCfg /action:config /product:odpm /frameworkversion:v4.0.30319 /providerpath:"%~dp0..\common\Oracle.ManagedDataAccess.dll" /set:settings\TNS_ADMIN:"%~dp0..\..\..\network\admin" 

REM Place the ODP.NET, Managed Driver assemblies into the GAC
echo.
echo OraProvCfg /action:gac /providerpath:"%~dp0..\common\Oracle.ManagedDataAccess.dll"        
OraProvCfg /action:gac /providerpath:"%~dp0..\common\Oracle.ManagedDataAccess.dll" 

REM Place the ODP.NET, Managed Policy assembly into the GAC
echo.
echo OraProvCfg /action:gac /providerpath:"%~dp0..\PublisherPolicy\4\Policy.4.121.Oracle.ManagedDataAccess.dll"        
OraProvCfg /action:gac /providerpath:"%~dp0..\PublisherPolicy\4\Policy.4.121.Oracle.ManagedDataAccess.dll"

)      

REM Add a registry entry for enabling event logs
echo.
echo reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\EventLog\Application\Oracle Data Provider for .NET, Managed Driver" /v EventMessageFile /t REG_EXPAND_SZ /d %SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\EventLogMessages.dll /f
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\EventLog\Application\Oracle Data Provider for .NET, Managed Driver" /v EventMessageFile /t REG_EXPAND_SZ /d %SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\EventLogMessages.dll /f

REM Delete the old registry entry to add managed assembly in the Add Reference Dialog box in VS.NET
echo.
echo reg query HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319\AssemblyFoldersEx\odp.net.managed\
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319\AssemblyFoldersEx\odp.net.managed\ 1>NUL 2>NUL
if %ERRORLEVEL% EQU 0 (
echo reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319\AssemblyFoldersEx\odp.net.managed" /f
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319\AssemblyFoldersEx\odp.net.managed" /f 1>NUL 2>NUL
)

REM Create a registry entry to add managed assembly in the Add Reference Dialog box in VS.NET
echo.
echo reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319\AssemblyFoldersEx\Oracle.ManagedDataAccess" /ve /t REG_SZ /d %~dp0..\common /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319\AssemblyFoldersEx\Oracle.ManagedDataAccess" /ve /t REG_SZ /d %~dp0..\common /f
echo.
echo reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319\AssemblyFoldersEx\Oracle.ManagedDataAccess.EntityFramework6" /ve /t REG_SZ /d %~dp0..\common\EF6 /f
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\.NETFramework\v4.0.30319\AssemblyFoldersEx\Oracle.ManagedDataAccess.EntityFramework6" /ve /t REG_SZ /d %~dp0..\common\EF6 /f

goto :EOF

:Usage 
echo. 
echo Usage: 
echo   configure.bat [machine_wide_configuration]
echo. 
echo Example: 
echo   configure.bat      (do not configure ODP.NET, Managed Driver at a machine wide level) 
echo   configure.bat true (configure ODP.NET, Managed Driver at a machine wide level) 
echo.
echo NOTE: By default, machine_wide_configuration=false.
goto :EOF
