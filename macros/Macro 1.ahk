#Requires AutoHotkey v2.0
#SingleInstance Off
;=== Macro Recorder ===
;Name=Macro 1
;Slot=1
;Recorded=2026-08-12 15:41:29
;MouseMode=screen
;RecordSleep=true
;
;SPEED   playback rate: 2.0 = twice as fast, 0.5 = half speed
;REPEAT  how many times the macro runs
SPEED := 1.00
REPEAT := 1
if (SPEED <= 0)
    SPEED := 1.0

SetKeyDelay(30)
SendMode("Event")
SetTitleMatchMode(2)
CoordMode("Mouse", "Screen")
;CoordMode("Mouse", "Window")

; wait for the launch hotkey's modifiers to be released
__deadline := A_TickCount + 3000
while (A_TickCount < __deadline && (GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
    || GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P") || GetKeyState("Shift", "P")))
    Sleep(20)

Loop(REPEAT)
{

tt := "*Untitled - Notepad ahk_class Notepad"
WinWait(tt)
if (!WinActive(tt))
  WinActivate(tt)


Sleep(Round(20 / SPEED))
Send "{Blind}{Backspace}"


Sleep(Round(20 / SPEED))
Send "{Blind}{Home}"


Sleep(Round(20 / SPEED))
Send "{Blind}{Up}"

}
; release any modifier this macro left held down
for __k in ["LWin", "RWin", "Ctrl", "Alt", "Shift"]
    if GetKeyState(__k)
        Send("{" __k " Up}")
ExitApp()

^!Esc::ExitApp()
