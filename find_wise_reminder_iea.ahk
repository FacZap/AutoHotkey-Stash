clickX   := 600   ; X coordinate where to click inside the window
clickY   := 40    ; Y coordinate where to click inside the window
clickXX  := 500   ; X coordinate where to click inside the window
clickYY  := 150    ; Y coordinate where to click inside the window

#|::
Process, Exist, WiseReminder.exe
If (Errorlevel != 0) ; is running
{
    WinGet, WinState, MinMax, ahk_exe WiseReminder.exe
    If (WinState = "") { ; is minimized to tray
        	SendInput #b
		SendInput {Enter}
		Sleep 50
		SendInput {Up}
		SendInput w
		Sleep 60
		SendInput {Enter}
		Sleep 100
		Click, %clickX%, %clickY%
		Sleep 1000
		Click, %clickXX%, %clickYY%
	} ; Win+b activates the tray, w marks the icon of WiseReminder
    Else
        WinActivate, ahk_exe WiseReminder.exe
}
else  ; is NOT running
    Run, "C:\Program Files (x86)\Wise\Wise Reminder\WiseReminder.exe"
return

