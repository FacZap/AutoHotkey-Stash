#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================================
; SimpleReminders.ahk  —  plain-text reminders with a quiet pop-up.
;
;   Win+Alt+Z   open the manager GUI (write / edit / duplicate / delete)
;
; A reminder is up to 100 characters of text plus a date and time. When the
; time arrives a small window appears on the center-right of the screen with
; snooze options. No sound, no alarm, no focus stealing.
;
; The database is reminders.csv, next to this script. It is rewritten in full
; every time a reminder is created, modified, snoozed, completed or deleted,
; so the file on disk always matches what the GUI shows.
;
; Columns: id,text,due,status,created
;   due / created : yyyy-MM-dd HH:mm:ss  (sorts chronologically as plain text)
;   status        : pending | done
; ============================================================================

; ============================================================================
; Globals
; ============================================================================

global CsvFile     := A_ScriptDir "\reminders.csv"
global CheckEvery  := 15000        ; ms between due-date checks
global MaxTextLen  := 100

global Reminders   := []           ; array of {id, text, due, status, created}
global NextId      := 1

global MainGui := "", RemLV := "", ShowDoneCB := "", StatusTxt := ""
global RowIds  := []               ; ListView row -> reminder id
global ManagerOpen := false

global EditGui := "", EditId := 0
global TextCtl := "", DateCtl := "", TimeCtl := "", CountCtl := ""

global Popups := Map()             ; reminder id -> Gui (currently shown pop-up)
global SnoozingIds := Map()        ; reminder id -> true while its wizard is open

global SnoozeChoices := ["5 minutes", "10 minutes", "15 minutes", "30 minutes"
                       , "1 hour", "2 hours", "4 hours", "Today 16:00", "Tomorrow 09:00", "Tomorrow 16:00", "Custom..."]
global DefaultSnooze := 2          ; 1-based index into SnoozeChoices

; ============================================================================
; Start-up
; ============================================================================

TraySetIcon("shell32.dll", 44)     ; small clock
A_IconTip := "Simple Reminders"
BuildTrayMenu()

LoadReminders()
SetTimer(CheckDueReminders, CheckEvery)
CheckDueReminders()                ; fire anything already overdue at start-up

#!z::ShowManager()

; ============================================================================
; CSV storage
; ============================================================================

LoadReminders() {
    global Reminders := [], NextId := 1

    if !FileExist(CsvFile)
        return

    try
        content := FileRead(CsvFile, "UTF-8")
    catch as e {
        MsgBox("Could not read " CsvFile ":`n" e.Message, "Simple Reminders", "Icon!")
        return
    }

    rows := ParseCsv(content)
    for i, row in rows {
        if (i = 1 && row.Length && Trim(row[1]) = "id")   ; header
            continue
        if (row.Length < 3)
            continue

        digits := RegExReplace(row[1], "\D", "")
        id  := (digits = "") ? NextId : Integer(digits)
        due := Trim(row[3])
        if (RegExReplace(due, "\D", "") = "")             ; unusable date -> skip
            continue

        Reminders.Push({ id      : id
                       , text    : SubStr(Trim(row[2]), 1, MaxTextLen)
                       , due     : due
                       , status  : (row.Length >= 4 && Trim(row[4]) = "done") ? "done" : "pending"
                       , created : (row.Length >= 5 && Trim(row[5]) != "") ? Trim(row[5]) : StampToText(A_Now) })
        if (id >= NextId)
            NextId := id + 1
    }
    SortReminders()
}

SaveReminders() {
    out := "id,text,due,status,created`r`n"
    for r in Reminders
        out .= r.id "," CsvField(r.text) "," CsvField(r.due) "," r.status "," CsvField(r.created) "`r`n"

    try {
        f := FileOpen(CsvFile, "w", "UTF-8")             ; full rewrite, BOM for Excel
        f.Write(out)
        f.Close()
    } catch as e {
        MsgBox("Could not write " CsvFile ":`n" e.Message, "Simple Reminders", "Icon!")
    }
}

; Quote a field only when it needs it; embedded quotes are doubled (RFC 4180).
CsvField(value) {
    if RegExMatch(value, '[",\r\n]')
        return '"' StrReplace(value, '"', '""') '"'
    return value
}

; Character-by-character parser: handles quoted fields, doubled quotes and
; newlines inside quotes, so a reminder containing a comma survives a round trip.
ParseCsv(text) {
    rows := [], row := [], field := "", inQuotes := false, i := 1, len := StrLen(text)

    while (i <= len) {
        c := SubStr(text, i, 1)

        if (inQuotes) {
            if (c = '"') {
                if (SubStr(text, i + 1, 1) = '"') {
                    field .= '"'
                    i += 2
                    continue
                }
                inQuotes := false
                i++
                continue
            }
            field .= c
            i++
            continue
        }

        if (c = '"') {
            inQuotes := true
            i++
            continue
        }
        if (c = ",") {
            row.Push(field), field := ""
            i++
            continue
        }
        if (c = "`r" || c = "`n") {
            if (c = "`r" && SubStr(text, i + 1, 1) = "`n")
                i++
            row.Push(field), field := ""
            rows.Push(row), row := []
            i++
            continue
        }

        field .= c
        i++
    }

    if (field != "" || row.Length) {
        row.Push(field)
        rows.Push(row)
    }
    return rows
}

; ============================================================================
; Date helpers  (stamp = AHK YYYYMMDDHH24MISS, text = yyyy-MM-dd HH:mm:ss)
; ============================================================================

StampToText(stamp) => FormatTime(stamp, "yyyy-MM-dd HH:mm:ss")
TextToStamp(txt)   => SubStr(RegExReplace(txt, "\D", "") "00000000000000", 1, 14)
DueStamp(r)        => TextToStamp(r.due)
FormatWhen(txt)    => FormatTime(TextToStamp(txt), "ddd yyyy-MM-dd  HH:mm")

HumanDelta(secs) {
    if (secs < 0)
        return "overdue"
    if (secs < 60)
        return "< 1 min"
    mins := secs // 60
    if (mins < 60)
        return mins " min"
    hours := mins // 60
    if (hours < 24)
        return hours " h " Format("{:02}", Mod(mins, 60))
    return (hours // 24) " d " Mod(hours, 24) " h"
}

SortReminders() {
    ; Insertion sort on the due text. The fixed-width format sorts
    ; chronologically, but it has to be compared with StrCompare: v2's ">"
    ; is numeric-only and throws on a string like "2027-01-01 09:00:00".
    loop Reminders.Length - 1 {
        i := A_Index + 1
        item := Reminders[i]
        j := i - 1
        while (j >= 1 && StrCompare(Reminders[j].due, item.due) > 0) {
            Reminders[j + 1] := Reminders[j]
            j--
        }
        Reminders[j + 1] := item
    }
}

FindReminder(id) {
    for i, r in Reminders
        if (r.id = id)
            return i
    return 0
}

; ============================================================================
; Due-date polling
; ============================================================================

CheckDueReminders(*) {
    now := A_Now
    for r in Reminders {
        if (r.status != "pending")
            continue
        if Popups.Has(r.id)                       ; its pop-up is already up
            continue
        if SnoozingIds.Has(r.id)                  ; its snooze wizard is open
            continue
        if (DateDiff(DueStamp(r), now, "Seconds") <= 0)
            ShowPopup(r)
    }
    if ManagerOpen
        RefreshList()
}

; ============================================================================
; Reminder pop-up  (center-right of the primary monitor, never steals focus)
; ============================================================================

ShowPopup(r) {
    p := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox +ToolWindow +Owner", "Reminder")
    p.MarginX := 12, p.MarginY := 12
    p.BackColor := "FFFFFF"

    p.SetFont("s11", "Segoe UI")
    p.Add("Text", "w300", r.text)

    p.SetFont("s8")
    p.Add("Text", "xm y+8 w300 cGray", "Due " FormatWhen(r.due))

    p.SetFont("s9")
    ddl  := p.Add("DropDownList", "xm y+10 w120 Choose" DefaultSnooze, SnoozeChoices)
    bSnz := p.Add("Button", "x+8 yp-1 w85", "Snooze")
    bDis := p.Add("Button", "x+8 yp w85 Default", "Dismiss")

    bSnz.OnEvent("Click", (*) => SnoozeReminder(r.id, ddl.Text))
    bDis.OnEvent("Click", (*) => DismissReminder(r.id))
    ; closing the window any other way snoozes, so it never loops back in 15 s
    p.OnEvent("Close",  (*) => SnoozeReminder(r.id, ddl.Text))
    p.OnEvent("Escape", (*) => SnoozeReminder(r.id, ddl.Text))

    Popups[r.id] := p
    PositionPopup(p)
}

PositionPopup(g) {
    MonitorGetWorkArea(MonitorGetPrimary(), &left, &top, &right, &bottom)

    g.Show("Hide AutoSize")
    WinGetPos(, , &w, &h, g)

    x := right - w - 20
    ; stack any pop-ups that are already open downwards from the centre
    slot := Popups.Count - 1
    y := top + (bottom - top - h) // 2 + slot * (h + 8)
    if (y + h > bottom - 10)
        y := bottom - h - 10

    g.Show("NoActivate x" x " y" y)
}

ClosePopup(id) {
    if !Popups.Has(id)
        return
    try Popups[id].Destroy()
    Popups.Delete(id)
}

SnoozeReminder(id, choice) {
    ClosePopup(id)
    if !FindReminder(id)
        return

    ; "Custom..." opens a wizard that blocks on WinWaitClose, which the 15 s
    ; timer interrupts - and the reminder is still pending and overdue, so
    ; CheckDueReminders would pop a duplicate on top of it. Keyed by id, not a
    ; single flag, so a second reminder's wizard can be opened over this one.
    SnoozingIds[id] := true
    try {
        stamp := SnoozeStamp(choice)
    } finally {
        SnoozingIds.Delete(id)
    }

    ; The list may have been reloaded, re-sorted or had rows deleted while the
    ; wizard was up, so the index has to be resolved again afterwards.
    if !(i := FindReminder(id))
        return
    Reminders[i].due := StampToText(stamp)
    SaveReminders()
    if ManagerOpen
        RefreshList()
    ShowSnoozeTip(stamp)
}

; Brief confirmation of when the reminder comes back: 1 s for a short snooze
; (<= 4 h), 2 s for a longer one, where the date is worth a second look.
ShowSnoozeTip(stamp) {
    static clear := () => ToolTip(, , , 20)
    mins := DateDiff(stamp, A_Now, "Minutes")
    ToolTip("Snoozed until " FormatTime(stamp, "ddd yyyy-MM-dd HH:mm"), , , 20)
    SetTimer(clear, mins <= 240 ? -2000 : -3000)
}

DismissReminder(id) {
    i := FindReminder(id)
    ClosePopup(id)
    if !i
        return
    Reminders[i].status := "done"
    SaveReminders()
    if ManagerOpen
        RefreshList()
}

ChooseForUntil(promptText := "Choose an option:", title := "Custom snooze") {
    result := "Cancel"  ; default if closed via X or Escape

    g := Gui("+AlwaysOnTop +Owner", title)
    g.SetFont("s10")
    g.AddText("w280", promptText)

    btnFor    := g.AddButton("w85 y+15", "For...")
    btnUntil  := g.AddButton("x+10 w85", "Until...")
    btnCancel := g.AddButton("x+10 w85", "Cancel")

    btnFor.OnEvent("Click",    (*) => (result := "For",    g.Destroy()))
    btnUntil.OnEvent("Click",  (*) => (result := "Until",  g.Destroy()))
    btnCancel.OnEvent("Click", (*) => (result := "Cancel", g.Destroy()))
    g.OnEvent("Close",  (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())

    g.Show("AutoSize")
    WinWaitClose("ahk_id " g.Hwnd)  ; blocks until the Gui closes

    return result
}

SnoozeStamp(choice) {
    switch choice {
        case "5 minutes":  return DateAdd(A_Now, 5,  "Minutes")
        case "10 minutes": return DateAdd(A_Now, 10, "Minutes")
        case "15 minutes": return DateAdd(A_Now, 15, "Minutes")
        case "30 minutes": return DateAdd(A_Now, 30, "Minutes")
        case "1 hour":     return DateAdd(A_Now, 1,  "Hours")
        case "2 hours":    return DateAdd(A_Now, 2,  "Hours")
        case "4 hours":    return DateAdd(A_Now, 4,  "Hours")
        case "Today 16:00": return SubStr(A_Now, 1, 8) "160000"
        case "Tomorrow 09:00": return SubStr(DateAdd(A_Now, 1, "Days"), 1, 8) "090000"
        case "Tomorrow 16:00": return SubStr(DateAdd(A_Now, 1, "Days"), 1, 8) "160000"
        case "Custom...": return CustomSnoozeStamp()
    }
    return DateAdd(A_Now, 10, "Minutes")
}

; ----------------------------------------------------------------------------
; Custom snooze wizard
;
; Two steps - For/Until, then the value - with Back on the second one, so a
; wrong turn costs a click instead of a cancelled snooze. Both steps block on
; WinWaitClose (Gui.Show does not block), and an unparseable value re-opens the
; same box with the text still in it rather than throwing the snooze away.
; ----------------------------------------------------------------------------

CustomSnoozeStamp() {
    step   := 1                    ; 1 = For/Until chooser, 2 = For input, 3 = Until input
    forTxt := "", forErr := ""     ; survive an invalid re-open
    untTxt := "", untErr := ""

    loop {                         ; Back can bounce between the steps forever
        if (step = 1) {
            choice := ChooseForUntil("Snooze for a duration, or until a time?", "Custom snooze")
            if (choice = "For")
                step := 2
            else if (choice = "Until")
                step := 3
            else
                return DateAdd(A_Now, 2, "Minutes")   ; Cancel / X / Escape
            continue
        }

        if (step = 2) {
            res := AskSnoozeValue("Snooze for...", "Enter a duration (e.g. 1h30m, 45m, 2h)", forTxt, forErr)
            if (res.action = "cancel")
                return DateAdd(A_Now, 2, "Minutes")
            if (res.action = "back") {
                forErr := "", step := 1
                continue
            }
            forTxt := res.value                       ; bad text survives the re-open
            if (forTxt = "") {
                forErr := "Type a duration first."
                continue
            }
            if ((mins := ParseDurationMinutes(forTxt)) < 0) {
                forErr := "Invalid format. Use like 1h30m, 45m, or 2h."
                continue
            }
            return DateAdd(A_Now, mins, "Minutes")
        }

        res := AskSnoozeValue("Snooze until...", "Enter a snooze time (((yyyy/yy)-MM-dd) HH:mm) or Tomorrow HH:mm", untTxt, untErr)
        if (res.action = "cancel")
            return DateAdd(A_Now, 2, "Minutes")
        if (res.action = "back") {
            untErr := "", step := 1
            continue
        }
        untTxt := res.value
        if (untTxt = "") {
            untErr := "Type a time first."
            continue
        }
        if ((stamp := ParseUntilStamp(untTxt)) = "") {
            untErr := "Invalid format. Use ((yyyy)(yy)-MM-dd HH:mm) or Tomorrow HH:mm."
            continue
        }
        try                        ; the regexes accept 02-31 and 25:00, DateDiff does not
            DateDiff(stamp, A_Now, "Seconds")
        catch {
            untErr := "That date does not exist."
            continue
        }
        return stamp
    }
}

; Step 2 of the wizard. Same blocking shape as ChooseForUntil: the handlers set
; the locals and destroy the Gui, WinWaitClose waits for that.
; Returns {action: "ok" | "back" | "cancel", value: <trimmed text>}.
AskSnoozeValue(title, promptText, initialValue := "", errorText := "") {
    action := "cancel"             ; default if closed via X or Escape
    value  := ""

    g := Gui("+AlwaysOnTop +Owner -MinimizeBox -MaximizeBox", title)
    g.SetFont("s10")
    g.MarginX := 14, g.MarginY := 14

    g.AddText("xm w280", promptText)
    edit := g.AddEdit("xm y+6 w280", initialValue)

    if (errorText != "") {
        g.SetFont("s9 cRed")
        g.AddText("xm y+6 w280", errorText)
        g.SetFont("s10 cDefault")
    }

    bOk   := g.AddButton("xm y+14 w85 Default", "Enter")
    bBack := g.AddButton("x+10 w85", "Back")
    bCncl := g.AddButton("x+10 w85", "Cancel")

    ; edit.Value has to be read before Destroy - the comma runs left to right
    bOk.OnEvent("Click",   (*) => (value := edit.Value, action := "ok",   g.Destroy()))
    bBack.OnEvent("Click", (*) => (value := edit.Value, action := "back", g.Destroy()))
    bCncl.OnEvent("Click", (*) => (action := "cancel", g.Destroy()))
    g.OnEvent("Close",  (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())

    g.Show("AutoSize Center")
    edit.Focus()                   ; only sticks after Show
    if (initialValue != "")        ; EM_SETSEL: caret past the text we kept
        try SendMessage(0xB1, StrLen(initialValue), StrLen(initialValue), edit.Hwnd)

    WinWaitClose("ahk_id " g.Hwnd)
    return { action: action, value: Trim(value) }
}

; Whole minutes, or -1 when the text matches none of the duration formats.
ParseDurationMinutes(txt) {
    if RegExMatch(txt, "^(\d+)w(\d+)d(\d+)h(\d+)m$", &m)
        return (m[1] * 7 * 24 * 60) + (m[2] * 24 * 60) + (m[3] * 60) + m[4]
    if RegExMatch(txt, "^(\d+)d(\d+)h$", &m)
        return (m[1] * 24 * 60) + (m[2] * 60)
    if RegExMatch(txt, "^(\d+)d$", &m)
        return m[1] * 24 * 60
    if RegExMatch(txt, "^(\d+)d(\d+)h(\d+)m$", &m)
        return (m[1] * 24 * 60) + (m[2] * 60) + m[3]
    if RegExMatch(txt, "^(\d+)h(\d+)m$", &m)
        return (m[1] * 60) + m[2]
    if RegExMatch(txt, "^(\d+)h$", &m)
        return m[1] * 60
    if RegExMatch(txt, "^(\d+)m$", &m)
        return m[1] + 0
    if RegExMatch(txt, "^(\d+)$", &m)
        return m[1] + 0
    return -1
}

; YYYYMMDDHH24MI00, or "" when the text matches none of the datetime formats.
ParseUntilStamp(txt) {
    days := Map(
        "sun", 1, "sunday", 1,
        "mon", 2, "monday", 2,
        "tue", 3, "tuesday", 3,
        "wed", 4, "wednesday", 4,
        "thu", 5, "thursday", 5,
        "fri", 6, "friday", 6,
        "sat", 7, "saturday", 7
    )
    if RegExMatch(txt, "^[A-Za-z]+$"){ ; text only - snooze default (9am)
        if days.Has(StrLower(txt))
            return SubStr(DateAdd(A_Now, Mod(days[StrLower(txt)] - A_WDay + 7, 7), "Days"), 1, 8) "090000"
        if StrLower(txt) = "today"
            return SubStr(A_Now, 1, 8) "090000"
        if StrLower(txt) = "tomorrow"
            return SubStr(DateAdd(A_Now, 1, "Days"), 1, 8) "090000"
        return ""
    }
    ; if RegExMatch(txt, "^(?i)Fri(day)$", &m)
    ;    dif_days := (5 + 7 - A_WDay) % 7
    ;    return SubStr(DateAdd(A_Now, dif_days, "Days"), 1, 8) "090000"

    if RegExMatch(txt, "^(?i)Today (\d{2}):(\d{2})$", &m)
        return SubStr(A_Now, 1, 8) m[1] m[2] "00"
    if RegExMatch(txt, "^(?i)Tom(orrow)? (\d{2}):(\d{2})$", &m)
        return SubStr(DateAdd(A_Now, 1, "Days"), 1, 8) m[1] m[2] "00"
    if RegExMatch(txt, "^([A-Za-z]+) (\d{2}):(\d{2})$", &m) {
        day := days.Has(StrLower(m[1])) ? days[StrLower(m[1])] : 0
        if !day
            return ""
        dif_days := Mod(day - A_WDay + 7, 7)
        return SubStr(DateAdd(A_Now, dif_days, "Days"), 1, 8) m[2] m[3] "00"
    }
    if RegExMatch(txt, "^(\d{2})/(\d{2})/(\d{2}) (\d{2}):(\d{2})$", &m)
        return "20" m[1] m[2] m[3] m[4] m[5] "00"
    if RegExMatch(txt, "^(\d{4})/(\d{2})/(\d{2}) (\d{2}):(\d{2})$", &m)
        return m[1] m[2] m[3] m[4] m[5] "00"
    if RegExMatch(txt, "^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$", &m)
        return m[1] m[2] m[3] m[4] m[5] "00"
    if RegExMatch(txt, "^(\d{2})-(\d{2})-(\d{2}) (\d{2}):(\d{2})$", &m)
        return "20" m[1] m[2] m[3] m[4] m[5] "00"
    if RegExMatch(txt, "^(\d{2})-(\d{2}) (\d{2}):(\d{2})$", &m)
        return A_YYYY m[1] m[2] m[3] m[4] "00"
    if RegExMatch(txt, "^(\d{2}):(\d{2})$", &m)
        return A_YYYY A_MM A_DD m[1] m[2] "00"
    return ""
}


; ============================================================================
; Manager GUI
; ============================================================================

ShowManager() {
    global MainGui, RemLV, ShowDoneCB, StatusTxt, ManagerOpen

    if IsObject(MainGui) {
        ManagerOpen := true
        RefreshList()
        MainGui.Show()
        return
    }

    MainGui := Gui("-MaximizeBox", "Simple Reminders")
    MainGui.SetFont("s9", "Segoe UI")
    MainGui.MarginX := 10, MainGui.MarginY := 10

    RemLV := MainGui.Add("ListView", "w600 r14 Grid -Multi", ["When", "In", "Reminder", "Status"])
    RemLV.ModifyCol(1, 150)
    RemLV.ModifyCol(2, 80)
    RemLV.ModifyCol(3, 280)
    RemLV.ModifyCol(4, 70)
    RemLV.OnEvent("DoubleClick", (*) => EditSelected())

    ShowDoneCB := MainGui.Add("Checkbox", "xm y+8", "Show completed")
    ShowDoneCB.OnEvent("Click", (*) => RefreshList())

    ; widths + the six 6 px gaps add up to the ListView's 600
    bNew   := MainGui.Add("Button", "xm y+8 w78", "&New")
    bEdit  := MainGui.Add("Button", "x+6 yp w78", "&Edit")
    bDup   := MainGui.Add("Button", "x+6 yp w92", "D&uplicate")
    bDel   := MainGui.Add("Button", "x+6 yp w80", "&Delete")
    bDone  := MainGui.Add("Button", "x+6 yp w96", "Mark d&one")
    bPurge := MainGui.Add("Button", "x+6 yp w78", "&Clear...")
    bClose := MainGui.Add("Button", "x+6 yp w62", "Close")

    bNew.OnEvent("Click",   (*) => OpenEditor(0))
    bEdit.OnEvent("Click",  (*) => EditSelected())
    bDup.OnEvent("Click",   (*) => DuplicateSelected())
    bDel.OnEvent("Click",   (*) => DeleteSelected())
    bDone.OnEvent("Click",  (*) => MarkSelectedDone())
    bPurge.OnEvent("Click", (*) => ShowClearMenu())
    bClose.OnEvent("Click", (*) => HideManager())

    StatusTxt := MainGui.Add("Text", "xm y+10 w600", "")

    MainGui.OnEvent("Close",  (*) => HideManager())
    MainGui.OnEvent("Escape", (*) => HideManager())

    ManagerOpen := true
    RefreshList()
    MainGui.Show()
}

HideManager() {
    global ManagerOpen := false
    if IsObject(MainGui)
        MainGui.Hide()
}

RefreshList() {
    global RowIds

    if !IsObject(RemLV)
        return

    SortReminders()
    showDone := ShowDoneCB.Value
    now := A_Now
    pending := 0

    RemLV.Opt("-Redraw")
    RemLV.Delete()
    RowIds := []

    for r in Reminders {
        if (r.status = "pending")
            pending++
        if (r.status = "done" && !showDone)
            continue

        secs := DateDiff(DueStamp(r), now, "Seconds")
        if (r.status = "done") {
            inTxt := "", state := "done"
        } else {
            inTxt := HumanDelta(secs), state := (secs < 0 ? "overdue" : "pending")
        }

        RemLV.Add(, FormatWhen(r.due), inTxt, r.text, state)
        RowIds.Push(r.id)
    }
    RemLV.Opt("+Redraw")

    StatusTxt.Value := pending " pending  -  " Reminders.Length " total  -  " CsvFile
}

SelectedId() {
    row := RemLV.GetNext()
    if !row {
        MsgBox("Select a reminder first.", "Simple Reminders", "Icon! Owner" MainGui.Hwnd)
        return 0
    }
    return RowIds[row]
}

EditSelected() {
    if (id := SelectedId())
        OpenEditor(id)
}

; Opens the editor as a *new* reminder pre-filled from the selected one, so the
; copy is only written to the CSV once Save is pressed (and it gets a fresh id).
DuplicateSelected() {
    if !(id := SelectedId())
        return
    if FindReminder(id)
        OpenEditor(0, id)
}

DeleteSelected() {
    if !(id := SelectedId())
        return
    i := FindReminder(id)
    if !i
        return
    if (MsgBox("Delete this reminder?`n`n" Reminders[i].text, "Simple Reminders"
             , "YesNo Icon? Owner" MainGui.Hwnd) != "Yes")
        return
    ClosePopup(id)
    Reminders.RemoveAt(i)
    SaveReminders()
    RefreshList()
}

MarkSelectedDone() {
    if !(id := SelectedId())
        return
    if (i := FindReminder(id)) {
        ClosePopup(id)
        Reminders[i].status := (Reminders[i].status = "done") ? "pending" : "done"
        SaveReminders()
        RefreshList()
    }
}

; ============================================================================
; Clear...  (bulk removal)
; ============================================================================

; A MsgBox tops out at three buttons, so the chooser is its own little modal
; Gui. Each choice runs its own confirmation before anything is written.
ShowClearMenu() {
    g := Gui("-MinimizeBox -MaximizeBox +Owner" MainGui.Hwnd, "Clear reminders")
    g.SetFont("s9", "Segoe UI")
    g.MarginX := 14, g.MarginY := 14

    g.Add("Text", "xm", "What should be removed from the CSV?")

    bDone  := g.Add("Button", "xm y+12 w300", "Clear &completed")
    bFirst := g.Add("Button", "xm y+6 w300", "Clear duplicates - keep the &earliest due")
    bLast  := g.Add("Button", "xm y+6 w300", "Clear duplicates - keep the &latest due")
    bCncl  := g.Add("Button", "xm y+12 w300", "Cancel")

    bDone.OnEvent("Click",  (*) => ClearMenuPick(g, "completed"))
    bFirst.OnEvent("Click", (*) => ClearMenuPick(g, "earliest"))
    bLast.OnEvent("Click",  (*) => ClearMenuPick(g, "latest"))
    bCncl.OnEvent("Click",  (*) => g.Destroy())

    g.OnEvent("Close",  (*) => g.Destroy())
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()
}

; The chooser closes before the action runs, so the confirmation MsgBox is
; owned by the manager and the chooser cannot be left hanging behind it.
ClearMenuPick(g, action) {
    try g.Destroy()
    if (action = "completed")
        ClearCompleted()
    else
        ClearDuplicates(action)
}

ClearCompleted() {
    global Reminders

    count := 0
    for r in Reminders
        if (r.status = "done")
            count++
    if !count {
        MsgBox("There are no completed reminders.", "Simple Reminders", "Iconi Owner" MainGui.Hwnd)
        return
    }
    if (MsgBox("Remove " count " completed reminder(s) from the CSV?", "Simple Reminders"
             , "YesNo Icon? Owner" MainGui.Hwnd) != "Yes")
        return

    kept := []
    for r in Reminders
        if (r.status != "done")
            kept.Push(r)
    Reminders := kept
    SaveReminders()
    RefreshList()
}

; Two reminders are duplicates when they share the same status and the same
; text (case- and whitespace-insensitive). Of each group, keep = "earliest"
; keeps the one due soonest, "latest" the one due last; the rest are dropped.
ClearDuplicates(keep) {
    global Reminders

    SortReminders()                            ; each group is then in due order

    ; key -> index of the row to keep. "earliest" keeps the first hit in the
    ; sorted array, "latest" lets every later hit overwrite it.
    survivorOf := Map()
    survivorOf.CaseSense := false
    for i, r in Reminders {
        key := r.status "|" RegExReplace(Trim(r.text), "\s+", " ")
        if (!survivorOf.Has(key) || keep = "latest")
            survivorOf[key] := i
    }

    survivors := Map()
    for key, i in survivorOf
        survivors[i] := true

    count := Reminders.Length - survivors.Count
    if !count {
        MsgBox("There are no duplicate reminders.", "Simple Reminders", "Iconi Owner" MainGui.Hwnd)
        return
    }

    which := (keep = "latest") ? "latest" : "earliest"
    if (MsgBox("Remove " count " duplicate reminder(s), keeping the " which " due time of each?"
             , "Simple Reminders", "YesNo Icon? Owner" MainGui.Hwnd) != "Yes")
        return

    kept := []
    for i, r in Reminders {
        if survivors.Has(i) {
            kept.Push(r)
            continue
        }
        ClosePopup(r.id)                       ; a pop-up for a removed row is stale
    }
    Reminders := kept
    SaveReminders()
    RefreshList()
}

; ============================================================================
; New / edit reminder
; ============================================================================

; id = reminder to edit, or 0 for a new one. dupeFrom (only meaningful when
; id = 0) is the reminder whose text and due time pre-fill the new one.
OpenEditor(id := 0, dupeFrom := 0) {
    global EditGui, EditId, TextCtl, DateCtl, TimeCtl, CountCtl

    if IsObject(EditGui) {
        try EditGui.Destroy()
        EditGui := ""
    }

    EditId := id
    src := id ? id : dupeFrom
    i := src ? FindReminder(src) : 0
    text  := i ? Reminders[i].text : ""
    stamp := i ? DueStamp(Reminders[i]) : DateAdd(A_Now, 15, "Minutes")

    owner := (IsObject(MainGui) && ManagerOpen) ? " +Owner" MainGui.Hwnd : ""
    title := id ? "Edit reminder" : (i ? "Duplicate reminder" : "New reminder")
    EditGui := Gui("-MaximizeBox -MinimizeBox" owner, title)
    EditGui.SetFont("s9", "Segoe UI")
    EditGui.MarginX := 12, EditGui.MarginY := 12

    EditGui.Add("Text", "xm", "Reminder text (max " MaxTextLen " characters)")
    TextCtl := EditGui.Add("Edit", "xm y+4 w420 Limit" MaxTextLen, text)
    CountCtl := EditGui.Add("Text", "xm y+4 w420 cGray", "")
    TextCtl.OnEvent("Change", (*) => UpdateCount())

    EditGui.Add("Text", "xm y+12 w60", "When")
    DateCtl := EditGui.Add("DateTime", "x+8 yp-3 w130", "yyyy-MM-dd")
    TimeCtl := EditGui.Add("DateTime", "x+8 yp w80 1", "HH:mm")
    DateCtl.Value := stamp
    TimeCtl.Value := stamp

    EditGui.Add("Text", "xm y+12 w60", "Quick set")
    b15 := EditGui.Add("Button", "x+8 yp-4 w70", "in 15m")
    b1h := EditGui.Add("Button", "x+6 yp w70", "in 1h")
    b3h := EditGui.Add("Button", "x+6 yp w70", "in 3h")
    b9  := EditGui.Add("Button", "x+6 yp w80", "tom 9:00")
    bCustom := EditGui.Add("Button", "x+6 yp w80", "Custom...")
    bCustom.OnEvent("Click", (*) => SetEditorStamp(SnoozeStamp("Custom...")))

    b15.OnEvent("Click", (*) => SetEditorStamp(DateAdd(A_Now, 15, "Minutes")))
    b1h.OnEvent("Click", (*) => SetEditorStamp(DateAdd(A_Now, 1, "Hours")))
    b3h.OnEvent("Click", (*) => SetEditorStamp(DateAdd(A_Now, 3, "Hours")))
    b9.OnEvent("Click",  (*) => SetEditorStamp(SubStr(DateAdd(A_Now, 1, "Days"), 1, 8) "090000"))

    bSave   := EditGui.Add("Button", "xm y+16 w100 Default", "&Save")
    bCancel := EditGui.Add("Button", "x+8 yp w100", "Cancel")
    bSave.OnEvent("Click",   (*) => SaveEditor())
    bCancel.OnEvent("Click", (*) => CloseEditor())

    EditGui.OnEvent("Close",  (*) => CloseEditor())
    EditGui.OnEvent("Escape", (*) => CloseEditor())

    UpdateCount()
    EditGui.Show()
    TextCtl.Focus()
}

UpdateCount() {
    CountCtl.Value := StrLen(TextCtl.Value) " / " MaxTextLen " characters"
}

SetEditorStamp(stamp) {
    DateCtl.Value := stamp
    TimeCtl.Value := stamp
}

CloseEditor() {
    global EditGui
    if IsObject(EditGui) {
        try EditGui.Destroy()
        EditGui := ""
    }
}

SaveEditor() {
    global Reminders, NextId

    text := Trim(RegExReplace(TextCtl.Value, "[\r\n\t]+", " "))
    if (text = "") {
        MsgBox("Type the reminder text first.", "Simple Reminders", "Icon! Owner" EditGui.Hwnd)
        TextCtl.Focus()
        return
    }
    text := SubStr(text, 1, MaxTextLen)

    ; date from the calendar control, time from the spinner, seconds always 00
    stamp := SubStr(DateCtl.Value, 1, 8) SubStr(TimeCtl.Value, 9, 4) "00"

    if (DateDiff(stamp, A_Now, "Seconds") < 0) {
        if (MsgBox("That time is in the past - the reminder will pop up right away.`n`nSave anyway?"
                 , "Simple Reminders", "YesNo Icon? Owner" EditGui.Hwnd) != "Yes")
            return
    }

    if (EditId && (i := FindReminder(EditId))) {
        ClosePopup(EditId)                       ; a visible pop-up is now stale
        Reminders[i].text   := text
        Reminders[i].due    := StampToText(stamp)
        Reminders[i].status := "pending"         ; re-scheduling revives a done one
    } else {
        Reminders.Push({ id      : NextId
                       , text    : text
                       , due     : StampToText(stamp)
                       , status  : "pending"
                       , created : StampToText(A_Now) })
        NextId++
    }

    SaveReminders()
    CloseEditor()
    if ManagerOpen
        RefreshList()
    CheckDueReminders()
}

; ============================================================================
; Tray
; ============================================================================

BuildTrayMenu() {
    t := A_TrayMenu
    t.Delete()
    t.Add("Reminders (Win+Alt+Z)", (*) => ShowManager())
    t.Add("Reload from CSV", (*) => ReloadCsv())
    t.Add("Open CSV", (*) => OpenCsv())
    t.Add()
    t.Add("Reload script", (*) => Reload())
    t.Add("Exit", (*) => ExitApp())
    t.Default := "Reminders (Win+Alt+Z)"
}

ReloadCsv() {
    for id in Popups.Clone()
        ClosePopup(id)
    LoadReminders()
    if ManagerOpen
        RefreshList()
    CheckDueReminders()
}

OpenCsv() {
    if !FileExist(CsvFile) {
        MsgBox("No reminders have been saved yet, so " CsvFile " does not exist.", "Simple Reminders")
        return
    }
    try
        Run('"' CsvFile '"')
    catch
        Run('notepad.exe "' CsvFile '"')
}
