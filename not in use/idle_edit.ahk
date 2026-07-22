#NoEnv
#SingleInstance Force
#Persistent

; -----------------------------
; Configurable idle threshold
; 0 = disabled (default on startup)
; -----------------------------
idleMinutes := 0                 ; default: disabled (0 min)
idleThresholdMs := idleMinutes * 60 * 1000

Goto, Work


; -----------------------------
; Hotkey: Win + Numpad *
; Opens input box to set minutes
; -----------------------------
#NumpadMult::
    InputBox, newMins, Idle time threshold, Enter minutes of inactivity before hiding to desktop:, , 320, 150, , , , , %idleMinutes%
    if (ErrorLevel)  ; user pressed Cancel or closed box
        return

    newMins := Trim(newMins)

    ; basic validation: must be a non-negative number (0 = disabled)
    if (newMins = "" || !RegExMatch(newMins, "^\d+(\.\d+)?$")) {
        ToolTip, Invalid value. Keeping %idleMinutes% min.
        SetTimer, ClearTip, -1200
        return
    }

    idleMinutes := newMins
    idleThresholdMs := idleMinutes * 60 * 1000

    if (idleMinutes <= 0) {
        SetTimer, Check, off
        SetTimer, Check2, off
        ToolTip
        ToolTip, Idle hide disabled (0 min).
    } else {
        SetTimer, Check2, off
        SetTimer, Check, on
        ToolTip, Idle threshold set to %idleMinutes% min.
    }
    SetTimer, ClearTip, -1200
return

ClearTip:
ToolTip
return


Work:
if (idleMinutes > 0)
    SetTimer, Check, 1000 ; check every second
return


Check:
if (A_TimeIdlePhysical >= idleThresholdMs)
{
    Send, #d
    ToolTip, Escritorio
    SetTimer, Check, off
    Sleep, 500
    SetTimer, Check2, 500
}
return


Check2:
if (A_TimeIdlePhysical < 500)
{
    Send, #d
    ToolTip
    SetTimer, Check2, off
    SetTimer, Check, on
}
return
