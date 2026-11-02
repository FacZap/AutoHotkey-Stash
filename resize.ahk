^!MButton::
    WinGet, winID, ID, A  ; Get active window ID
    if (winID)
    {
        WinMove, ahk_id %winID%, , , , 300, 300  ; Resize to 200x200, keep current position
    }
return

^!RButton::
    WinGet, winID, ID, A
    if (winID)
    {
        ; Restore if minimized/maximized
        WinRestore, ahk_id %winID%

        ; Get window size
        WinGetPos, X, Y, W, H, ahk_id %winID%

        ; Calculate center of primary screen
        newX := (A_ScreenWidth  - W) // 2
        newY := (A_ScreenHeight - H) // 2

        ; Move it back into view
        WinMove, ahk_id %winID%, , newX, newY
    }
return