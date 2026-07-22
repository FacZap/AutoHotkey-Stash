#Requires AutoHotkey v2.0
#SingleInstance Force

; =============================================================
; idle_edit_v2 — AHK v2 port (prepared for unification)
; Hides everything to the desktop (Win+D) after a period of
; physical inactivity, then restores on the next input.
;
; Threshold set via Win + Numpad *
;   0 = disabled (default on startup)
; =============================================================

; -----------------------------
; Configurable idle threshold
; 0 = disabled (default on startup)
; -----------------------------
global idleMinutes := 0                          ; default: disabled (0 min)
global idleThresholdMs := idleMinutes * 60 * 1000

; -----------------------------
; Hotkey: Win + Numpad *
; Opens input box to set minutes
; -----------------------------
#NumpadMult:: {
    global idleMinutes, idleThresholdMs

    ib := InputBox("Enter minutes of inactivity before hiding to desktop (0 = disabled):"
                 , "Idle time threshold", "w320 h150", idleMinutes)
    if (ib.Result != "OK")   ; user pressed Cancel or closed box
        return

    newMins := Trim(ib.Value)

    ; basic validation: must be a non-negative number (0 = disabled)
    if (newMins = "" || !RegExMatch(newMins, "^\d+(\.\d+)?$")) {
        ShowTip("Invalid value. Keeping " idleMinutes " min.")
        return
    }

    idleMinutes := newMins + 0
    idleThresholdMs := idleMinutes * 60 * 1000

    if (idleMinutes <= 0) {
        SetTimer(Check, 0)
        SetTimer(Check2, 0)
        ShowTip("Idle hide disabled (0 min).")
    } else {
        SetTimer(Check2, 0)
        SetTimer(Check, 1000)
        ShowTip("Idle threshold set to " idleMinutes " min.")
    }
}

ShowTip(text) {
    ToolTip(text)
    SetTimer(ClearTip, -1200)
}

ClearTip() {
    ToolTip()
}

; Start monitoring only if enabled on launch
if (idleMinutes > 0)
    SetTimer(Check, 1000)   ; check every second

Check() {
    global idleThresholdMs
    if (A_TimeIdlePhysical >= idleThresholdMs) {
        Send("#d")
        ToolTip("Escritorio")
        SetTimer(Check, 0)
        Sleep(500)
        SetTimer(Check2, 500)
    }
}

Check2() {
    if (A_TimeIdlePhysical < 500) {
        Send("#d")
        ToolTip()
        SetTimer(Check2, 0)
        SetTimer(Check, 1000)
    }
}
