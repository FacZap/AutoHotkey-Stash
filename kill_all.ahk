#NoTrayIcon
#Persistent

^+!k:: ; Ctrl + Shift + Alt + K to trigger
WinGet, idList, List
Loop, % idList {
    this_id := idList%A_Index%

    ; Get window properties
    WinGetTitle, title, ahk_id %this_id%
    WinGetClass, class, ahk_id %this_id%
    WinGet, exe, ProcessName, ahk_id %this_id%
    WinGet, style, Style, ahk_id %this_id%

    ; Skip desktop-related classes
    if (class = "Progman" or class = "WorkerW")
        continue

    ; Skip Chrome and Edge
    if (exe = "chrome.exe" or exe = "msedge.exe")
        continue

    ; Skip if window has no title (likely background or system)
    if (title = "")
        continue

    ; Only close visible windows
    if (style & 0x10000000) {
        WinClose, ahk_id %this_id%
        Sleep, 100
    }
}
return
