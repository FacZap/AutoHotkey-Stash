#Requires AutoHotkey v2.0
#include UIA.ahk

IniFile := A_ScriptDir "\find_google_calendar.ini"
BrowserExe := Map("Chrome", "chrome.exe", "Firefox", "firefox.exe")
    .Get(IniRead(IniFile, "Settings", "Browser", "Chrome"), "chrome.exe")

+NumpadEnter::
{
    global BrowserExe
    for hwnd in WinGetList("ahk_exe " BrowserExe) {
        root := UIA.ElementFromHandle(hwnd)
        for tab in root.FindElements({Type: "TabItem"}) {
            if InStr(tab.Name, "Calendario") || InStr(tab.Name, "Google Calendar") {
                tab.Select()
                MsgBox(tab.Name)
                WinActivate("ahk_id " hwnd)
                return
            }
        }
    }
}