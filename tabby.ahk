Tab & CapsLock:: ; MANTENER TAB, y después presionar CapsLock
    SetKeyDelay, 30
    SendMode, Event
    SetTitleMatchMode, 2
    CoordMode, Mouse, Screen

    Send, {Blind}{Ctrl Down}{Shift Down}2{Shift Up}{Ctrl Up}
    Sleep, 350

    MouseClick, left, 262, 198
    Sleep, 500

    MouseClick, left, 544, 300
    Sleep, 122

    Sleep, 100

    Send, {Blind}{Shift Down}{Ctrl Down}{Tab}{Ctrl Up}{Shift Up}
return
