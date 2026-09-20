;==============================================================================
; restore-at-fixed-time.ahk       AutoHotkey v1.1  (tested on 1.1.37.02)
;
; Auxiliary companion to traymond-timer.ahk. It does exactly one thing: at
; 16:40 every day, it asks Traymond to restore every window it is hiding.
;
; Nothing else. No hotkeys - so it can never collide with traymond-timer.ahk,
; with ^^AHK_Unified_Master.ahk, or with Traymond's own Win+Shift+Z - and no
; per-window bookkeeping. Run it next to traymond-timer.ahk (in PerWindow mode,
; say) to get a guaranteed daily sweep on top of the individual countdowns, or
; run it on its own as the whole timer.
;
; Same plumbing as the main script: hidden windows cannot be re-shown from
; outside without orphaning Traymond's tray icon, so we post Traymond its own
; "Restore all windows" menu command (WM_COMMAND 0x0111 / 0x98) and let it do
; the work - tray icon removed, crash-recovery file rewritten, exactly as if
; you had picked the item yourself. Traymond's window is message-only, so it
; only turns up via FindWindowEx(HWND_MESSAGE, ...); WinExist() never sees it.
; See traymond-timer.ahk / README.md for the longer version.
;==============================================================================

#NoEnv
#Persistent
#SingleInstance Force            ; relaunching just replaces the old instance
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%

;=============================== CONFIG =======================================

RestoreAt := "16:40"             ; the hardcoded sweep time, 24h HH:mm

ShowNotifications := true        ; tray balloon when the sweep fires
CheckIntervalMs   := 20000       ; how often to look at the clock

;==============================================================================

; Empty = today's sweep is still ahead of us. Set to YYYYMMDD once fired, so it
; can only happen once a day.
FiredOn := ""

; Starting the script after 16:40 must not trigger a sweep on the spot - that
; time belonged to a day this instance was not around for. Tomorrow onwards is
; ours.
if (A_Now >= TargetStamp())
    FiredOn := A_YYYY . A_MM . A_DD

Menu, Tray, Tip, Traymond restore-all daily at %RestoreAt%

SetTimer, CheckTime, %CheckIntervalMs%

if (FiredOn != "")
    startupNote := RestoreAt . " already went by today - next sweep is tomorrow"
else
    startupNote := "Armed - hidden windows come back at " . RestoreAt
if (!TraymondHwnd())
    startupNote .= "`n(Traymond is not running yet)"
Notify(startupNote)
return


;=============================== TIMER ========================================

CheckTime:
    today := A_YYYY . A_MM . A_DD
    if (FiredOn = today)                  ; already swept today
        return
    if (A_Now < TargetStamp())            ; not time yet
        return
    FiredOn := today
    RestoreAll()
return


;=============================== HELPERS ======================================

; Today's sweep moment as a YYYYMMDDHH24MISS timestamp. Comparing timestamps -
; rather than matching HH:mm exactly - means a PC asleep or busy at 16:40 still
; gets its sweep on the next check instead of missing the day entirely.
TargetStamp() {
    global RestoreAt
    hhmm := StrSplit(RestoreAt, ":")
    ; {:02d} so a single-digit hour ("9:05") still stamps as 0905.
    return A_YYYY . A_MM . A_DD . Format("{:02d}{:02d}00", hhmm[1], hhmm[2])
}

; Message-only window: FindWindowEx with HWND_MESSAGE (-3) as the parent is the
; only way to reach it. Looked up fresh each time, so restarting Traymond -
; which changes the handle - does not break us.
TraymondHwnd() {
    return DllCall("FindWindowExA", "Ptr", -3, "Ptr", 0, "AStr", "Traymond", "Ptr", 0, "Ptr")
}

RestoreAll() {
    global RestoreAt
    tr := TraymondHwnd()
    if (!tr) {
        Notify(RestoreAt . " - Traymond is not running, nothing to restore")
        return false
    }
    ; WM_COMMAND with the id of Traymond's "Restore all windows" menu item.
    if (!DllCall("PostMessage", "Ptr", tr, "UInt", 0x0111, "Ptr", 0x98, "Ptr", 0)) {
        Notify(RestoreAt . " - could not reach Traymond (PostMessage failed)")
        return false
    }
    Notify(RestoreAt . " - restored every window Traymond was hiding")
    return true
}

Notify(text) {
    global ShowNotifications
    if (ShowNotifications)
        TrayTip, Traymond daily restore, %text%,, 17     ; info icon, silent
}
