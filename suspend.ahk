; Suspend All Other AHK Scripts - Ctrl+Alt+Shift+P

#Persistent
; #NoTrayIcon
SetTitleMatchMode, 2

toggle := false

^!+p:: ; Ctrl + Alt + Shift + P
{
    toggle := !toggle

    ; Get list of all running AutoHotkey scripts
    DetectHiddenWindows, On
    WinGet, idList, List, ahk_class AutoHotkey

    Loop, % idList
    {
        this_id := idList%A_Index%
        WinGetTitle, this_title, ahk_id %this_id%
        
        Sleep, Delay 100

        ; Skip this script itself
        if InStr(this_title, "suspend.ahk")
            continue

        ; Send suspend toggle to each script
        PostMessage, 0x111, 65305,,, ahk_id %this_id% ; 65305 = ID for "Suspend"
    }

    TrayTip, AHK Suspension, % toggle ? "All other scripts suspended." : "All other scripts unsuspended.", 2
    return
}
