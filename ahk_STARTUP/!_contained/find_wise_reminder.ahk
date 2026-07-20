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
	} ; Win+b activates the tray, w marks the icon of WiseReminder
    Else
        WinActivate, ahk_exe WiseReminder.exe
}
else  ; is NOT running
    Run, "C:\Program Files (x86)\Wise\Wise Reminder\WiseReminder.exe"
return