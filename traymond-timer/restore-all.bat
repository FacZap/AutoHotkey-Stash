@echo off
REM ============================================================================
REM Restore every window Traymond has currently hidden, then exit.
REM Fire-and-forget: nothing stays resident, so this is ideal for Task Scheduler.
REM
REM Schedule it for 17:30 every day:
REM   schtasks /create /tn "Traymond restore all" /tr "\"%~f0\"" /sc daily /st 17:30
REM Every 30 minutes, all day:
REM   schtasks /create /tn "Traymond restore all" /tr "\"%~f0\"" /sc minute /mo 30
REM Remove it again:
REM   schtasks /delete /tn "Traymond restore all" /f
REM ============================================================================

setlocal
set "AHK=%ProgramFiles%\AutoHotkey\AutoHotkey.exe"
if not exist "%AHK%" set "AHK=%ProgramFiles(x86)%\AutoHotkey\AutoHotkey.exe"
if not exist "%AHK%" (
    echo AutoHotkey.exe not found - use restore-all.ps1 instead, it needs no AutoHotkey.
    exit /b 1
)

"%AHK%" "%~dp0traymond-timer.ahk" /restore-all
exit /b 0
