#Requires AutoHotkey v2.0
#SingleInstance Force

global MinMinutes  := 5
global MaxMinutes  := 15
global StopMinutes := 60

global ReminderMs  := 1000      ; how long each reminder stays on screen

; Runtime state
global ctrlGui     := ""
global timerText   := ""
global nextText    := ""
global reminderGui := ""
global EndTime     := 0
global NextTime    := 0

; =========================
; Startup Configuration GUI
; =========================
cfgGui := Gui(, "Bloque CT Configuration")
cfgGui.SetFont("s10", "Segoe UI")

cfgGui.AddText(, "Minimum interval (minutes):")
minEdit := cfgGui.AddEdit("w100 Number", MinMinutes)

cfgGui.AddText("y+10", "Maximum interval (minutes):")
maxEdit := cfgGui.AddEdit("w100 Number", MaxMinutes)

cfgGui.AddText("y+10", "Auto-stop after (minutes):")
stopEdit := cfgGui.AddEdit("w100 Number", StopMinutes)

startBtn := cfgGui.AddButton("w120 h30 y+15", "Start")
startBtn.OnEvent("Click", StartScript)

cfgGui.OnEvent("Close", (*) => ExitApp())
cfgGui.Show()

return

StartScript(*)
{
    global MinMinutes, MaxMinutes, StopMinutes
    global cfgGui, minEdit, maxEdit, stopEdit
    global timerText, nextText, ctrlGui, EndTime

    if !(IsInteger(minEdit.Value) && IsInteger(maxEdit.Value) && IsInteger(stopEdit.Value))
    {
        MsgBox("Enter a whole number of minutes in all three fields.", "Bloque CT", "Icon!")
        return
    }

    MinMinutes  := Integer(minEdit.Value)
    MaxMinutes  := Integer(maxEdit.Value)
    StopMinutes := Integer(stopEdit.Value)

    if (MinMinutes < 1)
        MinMinutes := 1

    if (MaxMinutes < MinMinutes)
        MaxMinutes := MinMinutes

    if (StopMinutes < 1)
        StopMinutes := 1

    cfgGui.Destroy()

    ; Auto-stop deadline
    EndTime := A_TickCount + (StopMinutes * 60 * 1000)

    ; =========================
    ; Control GUI
    ; =========================
    ctrlGui := Gui("+AlwaysOnTop", "Bloque CT Running")
    ctrlGui.SetFont("s10", "Segoe UI")

    timerText := ctrlGui.AddText("w260", "")
    nextText  := ctrlGui.AddText("w260", "")

    stopBtn := ctrlGui.AddButton("w260 h30", "Stop Script")
    stopBtn.OnEvent("Click", (*) => ExitApp())

    ctrlGui.SetFont("s8 Italic", "Segoe UI")
    ctrlGui.AddText("w260 cGray", "Closing this window keeps the reminders`nrunning. Reopen it from the tray icon.")

    ; The X only hides the window; "Stop Script" (or the tray Exit) is what quits
    ctrlGui.OnEvent("Close", HideControlGui)
    ctrlGui.Show("x10 y10")

    ; Tray icon is the way back to a hidden window; double-click does the same
    A_TrayMenu.Insert("1&", "Show timer window", ShowControlGui)
    A_TrayMenu.Insert("2&")
    A_TrayMenu.Default := "Show timer window"

    ; Show one reminder right away, as confirmation that the script is running
    ShowReminder()

    ScheduleNextReminder()

    SetTimer(UpdateTimer, 1000)
    UpdateTimer()
}

; Hiding rather than destroying keeps the countdown timer and the reminder
; schedule alive, and keeps timerText/nextText valid for UpdateTimer.
HideControlGui(*)
{
    global ctrlGui

    ctrlGui.Hide()
    return true     ; cancel the default close action (which would destroy it)
}

ShowControlGui(*)
{
    global ctrlGui

    if IsObject(ctrlGui)
        ctrlGui.Show()
}

; Picks a random wait and arms a one-shot timer for it. Nothing blocks, so the
; Stop button and the countdown stay responsive while waiting.
ScheduleNextReminder()
{
    global MinMinutes, MaxMinutes, NextTime

    waitMs := Random(
        MinMinutes * 60 * 1000,
        MaxMinutes * 60 * 1000
    )

    NextTime := A_TickCount + waitMs
    SetTimer(ReminderTick, -waitMs)
}

ReminderTick()
{
    global EndTime

    if (A_TickCount >= EndTime)
    {
        ExitApp()
        return
    }

    ShowReminder()
    ScheduleNextReminder()
}

UpdateTimer()
{
    global EndTime, NextTime, timerText, nextText

    if (A_TickCount >= EndTime)
    {
        ExitApp()
        return
    }

    timerText.Value := "Auto-stop in:      " FormatRemaining(EndTime)
    nextText.Value  := "Next reminder in:  " FormatRemaining(NextTime)
}

FormatRemaining(targetTick)
{
    remaining := targetTick - A_TickCount

    if (remaining < 0)
        remaining := 0

    totalSec := remaining // 1000
    hours    := totalSec // 3600
    mins     := Mod(totalSec // 60, 60)
    secs     := Mod(totalSec, 60)

    if (hours > 0)
        return Format("{:d}:{:02}:{:02}", hours, mins, secs)

    return Format("{:02}:{:02}", mins, secs)
}

ShowReminder()
{
    global reminderGui, ReminderMs

    ; Never leave a previous popup stacked underneath this one
    CloseReminder()

    reminderGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
    reminderGui.BackColor := "FFFF99"

    reminderGui.SetFont("s24 Bold", "Segoe UI")
    reminderGui.AddText("Center w500 h80", "Bloque CT activado")

    ; NoActivate so the popup does not steal keyboard focus mid-typing
    reminderGui.Show("AutoSize Center NoActivate")

    ; Semi-transparent
    WinSetTransparent(220, reminderGui.Hwnd)

    SetTimer(CloseReminder, -ReminderMs)
}

CloseReminder()
{
    global reminderGui

    if IsObject(reminderGui)
    {
        try reminderGui.Destroy()
        reminderGui := ""
    }
}
