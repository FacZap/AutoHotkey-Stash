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
; ==========================================================

SLOW_PERCENT := 70       ; % of the normal Windows pointer speed
KILL_ACCEL   := true     ; also switch off "Enhance pointer precision"
POLL_MS      := 75       ; how often to look for the overlay
MAX_SLOW_MS  := 120000   ; safety net: never stay slowed longer than this

CAPTURE_WIN := "Greenshot capture form ahk_exe Greenshot.exe"

SPI_GETMOUSE      := 0x0003   ; threshold1, threshold2, acceleration
SPI_SETMOUSE      := 0x0004
SPI_GETMOUSESPEED := 0x0070
SPI_SETMOUSESPEED := 0x0071

slowActive := false
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
    global slowActive, slowStart, origSpeed, origAccel
    global SLOW_PERCENT, KILL_ACCEL, SPI_GETMOUSE, SPI_SETMOUSE

    origSpeed := GetMouseSpeed()
    newSpeed := Round(origSpeed * SLOW_PERCENT / 100)
    if (newSpeed < 1)
        newSpeed := 1
    SetMouseSpeed(newSpeed)

    if KILL_ACCEL {
        origAccel := Buffer(12, 0)
        DllCall("SystemParametersInfo", "UInt", SPI_GETMOUSE, "UInt", 0, "Ptr", origAccel, "UInt", 0)
        flat := Buffer(12, 0)               ; all three zero = 1:1 pointer movement
        DllCall("SystemParametersInfo", "UInt", SPI_SETMOUSE, "UInt", 0, "Ptr", flat, "UInt", 0)
    }

    slowActive := true
    slowStart := A_TickCount
}

Restore() {
    global slowActive, origSpeed, origAccel, KILL_ACCEL, SPI_SETMOUSE

    if !slowActive
        return
    SetMouseSpeed(origSpeed)
    if (KILL_ACCEL && origAccel)
        DllCall("SystemParametersInfo", "UInt", SPI_SETMOUSE, "UInt", 0, "Ptr", origAccel, "UInt", 0)
    slowActive := false
}

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
