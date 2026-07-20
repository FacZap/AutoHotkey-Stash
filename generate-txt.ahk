^F7::
CoordMode, Mouse, Screen  ; Set mouse coordinates to screen coordinates

MouseGetPos, ClickX, ClickY  ; Get current cursor position

; Right-click at the cursor position
Click, Right, , , , , U

; Wait for 50ms between key presses
Sleep, 50

; Send the key presses
Send, {Up 2}
Sleep, 50
Send, {Right}
Sleep, 50
Send, {Up 5}
Sleep, 50
Send, {Enter}

return

