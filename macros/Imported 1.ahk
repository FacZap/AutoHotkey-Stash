#Requires AutoHotkey v2.0
#SingleInstance Off
SPEED := 1.00
REPEAT := 1
if (SPEED <= 0)
    SPEED := 1.0

;Press F1 to play. Hold to record. Long hold to edit
;#####SETTINGS#####
;What is the preferred method of recording mouse coordinates (screen,window,relative)
;MouseMode=screen
;Record sleep between input actions (true,false)
;RecordSleep=false
; wait for the launch hotkey's modifiers to be released
__deadline := A_TickCount + 3000
while (A_TickCount < __deadline && (GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
    || GetKeyState("Ctrl", "P") || GetKeyState("Alt", "P") || GetKeyState("Shift", "P")))
    Sleep(20)

Loop(REPEAT)
{


SetKeyDelay(30)
SendMode("Event")
SetTitleMatchMode(2)
CoordMode("Mouse", "Screen")
;CoordMode("Mouse", "Window")

;tt := "C:\Users\fzapata\Downloads\2026-07-30 16_53_08-Win ahk_class WindowsForms10.Window.8.app.0.7797c1_r8_ad1"
;WinWait(tt)
;if (!WinActive(tt))
;  WinActivate(tt)

;Sleep(Round(570 / SPEED))

Send "{Blind}{Alt Down}{F4}{Alt Up}"

;tt := "Win10-VPNBUNGE - VMware Workstation ahk_class VMUIFrame"
;WinWait(tt)
;if (!WinActive(tt))
;  WinActivate(tt)

;Sleep(Round(250 / SPEED))

Send "{Blind}{LWin Down}1{LWin Up}"

;tt := "Greenshot image editor ahk_class WindowsForms10.Window.8.app.0.7797c1_r8_ad1"
;WinWait(tt)
;if (!WinActive(tt))
;  WinActivate(tt)

;Sleep(Round(414 / SPEED))

Send "{Blind}{Ctrl Down}s{Ctrl Up}"

;tt := "C:\Users\fzapata\Downloads\2026-07-30 16_53_15-Win ahk_class WindowsForms10.Window.8.app.0.7797c1_r8_ad1"
;WinWait(tt)
;if (!WinActive(tt))
;  WinActivate(tt)


}
; release any modifier this macro left held down
for __k in ["LWin", "RWin", "Ctrl", "Alt", "Shift"]
    if GetKeyState(__k)
        Send("{" __k " Up}")
ExitApp()

^!Esc::ExitApp()
