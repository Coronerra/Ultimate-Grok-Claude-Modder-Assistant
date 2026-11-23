@echo off
rem Grok Modding Kit - PC setup launcher. MIT License, Copyright (c) 2026 Jezebel Graves.
rem Asks Windows for admin rights (UAC), then runs setup.ps1 next to this file with
rem ExecutionPolicy Bypass for that one PowerShell process only (nothing is changed system-wide).
rem Usage: double-click setup.bat     or     setup.bat -DryRun
rem install.bat (kit top folder) sets GMK_GAME=SE or VR and GMK_NOPAUSE=1 before calling this file.
setlocal EnableExtensions DisableDelayedExpansion

set "GMK_PS1=%~dp0setup.ps1"
if not exist "%GMK_PS1%" (
  echo setup.ps1 was not found next to setup.bat. Keep both files in the same folder.
  pause
  exit /b 1
)

rem Hand values to PowerShell through environment variables so spaces, ^& and quotes in
rem paths or names cannot break the command line. The elevated process does not inherit
rem these, so the launcher turns them into quoted arguments.
set "GMK_USER=%USERNAME%"
set "GMK_DOMAIN=%USERDOMAIN%"
set "GMK_PROFILE=%USERPROFILE%"
set "GMK_DRYRUN="
if /i "%~1"=="-DryRun" set "GMK_DRYRUN=1"
if /i "%~1"=="/DryRun" set "GMK_DRYRUN=1"
if /i "%~1"=="-WhatIf" set "GMK_DRYRUN=1"
if /i not "%GMK_GAME%"=="SE" if /i not "%GMK_GAME%"=="VR" set "GMK_GAME=Ask"

echo Grok Modding Kit PC setup
echo Windows will ask for administrator permission. Every change is asked again first; Enter means No.
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$q = [char]34;" ^
  "$a = '-NoProfile -ExecutionPolicy Bypass -File ' + $q + $env:GMK_PS1 + $q + ' -TargetUser ' + $q + $env:GMK_USER + $q + ' -TargetDomain ' + $q + $env:GMK_DOMAIN + $q + ' -TargetProfile ' + $q + $env:GMK_PROFILE + $q + ' -Game ' + $env:GMK_GAME + ' -PauseAtEnd';" ^
  "if ($env:GMK_DRYRUN) { $a += ' -DryRun' };" ^
  "try { $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $a -Verb RunAs -Wait -PassThru; exit $p.ExitCode }" ^
  "catch { Write-Host 'Administrator permission was not given, so nothing was changed.'; exit 1223 }"
set "GMK_RC=%ERRORLEVEL%"

echo.
if "%GMK_RC%"=="0" (
  echo Setup finished. The log is setup-log.txt next to this file.
) else (
  echo Setup ended with code %GMK_RC%. See setup-log.txt next to this file.
)
if not "%GMK_NOPAUSE%"=="1" pause
endlocal & exit /b %GMK_RC%
