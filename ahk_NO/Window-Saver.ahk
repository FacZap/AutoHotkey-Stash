; ===============================
; Window Recall Script
; Win+F5 = Save current window
; Win+F4 = Restore saved window
; ===============================

savedHwnd := ""

#F5::
    WinGet, hwnd, ID, A
    if (hwnd)
    {
        savedHwnd := hwnd
        WinGetTitle, title, ahk_id %hwnd%
        TrayTip, Window Saved, % "Saved:`n" title, 2
    }
    return


#F4::
    if (savedHwnd = "")
    {
        MsgBox, 48, No Window Stored, No window has been stored yet.
        return
    }

    ; Check if window still exists
    if !WinExist("ahk_id " savedHwnd)
    {
        MsgBox, 48, Window Closed, The stored window no longer exists.`nState cleared.
        savedHwnd := ""
        return
    }

    ; Restore window
    WinActivate, ahk_id %savedHwnd%
    return
