#Persistent
#NoEnv
DetectHiddenWindows, On
SetTitleMatchMode, 2
SetTimer, CheckActiveWindow, 500  ; Check every 500ms

lastWasVLC := false

CheckActiveWindow:
    WinGet, activeProcessName, ProcessName, A

    if (activeProcessName = "vlc.exe") {
        if (!lastWasVLC) {
            ; Switched to VLC
            Send, #{Space}
            lastWasVLC := true
        }
    } else {
        if (lastWasVLC) {
            ; Switched away from VLC
            Send, #{Space}
            lastWasVLC := false
        }
    }
return
