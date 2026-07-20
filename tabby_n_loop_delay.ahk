#Persistent
SetKeyDelay, 30
SendMode, Event
SetTitleMatchMode, 2
CoordMode, Mouse, Screen

global running := false
global loopCount := 0
global currentIteration := 0
global cycleDelay := 9000

Tab & CapsLock::
if (running) {
    running := false
    MsgBox, Loop detenido.
    return
}
Gui, +AlwaysOnTop
Gui, Add, Text,, Ingresá cuántas veces ejecutar el macro:
Gui, Add, Edit, vLoopInputNumber w100 Number

Gui, Add, Text,, Delay entre ciclos (ms):
Gui, Add, Edit, vDelayInputNumber w100 Number, %cycleDelay%

Gui, Add, Button, default gStartLoop, OK
Gui, Add, Button, gCancelLoop, Cancelar
Gui, Show,, Ejecutar Macro
return

StartLoop:
Gui, Submit
if (LoopInputNumber < 1 || DelayInputNumber < 0) {
    MsgBox, Por favor, ingresá valores válidos (>0 para repeticiones, >=0 para delay).
    return
}
loopCount := LoopInputNumber
cycleDelay := DelayInputNumber
currentIteration := 0
running := true
Gui, Destroy
SetTimer, RunMacro, 0
return

CancelLoop:
Gui, Destroy
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

MouseClick, left, 544, 300+50
Sleep, 122

Sleep, 100

Send, {Blind}{Shift Down}{Ctrl Down}{Tab}{Ctrl Up}{Shift Up}
; ============================

Sleep, %cycleDelay%
return
