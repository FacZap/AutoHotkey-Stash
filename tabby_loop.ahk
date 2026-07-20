#Persistent
SetKeyDelay, 30
SendMode, Event
SetTitleMatchMode, 2
CoordMode, Mouse, Screen

toggle := false

Tab & CapsLock::
toggle := !toggle  ; Toggle loop on/off
if (toggle) {
    SetTimer, RunMacro, 0
} else {
    SetTimer, RunMacro, Off
}
return

RunMacro:
    ; Main macro actions
    Send, {Blind}{Ctrl Down}{Shift Down}2{Shift Up}{Ctrl Up}
    Sleep, 350

    MouseClick, left, 262, 198
    Sleep, 500

    MouseClick, left, 544, 300
    Sleep, 122

    Sleep, 100

    Send, {Blind}{Shift Down}{Ctrl Down}{Tab}{Ctrl Up}{Shift Up}
    Sleep, 9000  ; Delay between loop iterations
return
