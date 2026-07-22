#Requires AutoHotkey v2.0

; ==============================
; Sleep Timer → send Play/Pause after X min Y sec (AHK v2)
; ==============================
#SingleInstance Force
;#Persistent

global gTimerActive := false

; ---- Quick presets ----
^!1::StartSleepTimer(10*60*1000)   ; 10 min
^!2::StartSleepTimer(20*60*1000)   ; 20 min
^!3::StartSleepTimer(30*60*1000)   ; 30 min

; ---- Interactive set ----
^!t:: {
    m := InputBox("Minutes:", "Sleep Timer", "w200 h120")
    if (m.Result != "OK") {
        Notify("Canceled.")
        return
    }
    s := InputBox("Seconds:", "Sleep Timer", "w200 h120")
    if (s.Result != "OK") {
        Notify("Canceled.")
        return
    }
    minutes := Number(m.Value), seconds := Number(s.Value)
    totalMs := (minutes*60 + seconds) * 1000
    if (totalMs <= 0) {
        Notify("Time must be > 0.")
        return
    }
    StartSleepTimer(totalMs)
}

; ---- Cancel ----
^!c::CancelSleepTimer()

; ---- Auto-execute: allow command-line usage ----
if (A_Args.Length >= 1) {
    minutes := Number(A_Args[1])
    seconds := (A_Args.Length >= 2) ? Number(A_Args[2]) : 0
    totalMs := (minutes*60 + seconds) * 1000
    if (totalMs > 0)
        StartSleepTimer(totalMs)
}

StartSleepTimer(totalMs) {
    ; CancelSleepTimer()
    gTimerActive := true
    mins := Floor(totalMs/60000), secs := Floor(Mod(totalMs,60000)/1000)
    Notify(Format("Sleep timer set: {1}m {2}s", mins, secs))
    SetTimer(FirePlayPause, -totalMs) ; one-shot
}

CancelSleepTimer() {
    if (gTimerActive) {
        SetTimer(FirePlayPause, 0)
        gTimerActive := false
        Notify("Sleep timer canceled.")
    }
}

FirePlayPause() {
    gTimerActive := false
    Send("{Media_Play_Pause}")
    Notify("Sent Play/Pause.")
}

Notify(msg) {
    TrayTip("Sleep Timer", msg, 1)
}
