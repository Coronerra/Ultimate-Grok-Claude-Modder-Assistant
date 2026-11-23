@echo off
rem Grok Modding Kit for Skyrim (SE/AE and VR) - Windows installer for the modding PC.
rem MIT License, Copyright (c) 2026 Jezebel Graves. See LICENSE.
rem
rem What it does: checks prerequisites, asks SE/AE or VR, then runs pc-setup\setup.bat
rem (which asks Windows for admin rights and runs pc-setup\setup.ps1). Every change in
rem setup.ps1 is asked first and Enter means No. Files it changes are backed up first.
rem It never edits modlist.txt, plugins.txt, loadorder.txt or any game or mod file.
rem
rem Usage: double-click install.bat     or     install.bat -DryRun   (shows what it would do)
rem        install.bat SE   or   install.bat VR   skips the game question.
setlocal EnableExtensions DisableDelayedExpansion
title Grok Modding Kit for Skyrim - installer
set "KIT_DIR=%~dp0"
set "GMK_RC=1"
set "GMK_ARG="
set "GMK_GAME="

for %%A in (%*) do (
  if /i "%%~A"=="-DryRun" set "GMK_ARG=-DryRun"
  if /i "%%~A"=="/DryRun" set "GMK_ARG=-DryRun"
  if /i "%%~A"=="-WhatIf" set "GMK_ARG=-DryRun"
  if /i "%%~A"=="SE" set "GMK_GAME=SE"
  if /i "%%~A"=="AE" set "GMK_GAME=SE"
  if /i "%%~A"=="VR" set "GMK_GAME=VR"
)

echo ============================================================
echo  Grok Modding Kit for Skyrim (SE/AE and VR) - PC installer
echo ============================================================
echo.
echo This sets up YOUR modding PC so your Grok Bot can reach it over
echo Tailscale + SSH. Every change is asked first; Enter means No.
echo It never edits modlist.txt, plugins.txt, loadorder.txt, game or mod files.
if defined GMK_ARG echo DRY RUN: nothing will be changed.
echo.

rem ---- 1. prerequisites -------------------------------------------------
echo [1/3] Checking prerequisites...
if /i not "%OS%"=="Windows_NT" (
  echo   This installer needs Windows 10 or 11.
  goto :end
)
if not exist "%KIT_DIR%pc-setup\setup.bat" (
  echo   pc-setup\setup.bat is missing. Unzip the WHOLE kit and run install.bat from its top folder.
  goto :end
)
if not exist "%KIT_DIR%pc-setup\setup.ps1" (
  echo   pc-setup\setup.ps1 is missing. Unzip the WHOLE kit and run install.bat from its top folder.
  goto :end
)
where powershell.exe >nul 2>&1
if errorlevel 1 (
  echo   Windows PowerShell [powershell.exe] was not found. It ships with Windows 10 and 11; repair Windows PowerShell first.
  goto :end
)
echo   Windows and PowerShell: OK
where winget >nul 2>&1
if errorlevel 1 (
  echo   winget: not found. Setup will show download links instead of installing Python, Git and Tailscale for you.
) else (
  echo   winget: OK
)
set "GMK_RUNNING="
for %%P in (SkyrimSE.exe SkyrimVR.exe ModOrganizer.exe) do (
  tasklist /FI "IMAGENAME eq %%P" 2>nul | find /i "%%P" >nul && set "GMK_RUNNING=1" && echo   Note: %%P is running.
)
if defined GMK_RUNNING (
  echo   Setup does not touch game or mod files, but closing the game and MO2 first is safest.
)
echo.

rem ---- 2. which game ----------------------------------------------------
echo [2/3] Which game is this PC set up for?
if defined GMK_GAME goto :gamechosen
:askgame
echo   1 = Skyrim Special Edition / Anniversary Edition (flat screen)
echo   2 = Skyrim VR
set "GMK_PICK="
set /p "GMK_PICK=  Type 1 or 2 and press Enter: "
if "%GMK_PICK%"=="1" set "GMK_GAME=SE"
if "%GMK_PICK%"=="2" set "GMK_GAME=VR"
if not defined GMK_GAME (
  echo   Please type 1 or 2.
  goto :askgame
)
:gamechosen
if /i "%GMK_GAME%"=="VR" (echo   Selected: Skyrim VR) else (echo   Selected: Skyrim SE/AE)
echo.

rem ---- 3. run the guided setup -------------------------------------------
echo [3/3] Starting the guided setup. Windows will ask for administrator permission.
set "GMK_NOPAUSE=1"
call "%KIT_DIR%pc-setup\setup.bat" %GMK_ARG%
set "GMK_RC=%ERRORLEVEL%"
echo.

echo ============================================================
echo  Next steps
echo ============================================================
if "%GMK_RC%"=="0" (
  echo  Setup finished. Log: pc-setup\setup-log.txt
) else (
  echo  Setup ended with code %GMK_RC%. Read pc-setup\setup-log.txt before trying again.
)
echo.
echo  1. Open Tailscale and sign in, if it asked you to.
echo  2. Install the script extender for your game through your mod manager:
if /i "%GMK_GAME%"=="VR" (
  echo       SKSEVR, plus VR Address Library for SKSEVR when a mod needs it.
) else (
  echo       SKSE64 for your game version, plus Address Library for SKSE Plugins.
)
echo  3. Tell your Grok Bot: which game, your Tailscale machine name or IP,
echo     your Windows user name, and the game / MO2 paths shown above.
echo     Never send a password or a private key.
echo  4. Say to the bot: "Run the getting-started Skyrim modding skill."
echo  Full instructions: INSTALL.md in this folder. Uninstall: see INSTALL.md.
goto :done

:end
echo.
echo Nothing was changed. See INSTALL.md for help.
:done
echo.
pause
endlocal & exit /b %GMK_RC%
