; ==========================================
; Multi-window recall + cycling (AHK v1)
; Win+F5 = Add active window
; Win+F4 = Cycle stored windows
; ==========================================

global gWindows := []
global gIndex := 0

#F5::
    WinGet, hwnd, ID, A
    if (!hwnd)
        return

    ; Prevent duplicates
    for i, v in gWindows
    {
        if (v = hwnd)
        {
            TrayTip, Window Already Saved, This window is already stored., 2
            return
        }
    }

    gWindows.Push(hwnd)
    WinGetTitle, title, ahk_id %hwnd%
    TrayTip, Window Saved, % "Added (" gWindows.Length() "):`n" title, 2
return


#F4::
    if (gWindows.Length() = 0)
    {
        MsgBox, 48, No Windows Stored, No windows have been stored yet.
        gIndex := 0
        return
    }

    CleanClosedWindows()

    if (gWindows.Length() = 0)
    {
        MsgBox, 48, All Windows Closed, All stored windows were closed.`nList cleared.
        gIndex := 0
        return
    }

    ; Cycle index
    gIndex++
    if (gIndex > gWindows.Length())
        gIndex := 1

    hwnd := gWindows[gIndex]

    if !WinExist("ahk_id " hwnd)
    {
        gWindows.RemoveAt(gIndex)
        gIndex--
        Gosub, #F4
        return
    }

    WinActivate, ahk_id %hwnd%
return


; -------------------------
; Helpers (AHK v1-safe)
; -------------------------

CleanClosedWindows() {
    global gWindows, gIndex

    count := gWindows.Length()
    Loop % count
    {
        i := count - A_Index + 1  ; iterate backwards
        hwnd := gWindows[i]

        if !WinExist("ahk_id " hwnd)
        {
            gWindows.RemoveAt(i)
            if (gIndex >= i)
                gIndex--
        }
    }

    if (gIndex < 0)
        gIndex := 0
}
