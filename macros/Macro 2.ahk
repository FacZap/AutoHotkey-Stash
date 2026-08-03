#Requires AutoHotkey v2.0
#SingleInstance Off
;=== Macro Recorder ===
;Name=Macro 2
;Slot=2
;Recorded=2026-08-03 09:04:35
;MouseMode=screen
;RecordSleep=true
;
;SPEED   playback rate: 2.0 = twice as fast, 0.5 = half speed
;REPEAT  how many times the macro runs
SPEED := 5.00
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

;tt := "Untitled - Notepad ahk_class Notepad"
;WinWait(tt)
;if (!WinActive(tt))
;  WinActivate(tt)

Sleep(Round(1875 / SPEED))

Send "{Blind}a"

;tt := "*Untitled - Notepad ahk_class Notepad"
;WinWait(tt)
;if (!WinActive(tt))
;  WinActivate(tt)

Send "{Blind}aaaaa"

Sleep(Round(204 / SPEED))

Send "{Blind}aaaa"

}
; release any modifier this macro left held down
for __k in ["LWin", "RWin", "Ctrl", "Alt", "Shift"]
    if GetKeyState(__k)
        Send("{" __k " Up}")
ExitApp()

^!Esc::ExitApp()
