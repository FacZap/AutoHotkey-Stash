#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================================
; SimpleReminders.ahk  —  plain-text reminders with a quiet pop-up.
;
;   Win+Alt+Z   open the manager GUI (write / edit / delete reminders)
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

global SnoozeChoices := ["5 minutes", "10 minutes", "15 minutes", "30 minutes"
                       , "1 hour", "2 hours", "4 hours", "Tomorrow 09:00"]
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
    i := FindReminder(id)
    ClosePopup(id)
    if !i
        return
    Reminders[i].due := StampToText(SnoozeStamp(choice))
    SaveReminders()
    if ManagerOpen
        RefreshList()
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

SnoozeStamp(choice) {
    switch choice {
        case "5 minutes":  return DateAdd(A_Now, 5,  "Minutes")
        case "10 minutes": return DateAdd(A_Now, 10, "Minutes")
        case "15 minutes": return DateAdd(A_Now, 15, "Minutes")
        case "30 minutes": return DateAdd(A_Now, 30, "Minutes")
        case "1 hour":     return DateAdd(A_Now, 1,  "Hours")
        case "2 hours":    return DateAdd(A_Now, 2,  "Hours")
        case "4 hours":    return DateAdd(A_Now, 4,  "Hours")
        case "Tomorrow 09:00": return SubStr(DateAdd(A_Now, 1, "Days"), 1, 8) "090000"
    }
    return DateAdd(A_Now, 10, "Minutes")
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

    bNew   := MainGui.Add("Button", "xm y+8 w90", "&New")
    bEdit  := MainGui.Add("Button", "x+6 yp w90", "&Edit")
    bDel   := MainGui.Add("Button", "x+6 yp w90", "&Delete")
    bDone  := MainGui.Add("Button", "x+6 yp w100", "Mark d&one")
    bPurge := MainGui.Add("Button", "x+6 yp w120", "&Clear completed")
    bClose := MainGui.Add("Button", "x+6 yp w80", "Close")

    bNew.OnEvent("Click",   (*) => OpenEditor(0))
    bEdit.OnEvent("Click",  (*) => EditSelected())
    bDel.OnEvent("Click",   (*) => DeleteSelected())
    bDone.OnEvent("Click",  (*) => MarkSelectedDone())
    bPurge.OnEvent("Click", (*) => ClearCompleted())
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

; ============================================================================
; New / edit reminder
; ============================================================================

OpenEditor(id := 0) {
    global EditGui, EditId, TextCtl, DateCtl, TimeCtl, CountCtl

    if IsObject(EditGui) {
        try EditGui.Destroy()
        EditGui := ""
    }

    EditId := id
    i := id ? FindReminder(id) : 0
    text  := i ? Reminders[i].text : ""
    stamp := i ? DueStamp(Reminders[i]) : DateAdd(A_Now, 15, "Minutes")

    owner := (IsObject(MainGui) && ManagerOpen) ? " +Owner" MainGui.Hwnd : ""
    EditGui := Gui("-MaximizeBox -MinimizeBox" owner, id ? "Edit reminder" : "New reminder")
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
    b15 := EditGui.Add("Button", "x+8 yp-4 w70", "in 15 m")
    b1h := EditGui.Add("Button", "x+6 yp w70", "in 1 h")
    b3h := EditGui.Add("Button", "x+6 yp w70", "in 3 h")
    b9  := EditGui.Add("Button", "x+6 yp w110", "tomorrow 9:00")

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
