; ==========================================
; Multi-window save + cycle + remove + list (AHK v1)
;
; Win+F5        = Add active window
; Win+F4        = Cycle stored windows
; Win+Shift+F5  = Remove active window from stored list
; Win+Shift+F4  = Show GUI list (hides when Win released)
; ==========================================

global gWindows := []
global gIndex := 0
global gListGuiVisible := false

; GUI control vars MUST be global/static if used in a function
global LVWinList

; -------------------------
; Add active window
; -------------------------
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


; -------------------------
; Cycle stored windows
; -------------------------
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

    ; Extra safety
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
; Remove current (active) window from list
; Win + Shift + F5
; -------------------------
#+F5::
    if (gWindows.Length() = 0)
    {
        MsgBox, 48, Nothing Stored, No windows are stored.
        gIndex := 0
        return
    }

    CleanClosedWindows()

    if (gWindows.Length() = 0)
    {
        MsgBox, 48, Nothing Stored, No windows are stored.
        gIndex := 0
        return
    }

    WinGet, hwnd, ID, A
    if (!hwnd)
        return

    removed := false
    for i, v in gWindows
    {
        if (v = hwnd)
        {
            gWindows.RemoveAt(i)
            removed := true

            if (gIndex >= i)
                gIndex--

            break
        }
    }

    if (removed)
    {
        WinGetTitle, title, ahk_id %hwnd%
        TrayTip, Removed, % "Removed:`n" title, 2
    }
    else
    {
        TrayTip, Not Found, Active window wasn't in the list., 2
    }

    if (gWindows.Length() = 0)
        gIndex := 0
return


; -------------------------
; List all saved windows in a GUI
; Win + Shift + F4
; GUI hides automatically when Win is released
; -------------------------
#+F4::
    if (gListGuiVisible)
        return

    CleanClosedWindows()

    if (gWindows.Length() = 0)
    {
        MsgBox, 48, No Windows Stored, No windows are stored.
        gIndex := 0
        return
    }

    ShowWindowListGui()
return


; -------------------------
; Helpers
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

ShowWindowListGui() {
    global gWindows, gIndex, gListGuiVisible, LVWinList

    gListGuiVisible := true

    Gui, WinList:New, +AlwaysOnTop -Caption +ToolWindow +Border
    Gui, WinList:Margin, 10, 10
    Gui, WinList:Font, s9, Segoe UI
    Gui, WinList:Add, Text,, Saved Windows (Win+F4 cycles)
    Gui, WinList:Add, ListView, w520 r10 Grid -Multi vLVWinList, #|Current|Title|HWND

    Gui, WinList:Default
    Gui, WinList:ListView, LVWinList

    LV_ModifyCol(1, 40)
    LV_ModifyCol(2, 55)
    LV_ModifyCol(3, 360)
    LV_ModifyCol(4, 80)

    for i, hwnd in gWindows
    {
        WinGetTitle, title, ahk_id %hwnd%
        cur := (i = gIndex ? "◀" : "")
        LV_Add("", i, cur, title, hwnd)
    }

    ; ---- HERE: fixed coordinates ----
    Gui, WinList:Show, x100 y100 NoActivate, WinList  ; x/y in pixels
    ; ----------------------------------

    SetTimer, __WinList_CheckWinReleased, 50
}

__WinList_CheckWinReleased:
    global gListGuiVisible

    if (!GetKeyState("LWin","P") && !GetKeyState("RWin","P"))
    {
        SetTimer, __WinList_CheckWinReleased, Off
        Gui, WinList:Destroy
        gListGuiVisible := false
    }
return
