; Since v2 the process also owns a small visible toolwindow titled "Wise Reminder",
; so "ahk_exe WiseReminder.exe" no longer tells whether the main window is in the
; tray. The main window is found by its WPF class + title, skipping toolwindows.
; When hidden it can't be WinShow'n (WPF leaves it blank): instead the WinForms
; NotifyIcon gets its own tray message (WM_USER+1024) with a double-click.

#z::
Process, Exist, WiseReminder.exe
If (ErrorLevel = 0) {
    Run, "C:\Program Files (x86)\Wise\Wise Reminder\WiseReminder.exe"
    return
}
mainHwnd := 0, trayHwnd := 0
DetectHiddenWindows, On
WinGet, list, List, ahk_exe WiseReminder.exe
Loop, %list%
{
    h := list%A_Index%
    WinGetClass, cls, ahk_id %h%
    WinGetTitle, title, ahk_id %h%
    WinGet, exStyle, ExStyle, ahk_id %h%
    if (InStr(cls, "HwndWrapper[WiseReminder.exe") = 1 && title = "Wise Reminder" && !(exStyle & 0x80))
        mainHwnd := h
    else if (InStr(cls, "WindowsForms10.Window.") = 1)
        trayHwnd := h
}
if (mainHwnd && DllCall("IsWindowVisible", "ptr", mainHwnd)) {
    WinActivate, ahk_id %mainHwnd%
    DetectHiddenWindows, Off
    return
}
if (trayHwnd)
    PostMessage, 0x800, 0, 0x203,, ahk_id %trayHwnd%   ; WM_LBUTTONDBLCLK
DetectHiddenWindows, Off
if (mainHwnd) {
    WinWait, ahk_id %mainHwnd%,, 2
    if (!ErrorLevel)
        WinActivate, ahk_id %mainHwnd%
}
return
