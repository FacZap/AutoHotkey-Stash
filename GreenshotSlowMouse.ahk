#Requires AutoHotkey v2.0
#SingleInstance Force

; ==========================================================
;  Greenshot helper
;
;  Drops pointer speed (and mouse acceleration) while
;  Greenshot's region-capture overlay is on screen, so the
;  selection edges can be placed precisely. Everything is
;  restored the moment the overlay closes.
;
;  It watches for Greenshot's "capture form" window rather
;  than binding a hotkey, so it works no matter how the
;  capture was started -- region hotkey, tray icon, context
;  menu -- and never has to be kept in sync with Greenshot's
;  configured hotkeys.
;
;  Every capture starts at slow factor 0 (normal speed). While
;  the overlay is up, the mouse wheel changes it: wheel down
;  slows the pointer, wheel up speeds it back up.
; ==========================================================

FACTOR_STEP  := 10       ; % of normal speed removed per wheel notch
FACTOR_MAX   := 90       ; never go slower than 10% of normal speed
KILL_ACCEL   := true     ; also switch off "Enhance pointer precision" while factor > 0
POLL_MS      := 75       ; how often to look for the overlay
MAX_SLOW_MS  := 120000   ; safety net: never stay slowed longer than this

CAPTURE_WIN := "Greenshot capture form ahk_exe Greenshot.exe"

SPI_GETMOUSE      := 0x0003   ; threshold1, threshold2, acceleration
SPI_SETMOUSE      := 0x0004
SPI_GETMOUSESPEED := 0x0070
SPI_SETMOUSESPEED := 0x0071

slowActive := false      ; true while the overlay is up (even at factor 0)
slowFactor := 0          ; % of normal speed removed; reset to 0 on every capture
origSpeed  := 0
origAccel  := 0          ; Buffer holding the original SPI_GETMOUSE triplet
slowStart  := 0

SetTimer WatchCapture, POLL_MS

WatchCapture() {
    global slowActive, slowStart, CAPTURE_WIN, MAX_SLOW_MS

    DetectHiddenWindows false
    if WinExist(CAPTURE_WIN) {
        if !slowActive
            SlowDown()
        else if (A_TickCount - slowStart > MAX_SLOW_MS)
            Restore()                       ; overlay stuck / never closed
    } else if slowActive {
        Restore()
    }
}

SlowDown() {
    global slowActive, slowStart, slowFactor, origSpeed, origAccel
    global KILL_ACCEL, SPI_GETMOUSE

    origSpeed := GetMouseSpeed()
    if KILL_ACCEL {
        origAccel := Buffer(12, 0)
        DllCall("SystemParametersInfo", "UInt", SPI_GETMOUSE, "UInt", 0, "Ptr", origAccel, "UInt", 0)
    }

    slowFactor := 0                         ; factor 0 = nothing changed yet
    slowActive := true
    slowStart := A_TickCount
}

; Applies slowFactor on top of the speed/acceleration saved in SlowDown()
ApplyFactor() {
    global slowFactor, origSpeed, origAccel, KILL_ACCEL, SPI_SETMOUSE

    newSpeed := Round(origSpeed * (100 - slowFactor) / 100)
    if (newSpeed < 1)
        newSpeed := 1
    SetMouseSpeed(newSpeed)

    if KILL_ACCEL {
        if (slowFactor > 0) {
            flat := Buffer(12, 0)           ; all three zero = 1:1 pointer movement
            DllCall("SystemParametersInfo", "UInt", SPI_SETMOUSE, "UInt", 0, "Ptr", flat, "UInt", 0)
        } else if origAccel {
            DllCall("SystemParametersInfo", "UInt", SPI_SETMOUSE, "UInt", 0, "Ptr", origAccel, "UInt", 0)
        }
    }

    ToolTip "Slow factor: " slowFactor "%  (speed " newSpeed "/20)"
    SetTimer HideTip, -1000                 ; named func so each notch restarts the same timer
}

HideTip() => ToolTip()

ChangeFactor(delta) {
    global slowFactor, slowStart, FACTOR_MAX

    newFactor := Max(0, Min(FACTOR_MAX, slowFactor + delta))
    slowStart := A_TickCount                ; user is still working: push the safety net back
    if (newFactor = slowFactor)
        return
    slowFactor := newFactor
    ApplyFactor()
}

Restore() {
    global slowActive, slowFactor, origSpeed, origAccel, KILL_ACCEL, SPI_SETMOUSE

    if !slowActive
        return
    SetMouseSpeed(origSpeed)
    if (KILL_ACCEL && origAccel)
        DllCall("SystemParametersInfo", "UInt", SPI_SETMOUSE, "UInt", 0, "Ptr", origAccel, "UInt", 0)
    slowFactor := 0
    slowActive := false
    ToolTip
}

; The wheel only belongs to this script while the overlay is up
#HotIf slowActive
WheelDown::ChangeFactor(FACTOR_STEP)
WheelUp::ChangeFactor(-FACTOR_STEP)
#HotIf

GetMouseSpeed() {
    global SPI_GETMOUSESPEED
    spd := 0
    DllCall("SystemParametersInfo", "UInt", SPI_GETMOUSESPEED, "UInt", 0, "UInt*", &spd, "UInt", 0)
    return spd ? spd : 10                   ; 10 = Windows default slider position
}

SetMouseSpeed(spd) {
    global SPI_SETMOUSESPEED
    DllCall("SystemParametersInfo", "UInt", SPI_SETMOUSESPEED, "UInt", 0, "Ptr", spd, "UInt", 0)
}

; Safety net: never leave the pointer slowed down if the script exits mid-capture
OnExit (*) => Restore()
