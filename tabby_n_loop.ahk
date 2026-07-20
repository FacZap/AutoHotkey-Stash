#Persistent
SetKeyDelay, 30
SendMode, Event
SetTitleMatchMode, 2
CoordMode, Mouse, Screen

global running := false
global loopCount := 0
global currentIteration := 0

Tab & CapsLock::
if (running) {
    running := false
    MsgBox, Loop detenido.
    return
}
Gui, +AlwaysOnTop
Gui, Add, Text,, Ingresá cuántas veces ejecutar el macro:
Gui, Add, Edit, vLoopInputNumber w100 Number
Gui, Add, Button, default gStartLoop, OK
Gui, Show,, Ejecutar Macro
return

StartLoop:
Gui, Submit
if (LoopInputNumber < 1) {
    MsgBox, Por favor, ingresá un número válido (> 0).
    return
}
loopCount := LoopInputNumber
currentIteration := 0
running := true
Gui, Destroy
SetTimer, RunMacro, 0
return

RunMacro:
if (!running || currentIteration >= loopCount) {
    running := false
    SetTimer, RunMacro, Off
    return
}
currentIteration++

; ==== Acciones del macro ====
Send, {Blind}{Ctrl Down}{Shift Down}2{Shift Up}{Ctrl Up}
Sleep, 350

MouseClick, left, 262, 198
Sleep, 500

MouseClick, left, 544, 300
Sleep, 122

Sleep, 100

Send, {Blind}{Shift Down}{Ctrl Down}{Tab}{Ctrl Up}{Shift Up}
; ============================

Sleep, 9000  ; Delay entre iteraciones
return
