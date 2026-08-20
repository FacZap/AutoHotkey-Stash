;==============================================================================
; traymond-timer.ahk        AutoHotkey v1.1  (tested on 1.1.37.02)
;
; Brings windows hidden by Traymond back on a timer.
;
; Traymond (https://github.com/fcFn/traymond) hides windows with ShowWindow(HIDE)
; and tracks them in its own process, so a hidden window cannot simply be
; re-shown from outside without leaving an orphaned tray icon behind. Instead
; this script asks Traymond to do the restoring, using the exact messages its
; window procedure already handles:
;
;   hide foreground window : WM_HOTKEY 0x0312            -> minimizeToTray()
;   restore ONE window     : WM_ICON   0x1C0A            -> showWindow()
;   restore ALL windows    : WM_COMMAND 0x0111 / 0x98    -> showAllWindows()
;
; Traymond therefore does its own bookkeeping: the tray icon is removed and its
; crash-recovery file is rewritten, exactly as if you had clicked the icon.
;
; RESIDENT USE   : just run the script. See CONFIG below.
; ONE-SHOT USE   : AutoHotkey.exe traymond-timer.ahk /restore-all
;                  AutoHotkey.exe traymond-timer.ahk /hide [hwnd]
;                  AutoHotkey.exe traymond-timer.ahk /restore <hwnd>
;                  (handy for Task Scheduler / a .bat file - see restore-all.bat)
;==============================================================================

#NoEnv
#Persistent
; NOTE: deliberately Off, not Force - a one-shot /restore-all call must not kill
; a resident copy. Resident mode enforces single-instance with a mutex instead.
#SingleInstance Off
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%
DetectHiddenWindows, On

;=============================== CONFIG =======================================

; "PerWindow" - each window gets its own countdown, chosen when you hide it.
; "Interval"  - restore ALL hidden windows every IntervalMinutes.
; "DailyTime" - restore ALL hidden windows once a day at DailyTime.
;
; Windows hidden with HotkeyPlainHide never get an individual countdown in any
; mode - but Interval / DailyTime still sweep them up along with everything else.
Mode := "PerWindow"

RestoreAfterMinutes := 25        ; what the prompt starts pre-filled with
IntervalMinutes     := 60        ; Interval mode
DailyTime           := "17:30"   ; DailyTime mode, 24h HH:mm

ShowNotifications := true        ; tray balloon on hide/restore

; Hotkeys ( # Win   + Shift   ^ Ctrl   ! Alt ).  Set to "" to disable one.
;
; HotkeyPromptHide intentionally shadows Traymond's own Win+Shift+Z: this script
; sees the keypress first, notes which window is about to disappear, then
; forwards the hide to Traymond. Hiding keeps working as before - the only
; difference is that we now know what was hidden and when, which is what makes
; a countdown possible. Change it if you would rather keep the two separate.
HotkeyPromptHide   := "#+z"      ; hide, then ask how long. Works in every mode.
HotkeyPlainHide    := "#!+z"     ; hide with no countdown and no prompt - i.e.
                                 ;   exactly what Traymond does on its own.
HotkeyDefaultHide  := ""         ; optional: hide and silently use
                                 ;   RestoreAfterMinutes without asking. Unbound
                                 ;   by default - set to e.g. "^#+z" to use it.
HotkeyRestoreAll   := "#+r"      ; restore everything right now
HotkeyCancelTimers := "#+c"      ; forget pending countdowns, leave windows hidden

;==============================================================================

Pending      := {}               ; hwnd -> tick count when it is due back
PendingTitle := {}               ; hwnd -> window title, for notifications
LastIntervalTick := A_TickCount
DailyFiredOn := ""
PromptHwnd   := 0                ; window the custom-time prompt is asking about
PromptTitle  := ""

; ---- one-shot command line mode -------------------------------------------
if (A_Args.Length() > 0) {
    exitCode := RunCli(A_Args)
    ExitApp, %exitCode%
}

if (!TraymondHwnd()) {
    MsgBox, 48, Traymond Timer, Traymond does not appear to be running.`n`nStart Traymond.exe first`, then run this script again.
    ExitApp
}

; ---- resident mode ---------------------------------------------------------
Mutex := DllCall("CreateMutex", "Ptr", 0, "Int", 1, "Str", "traymond_timer_resident", "Ptr")
if (A_LastError = 183) {         ; ERROR_ALREADY_EXISTS
    MsgBox, 48, Traymond Timer, Traymond Timer is already running - look for its tray icon.
    ExitApp
}

if (HotkeyPromptHide != "")
    Hotkey, $%HotkeyPromptHide%, DoCustomTimeHide   ; $ forces the keyboard hook
if (HotkeyPlainHide != "")                          ;   so we win over Traymond's
    Hotkey, $%HotkeyPlainHide%, DoPlainHide         ;   own RegisterHotKey
if (HotkeyDefaultHide != "")
    Hotkey, $%HotkeyDefaultHide%, DoTimedHide
if (HotkeyRestoreAll != "")
    Hotkey, %HotkeyRestoreAll%, DoRestoreAllNow
if (HotkeyCancelTimers != "")
    Hotkey, %HotkeyCancelTimers%, DoCancelTimers

Menu, Tray, NoStandard
Menu, Tray, Add, Restore all now, DoRestoreAllNow
Menu, Tray, Add, Pending countdowns..., ShowPending
Menu, Tray, Add, Cancel all countdowns, DoCancelTimers
Menu, Tray, Add
Menu, Tray, Add, Reload, DoReload
Menu, Tray, Add, Exit, DoExit
Menu, Tray, Default, Restore all now
Menu, Tray, Tip, Traymond Timer (%Mode%)

SetTimer, TickCheck, 1000
Notify("Traymond Timer running - mode: " . Mode)
return


;=============================== TRAYMOND PLUMBING ============================

; Traymond's window is message-only (created with HWND_MESSAGE as parent), so
; EnumWindows - and therefore AHK's WinExist() - cannot see it. FindWindowEx
; with HWND_MESSAGE (-3) as the parent is the only way to get the handle.
; Looked up fresh every time so restarting Traymond does not break us.
TraymondHwnd() {
    return DllCall("FindWindowExA", "Ptr", -3, "Ptr", 0, "AStr", "Traymond", "Ptr", 0, "Ptr")
}

; Traymond hides whatever is in the foreground, so an explicit target has to be
; activated first. Returns the hwnd that was hidden, or 0 on failure.
TraymondHide(target := 0) {
    tr := TraymondHwnd()
    if (!tr)
        return 0
    if (target) {
        WinActivate, ahk_id %target%
        WinWaitActive, ahk_id %target%,, 2
        if (ErrorLevel)
            return 0
    }
    hwnd := DllCall("GetForegroundWindow", "Ptr")
    if (!hwnd)
        return 0
    DllCall("PostMessage", "Ptr", tr, "UInt", 0x0312, "Ptr", 0, "Ptr", 0)   ; WM_HOTKEY
    return hwnd
}

; Traymond keys each tray icon by LOWORD(hwnd) and restores that window when the
; shell reports a double-click, passing lParam = MAKELPARAM(event, iconID).
; Posting that message ourselves is indistinguishable from a real double-click.
; (LOWORD means two windows could in principle collide - Traymond's own quirk,
; not ours; it would then restore whichever it stored first.)
TraymondRestoreOne(target) {
    tr := TraymondHwnd()
    if (!tr)
        return false
    lParam := ((target & 0xFFFF) << 16) | 0x0203     ; WM_LBUTTONDBLCLK
    return DllCall("PostMessage", "Ptr", tr, "UInt", 0x1C0A, "Ptr", 0, "Ptr", lParam)
}

; The "Restore all windows" tray menu command.
TraymondRestoreAll() {
    tr := TraymondHwnd()
    if (!tr)
        return false
    return DllCall("PostMessage", "Ptr", tr, "UInt", 0x0111, "Ptr", 0x98, "Ptr", 0)
}


;=============================== ONE-SHOT CLI =================================

RunCli(args) {
    cmd := args[1]
    if (!TraymondHwnd()) {
        Out("Traymond is not running - nothing to restore.")
        return 1
    }
    if (cmd = "/restore-all") {
        TraymondRestoreAll()
        Out("Restore-all sent to Traymond.")
    } else if (cmd = "/hide") {
        hwnd := TraymondHide(args.Length() >= 2 ? args[2] : 0)
        if (hwnd)
            Out("Hid window " . hwnd . ".")
        else {
            Out("Could not hide the requested window.")
            return 1
        }
    } else if (cmd = "/restore") {
        if (args.Length() < 2) {
            Out("/restore needs a window handle.")
            return 1
        }
        TraymondRestoreOne(args[2])
        Out("Restore sent for window " . args[2] . ".")
    } else {
        Out("Usage: traymond-timer.ahk [/restore-all | /hide [hwnd] | /restore <hwnd>]")
        return 1
    }
    Sleep, 150                   ; let the posted message be picked up
    return 0
}

Out(text) {
    FileAppend, %text%`n, *      ; stdout
}


;=============================== TIMER LOOP ===================================

TickCheck:
    now := A_TickCount
    ; Per-window countdowns. Used by PerWindow mode, and by any window given a
    ; custom time at the prompt - which is why this is not inside the mode test.
    due := []
    for hwnd, dueTick in Pending {
        if (now >= dueTick)
            due.Push(hwnd)
    }
    for index, hwnd in due {
        TraymondRestoreOne(hwnd)
        Notify("Restored: " . Shorten(PendingTitle[hwnd]))
        Pending.Delete(hwnd)
        PendingTitle.Delete(hwnd)
    }
    if (Mode = "Interval") {
        if (now - LastIntervalTick >= IntervalMinutes * 60000) {
            LastIntervalTick := now
            TraymondRestoreAll()
            Notify("Interval reached - restored all hidden windows")
        }
    } else if (Mode = "DailyTime") {
        FormatTime, nowHHmm,, HH:mm
        today := A_YYYY . A_MM . A_DD
        if (nowHHmm = DailyTime && DailyFiredOn != today) {
            DailyFiredOn := today
            TraymondRestoreAll()
            Notify("Daily restore - all hidden windows are back")
        }
    }
return


;=============================== ACTIONS ======================================

; Plain Traymond behaviour: hide it, and leave it hidden. No countdown, no
; prompt. Interval / DailyTime modes will still sweep it up on their schedule.
DoPlainHide:
    hidden := TraymondHide()
    if (!hidden) {
        Notify("Nothing to hide (or Traymond is not running)")
        return
    }
    WinGetTitle, hiddenTitle, ahk_id %hidden%
    Notify("Hidden: " . Shorten(hiddenTitle) . "`nNo countdown set")
return

; Optional (HotkeyDefaultHide): hide and start the default countdown without
; asking. Same as answering the prompt with whatever RestoreAfterMinutes is.
DoTimedHide:
    hidden := TraymondHide()
    if (!hidden) {
        Notify("Nothing to hide (or Traymond is not running)")
        return
    }
    WinGetTitle, hiddenTitle, ahk_id %hidden%
    Pending[hidden] := A_TickCount + (RestoreAfterMinutes * 60000)
    PendingTitle[hidden] := hiddenTitle
    Notify("Hidden: " . Shorten(hiddenTitle) . "`nBack in " . FormatMinutes(RestoreAfterMinutes))
return

; Hide the window first, then ask for the time. Doing it in this order means we
; never have to re-activate the target window afterwards: Traymond can only hide
; whatever is in the foreground, and once our own dialog has taken the
; foreground, handing it back is at the mercy of Windows' foreground-lock rules.
; Cancel un-hides the window again, so nothing is lost by asking second.
DoCustomTimeHide:
    if (PromptHwnd) {                ; already asking about something - just resurface
        Gui, TimePrompt:Show
        return
    }
    PromptHwnd := TraymondHide()
    if (!PromptHwnd) {
        Notify("Nothing to hide (or Traymond is not running)")
        return
    }
    WinGetTitle, PromptTitle, ahk_id %PromptHwnd%
    if (PromptTitle = "")
        PromptTitle := "(untitled window)"

    Gui, TimePrompt:New, +AlwaysOnTop +ToolWindow, Traymond Timer
    Gui, TimePrompt:Margin, 14, 12
    Gui, TimePrompt:Font, s9
    Gui, TimePrompt:Add, Text, xm w330, % "Hidden:  " . Shorten(PromptTitle, 42)
    Gui, TimePrompt:Add, Text, xm y+12, Bring it back in:
    Gui, TimePrompt:Add, Edit, xm y+4 w110 vPromptInput, %RestoreAfterMinutes%
    Gui, TimePrompt:Add, Text, x+8 yp+4 cGray, minutes
    Gui, TimePrompt:Add, Text, xm y+12 w330 cGray, % "Also accepts:   90m    2h    1h30    @17:45 (clock time)`n0 brings it back immediately."
    Gui, TimePrompt:Add, Button, xm y+14 w150 Default gTimePromptOK, Start countdown
    Gui, TimePrompt:Add, Button, x+10 w170 gTimePromptCancel, Cancel - un-hide now
    Gui, TimePrompt:Show
    GuiControl, TimePrompt:Focus, PromptInput
    GuiControlGet, hPromptEdit, TimePrompt:Hwnd, PromptInput
    SendMessage, 0xB1, 0, -1,, ahk_id %hPromptEdit%     ; EM_SETSEL - select all
return

TimePromptOK:
    Gui, TimePrompt:Submit, NoHide
    mins := ParseDelayMinutes(PromptInput)
    if (mins < 0) {
        Gui, TimePrompt:+OwnDialogs
        MsgBox, 48, Traymond Timer, Could not read "%PromptInput%".`n`nTry:  25    90m    2h    1h30    @17:45
        return
    }
    Gui, TimePrompt:Destroy
    if (mins = 0) {
        TraymondRestoreOne(PromptHwnd)
        Notify("Back already: " . Shorten(PromptTitle))
    } else {
        Pending[PromptHwnd] := A_TickCount + Round(mins * 60000)
        PendingTitle[PromptHwnd] := PromptTitle
        Notify("Hidden: " . Shorten(PromptTitle) . "`nBack in " . FormatMinutes(mins))
    }
    PromptHwnd := 0
return

TimePromptCancel:
TimePromptGuiClose:
TimePromptGuiEscape:
    Gui, TimePrompt:Destroy
    TraymondRestoreOne(PromptHwnd)
    Notify("Cancelled - " . Shorten(PromptTitle) . " is back")
    PromptHwnd := 0
return

DoRestoreAllNow:
    TraymondRestoreAll()
    Pending := {}
    PendingTitle := {}
    Notify("Restored all hidden windows")
return

DoCancelTimers:
    Pending := {}
    PendingTitle := {}
    Notify("Pending countdowns cancelled - windows stay hidden")
return

ShowPending:
    list := ""
    for hwnd, dueTick in Pending {
        left := (dueTick - A_TickCount) / 60000
        list .= Shorten(PendingTitle[hwnd], 50) . "   ->   " . FormatMinutes(left) . "`n"
    }
    if (list = "")
        list := "Nothing is waiting to be restored."
    MsgBox, 64, Traymond Timer - pending countdowns, %list%
return

DoReload:
    DllCall("CloseHandle", "Ptr", Mutex)
    Reload
return

DoExit:
    ExitApp

Notify(text) {
    global ShowNotifications
    if (ShowNotifications)
        TrayTip, Traymond Timer, %text%,, 17     ; info icon, silent
}

Shorten(text, limit := 40) {
    if (StrLen(text) > limit)
        return SubStr(text, 1, limit - 3) . "..."
    return text
}

; Reads what the user typed at the prompt and returns a number of minutes,
; or -1 if it makes no sense. Accepts:
;   25 / 25m   -> 25 minutes        1h30 / 1h30m -> 90 minutes
;   2h         -> 120 minutes       @17:45       -> at 17:45 (tomorrow if past)
;   0          -> immediately
ParseDelayMinutes(text) {
    text := Trim(text)
    if (text = "")
        return -1

    if (SubStr(text, 1, 1) = "@") {
        if (!RegExMatch(Trim(SubStr(text, 2)), "^(\d{1,2})[:.](\d{2})$", m))
            return -1
        if (m1 > 23 || m2 > 59)
            return -1
        target := A_YYYY . A_MM . A_DD . Format("{:02}{:02}00", m1, m2)
        seconds := target
        EnvSub, seconds, %A_Now%, Seconds
        if (seconds <= 0) {                  ; that time already went by today
            EnvAdd, target, 1, Days
            seconds := target
            EnvSub, seconds, %A_Now%, Seconds
        }
        return seconds / 60
    }

    if (RegExMatch(text, "i)^(\d+)\s*h\s*(\d{1,2})?\s*m?$", m))
        return (m1 * 60) + (m2 = "" ? 0 : m2)

    if (RegExMatch(text, "i)^(\d+(?:[.,]\d+)?)\s*m?$", m))
        return StrReplace(m1, ",", ".") + 0

    return -1
}

FormatMinutes(mins) {
    total := Round(mins)
    if (total <= 0)
        return "less than a minute"
    if (total < 60)
        return total . " min"
    hours := total // 60
    rest  := Mod(total, 60)
    return rest ? hours . " h " . rest . " min" : hours . " h"
}
