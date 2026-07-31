#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================================
; MacroRecorder.ahk  —  multi-slot macro recorder with persistent storage,
;                       recorded pauses, playback speed/repeat and a GUI.
;
; Replaces: Macro.Recorder.ahk, Macro.Recorder.v2.ahk, run-macro_recorder.ahk
;
; Macros are stored as standalone AutoHotkey v2 scripts in .\macros\ and are
; played back by launching them in their own process. The library index lives
; in .\macros\macros.ini
;
; See README_MacroRecorder.md for usage.
; ============================================================================

Thread("NoTimers")
CoordMode("ToolTip")
SetTitleMatchMode(2)
DetectHiddenWindows(true)

; ============================================================================
; Globals
; ============================================================================

global MacroDir   := A_ScriptDir "\macros"
global IniFile    := MacroDir "\macros.ini"
global MasterPath := A_ScriptDir "\^^AHK_Unified_Master.ahk"

; --- settings (loaded from [General]) ---
global PlayPrefix   := "#!"
global RecordPrefix := "#!+"
global GuiHotkey    := "!F1"
global PanicHotkey  := "^!Esc"
global PauseHotkey  := "#!p"
global SlotCount    := 12
global SlotKeys     := []
global MouseMode    := "screen"
global RecordSleep  := true
global MinGap       := 200
global DefaultPause := 1000
global SuspendMaster := false
global ShowGuiOnStart := false

; --- runtime state ---
global Slots        := []       ; array of {file, name, speed, repeat, lastRun, steps}
global LogArr       := []
global Recording    := false
global RecordSlot   := 0
global Playing      := false
global PlayPid      := 0
global PlayingSlot  := 0
global PendingMods  := Map()
global BoundHotkeys := []
global oldid        := ""
global RelativeX    := 0
global RelativeY    := 0
global MasterWasSuspended := false

; --- GUI handles ---
global MacroGui := "", SlotLV := "", StatusText := ""
global StepGui  := "", StepLV := "", StepSlot := 0, StepCache := []
global CfgGui   := ""

; ============================================================================
; Startup
; ============================================================================

EnsureLibrary()
LoadSettings()
LoadSlots()
MigrateLegacyRecordings()
BindControlHotkeys()
BindSlotHotkeys()
BuildTrayMenu()
OnExit(CleanupOnExit)
if (ShowGuiOnStart)
    ShowMacroGui()
return

; Never leave the master script suspended or a macro running because this
; script was closed mid-playback.
CleanupOnExit(*) {
    global PlayPid, MasterWasSuspended
    if (PlayPid && ProcessExist(PlayPid))
        try ProcessClose(PlayPid)
    if (MasterWasSuspended)
        SuspendMasterScript(false)
}

EnsureLibrary() {
    if !DirExist(MacroDir)
        DirCreate(MacroDir)
}

BuildTrayMenu() {
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Macro Recorder", (*) => ShowMacroGui())
    A_TrayMenu.Add("Settings", (*) => ShowSettingsGui())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Open macros folder", (*) => Run('explorer.exe "' MacroDir '"'))
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload", (*) => Reload())
    A_TrayMenu.Add("Exit", (*) => ExitApp())
    A_TrayMenu.Default := "Macro Recorder"
    TraySetIcon("shell32.dll", 44)
    A_IconTip := "Macro Recorder"
}

; ============================================================================
; Settings / library persistence
; ============================================================================

LoadSettings() {
    global
    PlayPrefix     := IniRead(IniFile, "General", "PlayPrefix", "#!")
    RecordPrefix   := IniRead(IniFile, "General", "RecordPrefix", "#!+")
    GuiHotkey      := IniRead(IniFile, "General", "GuiHotkey", "!F1")
    PanicHotkey    := IniRead(IniFile, "General", "PanicHotkey", "^!Esc")
    PauseHotkey    := IniRead(IniFile, "General", "PauseHotkey", "#!p")
    SlotCount      := Integer(IniRead(IniFile, "General", "SlotCount", "12"))
    keys           := IniRead(IniFile, "General", "SlotKeys", "F1|F2|F3|F4|F5|F6|F7|F8|F9|F10|F11|F12")
    MouseMode      := IniRead(IniFile, "General", "MouseMode", "screen")
    RecordSleep    := (IniRead(IniFile, "General", "RecordSleep", "true") = "true")
    MinGap         := Integer(IniRead(IniFile, "General", "MinGap", "200"))
    DefaultPause   := Integer(IniRead(IniFile, "General", "DefaultPause", "1000"))
    SuspendMaster  := (IniRead(IniFile, "General", "SuspendMaster", "false") = "true")
    ShowGuiOnStart := (IniRead(IniFile, "General", "ShowGuiOnStart", "false") = "true")

    if (MouseMode != "screen" && MouseMode != "window" && MouseMode != "relative")
        MouseMode := "screen"
    if (SlotCount < 1 || SlotCount > 12)
        SlotCount := 12
    if (MinGap < 1)
        MinGap := 200

    SlotKeys := StrSplit(keys, "|")
    while (SlotKeys.Length < SlotCount)
        SlotKeys.Push("")

    ; First run: materialise the defaults so macros.ini is editable by hand.
    if (IniRead(IniFile, "General", "PlayPrefix", "") = "")
        SaveSettings()
}

SaveSettings() {
    global
    IniWrite(PlayPrefix,   IniFile, "General", "PlayPrefix")
    IniWrite(RecordPrefix, IniFile, "General", "RecordPrefix")
    IniWrite(GuiHotkey,    IniFile, "General", "GuiHotkey")
    IniWrite(PanicHotkey,  IniFile, "General", "PanicHotkey")
    IniWrite(PauseHotkey,  IniFile, "General", "PauseHotkey")
    IniWrite(SlotCount,    IniFile, "General", "SlotCount")
    IniWrite(JoinArr(SlotKeys, "|"), IniFile, "General", "SlotKeys")
    IniWrite(MouseMode,    IniFile, "General", "MouseMode")
    IniWrite(RecordSleep ? "true" : "false",    IniFile, "General", "RecordSleep")
    IniWrite(MinGap,       IniFile, "General", "MinGap")
    IniWrite(DefaultPause, IniFile, "General", "DefaultPause")
    IniWrite(SuspendMaster ? "true" : "false",  IniFile, "General", "SuspendMaster")
    IniWrite(ShowGuiOnStart ? "true" : "false", IniFile, "General", "ShowGuiOnStart")
}

LoadSlots() {
    global Slots, SlotCount
    Slots := []
    Loop SlotCount {
        sec := "Slot" A_Index
        Slots.Push({
            file:    IniRead(IniFile, sec, "File", ""),
            name:    IniRead(IniFile, sec, "Name", ""),
            speed:   Number(IniRead(IniFile, sec, "Speed", "1.0")),
            repeat:  Integer(IniRead(IniFile, sec, "Repeat", "1")),
            lastRun: IniRead(IniFile, sec, "LastRun", ""),
            steps:   Integer(IniRead(IniFile, sec, "Steps", "0"))
        })
    }
}

SaveSlot(n) {
    global Slots
    s := Slots[n]
    sec := "Slot" n
    IniWrite(s.file,    IniFile, sec, "File")
    IniWrite(s.name,    IniFile, sec, "Name")
    IniWrite(s.speed,   IniFile, sec, "Speed")
    IniWrite(s.repeat,  IniFile, sec, "Repeat")
    IniWrite(s.lastRun, IniFile, sec, "LastRun")
    IniWrite(s.steps,   IniFile, sec, "Steps")
}

SlotPath(n) {
    global Slots, MacroDir
    return Slots[n].file = "" ? "" : MacroDir "\" Slots[n].file
}

SlotFilled(n) {
    p := SlotPath(n)
    return (p != "" && FileExist(p))
}

; One-time import of the old %TEMP%\~Record1.ahk / ~Record2.ahk files.
MigrateLegacyRecordings() {
    global Slots
    if (IniRead(IniFile, "General", "Migrated", "") = "1")
        return
    Loop 2 {
        n := A_Index
        src := A_Temp "\~Record" n ".ahk"
        if (!FileExist(src) || SlotFilled(n))
            continue
        name := "Imported " n
        dest := MacroDir "\" name ".ahk"
        try {
            FileCopy(src, dest, true)
            UpgradeMacroFile(dest)
            Slots[n].file  := name ".ahk"
            Slots[n].name  := name
            Slots[n].steps := CountSteps(dest)
            SaveSlot(n)
        }
    }
    IniWrite("1", IniFile, "General", "Migrated")
}

; Macros produced by the old Macro.Recorder have no SPEED/REPEAT variables and
; use hardcoded Sleep()/Loop(1), so the speed and repeat controls can't touch
; them. Rewrite them into the current format. Sleep lines keep their enabled /
; disabled state — use the step editor to switch them on.
UpgradeMacroFile(path) {
    global PanicHotkey
    if !FileExist(path)
        return false
    txt := FileRead(path)
    if InStr(txt, "SPEED :=")
        return false

    txt := RegExReplace(txt, "m)^(\s*;?)Sleep\((\d+)\)", "$1Sleep(Round($2 / SPEED))")
    txt := RegExReplace(txt, "m)^Loop\(\d+\)", "Loop(REPEAT)")
    ; drop the vestigial registry run-counter block
    txt := RegExReplace(txt, "m)^(StartingValue := 0|i := RegRead\(.*|RegWrite\(.*)\R?", "")
    ; re-point the macro's own abort hotkey at the configured panic key
    txt := RegExReplace(txt, "m)^\S+::ExitApp\(\)",
                        StrReplace(PanicHotkey, "$", "$$") "::ExitApp()")

    header := "#Requires AutoHotkey v2.0`n#SingleInstance Off`n"
            . "SPEED := 1.00`nREPEAT := 1`nif (SPEED <= 0)`n    SPEED := 1.0`n`n"
    FileDelete(path)
    FileAppend(header . txt, path, "UTF-8")
    return true
}

JoinArr(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i = 1 ? "" : sep) v
    return out
}

; ============================================================================
; Hotkey binding
; ============================================================================

BindControlHotkeys() {
    global
    A_SuspendExempt := true
    TryHotkey(GuiHotkey,   (*) => ToggleMacroGui())
    TryHotkey(PanicHotkey, (*) => PanicStop())
    A_SuspendExempt := false
}

; Play hotkeys are bound only for filled slots; record hotkeys are always bound
; so an empty slot can be recorded into. While recording, every slot hotkey is
; released except the active slot's record hotkey (which stops the recording),
; so slot keys can be captured as macro content.
BindSlotHotkeys(recordingSlot := 0) {
    global
    for hk in BoundHotkeys
        try Hotkey(hk, "Off")
    BoundHotkeys := []

    A_SuspendExempt := true
    Loop SlotCount {
        n := A_Index
        key := SlotKeys.Has(n) ? SlotKeys[n] : ""
        if (key = "")
            continue
        if (recordingSlot) {
            if (n = recordingSlot)
                RegisterSlotHotkey(RecordPrefix key, RecordSlot_Handler.Bind(n))
            continue
        }
        if (SlotFilled(n))
            RegisterSlotHotkey(PlayPrefix key, PlaySlot_Handler.Bind(n))
        RegisterSlotHotkey(RecordPrefix key, RecordSlot_Handler.Bind(n))
    }
    A_SuspendExempt := false
}

RegisterSlotHotkey(hk, cb) {
    global BoundHotkeys
    try {
        Hotkey(hk, cb, "On")
        BoundHotkeys.Push(hk)
    }
}

TryHotkey(hk, cb) {
    try Hotkey(hk, cb, "On")
    catch
        MsgBox("Invalid hotkey in macros.ini: " hk, "Macro Recorder", 4096)
}

PlaySlot_Handler(n, *) {
    PlaySlot(n)
}

RecordSlot_Handler(n, *) {
    if (Recording) {
        StopRecording(true)
        return
    }
    StartRecording(n)
}

PanicStop() {
    global Recording, Playing
    if (Recording)
        StopRecording(false)          ; cancel: discard
    if (Playing)
        StopPlayback()
}

; ============================================================================
; On-screen indicator (from the original script)
; ============================================================================

ShowTip(s := "", pos := "y35", color := "Red|00FFFF") {
    static bak := "", idx := 0, TipGui := Gui(), TipText
    if (bak = color "," pos "," s)
        return
    bak := color "," pos "," s
    SetTimer(ShowTip_ChangeColor, 0)
    TipGui.Destroy()
    if (s = "")
        return

    TipGui := Gui("+LastFound +AlwaysOnTop +ToolWindow -Caption +E0x08000020", "ShowTip")
    WinSetTransColor("FFFFF0 150")
    TipGui.BackColor := "cFFFFF0"
    TipGui.MarginX := 10
    TipGui.MarginY := 5
    TipGui.SetFont("q3 s20 bold cRed")
    TipText := TipGui.Add("Text", , s)
    TipGui.Show("NA " . pos)
    SetTimer(ShowTip_ChangeColor, 1000)

    ShowTip_ChangeColor() {
        r := StrSplit(SubStr(bak, 1, InStr(bak, ",") - 1), "|")
        TipText.SetFont("q3 c" r[idx := Mod(Round(idx), r.Length) + 1])
    }
}

SetStatus(txt) {
    global StatusText
    if (StatusText)
        try StatusText.Value := txt
}

; ============================================================================
; Recording
; ============================================================================

StartRecording(n) {
    global LogArr, Recording, RecordSlot, oldid, RelativeX, RelativeY, PendingMods, MacroGui

    if (Recording || Playing)
        return
    if (SlotFilled(n)) {
        if (MsgBox("Slot " n " already holds `"" Slots[n].name "`".`n`nOverwrite it?",
                   "Macro Recorder", "YesNo Icon! 4096") != "Yes")
            return
    }
    if (MacroGui)
        try MacroGui.Hide()

    LogArr := []
    oldid := ""
    PendingMods := Map()
    Log()                                   ; prime the delay timer
    Recording := true
    RecordSlot := n
    BindSlotHotkeys(n)
    SetCapture(true)
    CoordMode("Mouse", "Screen")
    MouseGetPos(&RelativeX, &RelativeY)
    ShowTip("REC " n)
}

; save = true  -> write the macro; false -> discard (cancel)
StopRecording(save := true) {
    global LogArr, Recording, RecordSlot, Slots

    if (!Recording) {
        ShowTip()
        return
    }
    Recording := false
    SetCapture(false)
    n := RecordSlot
    RecordSlot := 0
    TrimPendingChord()

    if (!save) {
        ShowTip("CANCELLED")
        SetTimer(() => ShowTip(), -1200)
    } else if (LogArr.Length = 0) {
        ShowTip("NOTHING RECORDED")
        SetTimer(() => ShowTip(), -1500)
    } else {
        s := Slots[n]
        if (s.name = "")
            s.name := "Macro " n
        if (s.file = "")
            s.file := SanitizeFileName(s.name) ".ahk"
        path := MacroDir "\" s.file
        WriteMacroFile(path, n, LogArr)
        s.steps := CountSteps(path)
        SaveSlot(n)
        ShowTip("SAVED " s.steps)
        SetTimer(() => ShowTip(), -1200)
    }

    LogArr := []
    BindSlotHotkeys()
    RefreshSlotList()
}

; Pressing a modified hotkey (e.g. Win+Alt+Shift+F1) leaves the modifier
; down-events at the tail of the log. Strip them so recordings do not end with
; a stuck {Ctrl Down}{Shift Down}.
TrimPendingChord() {
    global LogArr, PendingMods
    if (LogArr.Length = 0 || PendingMods.Count = 0)
        return
    i := LogArr.Length
    r := LogArr[i]
    if (SubStr(r, 1, 4) != "Send")
        return
    changed := true
    while (changed) {
        changed := false
        if (RegExMatch(r, "\{(\w+) Down\}`"$", &m) && PendingMods.Has(m[1])) {
            r := RegExReplace(r, "\{" m[1] " Down\}`"$", "`"")
            changed := true
        }
    }
    if (r = "Send `"{Blind}`"" || r = "Send `"`"") {
        LogArr.RemoveAt(i)
        ; a Sleep that now dangles at the tail is noise too
        if (LogArr.Length && RegExMatch(LogArr[LogArr.Length], "^;?Sleep\("))
            LogArr.RemoveAt(LogArr.Length)
    } else {
        LogArr[i] := r
    }
    PendingMods := Map()
}

InsertManualPause(*) {
    global Recording, LogArr, DefaultPause
    if (!Recording)
        return
    TrimPendingChord()
    SetCapture(false)                       ; don't record the prompt itself
    ShowTip()
    ib := InputBox("Pause length in milliseconds:", "Insert pause", "w260 h130", DefaultPause)
    if (ib.Result = "OK" && IsInteger(ib.Value) && Integer(ib.Value) > 0)
        LogArr.Push("Sleep(Round(" Integer(ib.Value) " / SPEED))")
    Log()                                   ; reset the delay clock
    SetCapture(true)
    ShowTip("REC " RecordSlot)
}

; ============================================================================
; Input capture
; ============================================================================

SetCapture(on := false) {
    global PauseHotkey
    f := on ? "On" : "Off"
    Loop 254 {
        k := GetKeyName(vk := Format("vk{:X}", A_Index))
        if (!(k ~= "^(?i:|Control|Alt|Shift)$"))
            try Hotkey("~*" vk, LogKey, f)
    }
    for i, k in StrSplit("NumpadEnter|Home|End|PgUp|PgDn|Left|Right|Up|Down|Delete|Insert", "|") {
        sc := Format("sc{:03X}", GetKeySC(k))
        if (!(k ~= "^(?i:|Control|Alt|Shift)$"))
            try Hotkey("~*" sc, LogKey, f)
    }

    ; manual-pause hotkey is only live while capturing
    try Hotkey(PauseHotkey, InsertManualPause, f)

    if (on) {
        SetTimer(LogWindow, 250)
        LogWindow()
    } else {
        SetTimer(LogWindow, 0)
    }
}

LogKey(HotkeyName) {
    global Recording
    if (!Recording)
        return
    Critical()
    k := GetKeyName(vksc := SubStr(A_ThisHotkey, 3))
    k := StrReplace(k, "Control", "Ctrl"), r := SubStr(k, 2)
    if (r ~= "^(?i:Alt|Ctrl|Shift|Win)$")
        LogKey_Control(k)
    else if (k ~= "^(?i:LButton|RButton|MButton)$")
        LogKey_Mouse(k)
    else {
        if ((k = "NumpadLeft" || k = "NumpadRight") && !GetKeyState(k, "P"))
            return
        k := StrLen(k) > 1 ? "{" k "}" : k ~= "\w" ? k : "{" vksc "}"
        Log(k, 1)
    }
}

LogKey_Control(key) {
    global PendingMods
    k := InStr(key, "Win") ? key : SubStr(key, 2)
    PendingMods[k] := true
    Log("{" k " Down}", 1)
    Critical("Off")
    KeyWait(key)
    Critical()
    ; If the Down event was trimmed away (the chord turned out to be a control
    ; hotkey, not macro content) the matching Up must be dropped too.
    if !PendingMods.Has(k)
        return
    PendingMods.Delete(k)
    Log("{" k " Up}", 1)
}

LogKey_Mouse(key) {
    global LogArr, RelativeX, RelativeY, MouseMode
    k := SubStr(key, 1, 1)

    ; screen
    CoordMode("Mouse", "Screen")
    MouseGetPos(&X, &Y, &id)
    Log((MouseMode == "window" || MouseMode == "relative" ? ";" : "") "MouseClick(`"" k "`", " X ", " Y ",,, `"D`") `;screen")

    ; window
    CoordMode("Mouse", "Window")
    MouseGetPos(&WindowX, &WindowY, &id)
    Log((MouseMode != "window" ? ";" : "") "MouseClick(`"" k "`", " WindowX ", " WindowY ",,, `"D`") `;window")

    ; relative
    CoordMode("Mouse", "Screen")
    MouseGetPos(&tempRelativeX, &tempRelativeY, &id)
    Log((MouseMode != "relative" ? ";" : "") "MouseClick(`"" k "`", " (tempRelativeX - RelativeX) ", " (tempRelativeY - RelativeY) ",,, `"D`", `"R`") `;relative")
    RelativeX := tempRelativeX
    RelativeY := tempRelativeY

    ; drag detection
    CoordMode("Mouse", "Screen")
    MouseGetPos(&X1, &Y1)
    t1 := A_TickCount
    Critical("Off")
    KeyWait(key)
    Critical()
    t2 := A_TickCount
    if (t2 - t1 <= 200)
        X2 := X1, Y2 := Y1
    else
        MouseGetPos(&X2, &Y2)

    if (LogArr.Length < 3)
        return

    ; screen
    i := LogArr.Length - 2, r := LogArr[i]
    if (InStr(r, ",,, `"D`")") && Abs(X2 - X1) + Abs(Y2 - Y1) < 5)
        LogArr[i] := SubStr(r, 1, -16) ") `;screen", Log()
    else
        Log((MouseMode == "window" || MouseMode == "relative" ? ";" : "") "MouseClick(`"" k "`", " (X + X2 - X1) ", " (Y + Y2 - Y1) ",,, `"U`") `;screen")

    ; window
    i := LogArr.Length - 1, r := LogArr[i]
    if (InStr(r, ",,, `"D`")") && Abs(X2 - X1) + Abs(Y2 - Y1) < 5)
        LogArr[i] := SubStr(r, 1, -16) ") `;window", Log()
    else
        Log((MouseMode != "window" ? ";" : "") "MouseClick(`"" k "`", " (WindowX + X2 - X1) ", " (WindowY + Y2 - Y1) ",,, `"U`") `;window")

    ; relative
    i := LogArr.Length, r := LogArr[i]
    if (InStr(r, ",,, `"D`", `"R`")") && Abs(X2 - X1) + Abs(Y2 - Y1) < 5)
        LogArr[i] := SubStr(r, 1, -23) ",,,, `"R`") `;relative", Log()
    else
        Log((MouseMode != "relative" ? ";" : "") "MouseClick(`"" k "`", " (X2 - X1) ", " (Y2 - Y1) ",,, `"U`", `"R`") `;relative")
}

LogWindow() {
    global oldid, LogArr, MouseMode, Recording
    static oldtitle := ""
    if (!Recording)
        return
    id := WinExist("A")
    title := WinGetTitle()
    class := WinGetClass()
    if (title = "" && class = "")
        return
    if (id = oldid && title = oldtitle)
        return
    oldid := id, oldtitle := title
    title := SubStr(title, 1, 50)
    title .= class ? " ahk_class " class : ""
    title := RegExReplace(Trim(title), "[``%;]", "``$0")
    c := (MouseMode != "window") ? ";" : ""
    s := c "tt := `"" title "`"`n" c "WinWait(tt)`n" c "if (!WinActive(tt))`n" c "  WinActivate(tt)"
    i := LogArr.Length
    r := i = 0 ? "" : LogArr[i]
    if (RegExMatch(r, "^;?tt := "))
        LogArr[i] := s, Log()
    else
        Log(s)
}

Log(str := "", Keyboard := false) {
    global LogArr, RecordSleep, MinGap, Recording
    static LastTime := 0
    t := A_TickCount
    Delay := (LastTime ? t - LastTime : 0)
    LastTime := t
    if (str = "" || !Recording)
        return

    ; With sleep recording on, only merge true typing bursts so that deliberate
    ; pauses survive as Sleep() lines. With it off, keep the old 1s window.
    mergeWindow := RecordSleep ? MinGap : 1000

    i := LogArr.Length
    r := i = 0 ? "" : LogArr[i]
    if (Keyboard && InStr(r, "Send") && Delay < mergeWindow) {
        LogArr[i] := SubStr(r, 1, -1) . str "`""
        return
    }
    if (Delay > MinGap)
        LogArr.Push((RecordSleep ? "" : ";") "Sleep(Round(" Delay " / SPEED))")
    LogArr.Push(Keyboard ? "Send `"{Blind}" str "`"" : str)
}

; ============================================================================
; Macro file generation
; ============================================================================

WriteMacroFile(path, n, body) {
    global MouseMode, RecordSleep, Slots, PanicHotkey
    s := Slots[n]
    ts := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")

    out := "#Requires AutoHotkey v2.0`n"
    out .= "#SingleInstance Off`n"
    out .= ";=== Macro Recorder ===`n"
    out .= ";Name=" s.name "`n"
    out .= ";Slot=" n "`n"
    out .= ";Recorded=" ts "`n"
    out .= ";MouseMode=" MouseMode "`n"
    out .= ";RecordSleep=" (RecordSleep ? "true" : "false") "`n"
    out .= ";`n"
    out .= ";SPEED   playback rate: 2.0 = twice as fast, 0.5 = half speed`n"
    out .= ";REPEAT  how many times the macro runs`n"
    out .= "SPEED := " Format("{:.2f}", s.speed) "`n"
    out .= "REPEAT := " s.repeat "`n"
    out .= "if (SPEED <= 0)`n    SPEED := 1.0`n`n"
    out .= "SetKeyDelay(30)`n"
    out .= "SendMode(`"Event`")`n"
    out .= "SetTitleMatchMode(2)`n"
    if (MouseMode == "window")
        out .= ";CoordMode(`"Mouse`", `"Screen`")`nCoordMode(`"Mouse`", `"Window`")`n"
    else
        out .= "CoordMode(`"Mouse`", `"Screen`")`n;CoordMode(`"Mouse`", `"Window`")`n"

    out .= "`nLoop(REPEAT)`n{`n"
    for k, v in body
        out .= "`n" v "`n"
    out .= "`n}`nExitApp()`n`n"
    out .= PanicHotkey "::ExitApp()`n"

    out := RegExReplace(out, "\R", "`n")
    if (FileExist(path))
        FileDelete(path)
    FileAppend(out, path, "UTF-8")
}

SanitizeFileName(name) {
    n := RegExReplace(name, '[\\/:*?"<>|]', "_")
    n := Trim(n)
    return n = "" ? "Macro" : n
}

; Rewrite SPEED / REPEAT in place without re-recording.
ApplyMacroParams(path, speed, repeat) {
    if !FileExist(path)
        return
    txt := FileRead(path)
    txt := RegExReplace(txt, "m)^SPEED := .*$",  "SPEED := " Format("{:.2f}", speed))
    txt := RegExReplace(txt, "m)^REPEAT := .*$", "REPEAT := " repeat)
    FileDelete(path)
    FileAppend(txt, path, "UTF-8")
}

; ============================================================================
; Macro parsing (step viewer / step counting)
; ============================================================================

ReadMacroLines(path) {
    return StrSplit(FileRead(path), "`n", "`r")
}

ParseMacro(path) {
    steps := []
    if !FileExist(path)
        return steps
    lines := ReadMacroLines(path)
    i := 0
    while (++i <= lines.Length) {
        t := Trim(lines[i])
        disabled := false
        if (SubStr(t, 1, 1) = ";") {
            body := Trim(SubStr(t, 2))
            if !RegExMatch(body, "^(Sleep\(|MouseClick\(|Send |tt := )")
                continue
            disabled := true
            t := body
        }
        if (t = "")
            continue

        if (RegExMatch(t, "^Sleep\(Round\((\d+)\s*/\s*SPEED\)\)", &m)
         || RegExMatch(t, "^Sleep\((\d+)\)", &m)) {
            steps.Push({first: i, last: i, type: "Wait", ms: Integer(m[1]),
                        text: m[1] " ms", disabled: disabled})
        } else if (RegExMatch(t, "^Send `"(.*)`"$", &m)) {
            steps.Push({first: i, last: i, type: "Keys", ms: 0,
                        text: StrReplace(m[1], "{Blind}", ""), disabled: disabled})
        } else if (RegExMatch(t, "^MouseClick\((.*)$", &m)) {
            steps.Push({first: i, last: i, type: "Mouse", ms: 0,
                        text: RegExReplace(t, "^MouseClick\(|\)\s*;.*$", ""), disabled: disabled})
        } else if (RegExMatch(t, "^tt := `"(.*)`"$", &m)) {
            last := i, j := i
            while (j + 1 <= lines.Length) {
                nxt := Trim(lines[j + 1])
                nb := (SubStr(nxt, 1, 1) = ";") ? Trim(SubStr(nxt, 2)) : nxt
                if RegExMatch(nb, "^(WinWait\(|if \(!WinActive|WinActivate\()")
                    last := ++j
                else
                    break
            }
            steps.Push({first: i, last: last, type: "Window", ms: 0,
                        text: m[1], disabled: disabled})
            i := j
        }
    }
    return steps
}

CountSteps(path) {
    return ParseMacro(path).Length
}

MacroDuration(path) {
    ms := 0
    for st in ParseMacro(path)
        if (st.type = "Wait" && !st.disabled)
            ms += st.ms
    return ms
}

WriteMacroLines(path, lines) {
    txt := ""
    for i, l in lines
        txt .= (i = 1 ? "" : "`n") l
    FileDelete(path)
    FileAppend(txt, path, "UTF-8")
}

; ============================================================================
; Playback
; ============================================================================

PlaySlot(n) {
    global Playing, PlayPid, PlayingSlot, Slots, Recording, SuspendMaster

    if (Recording)
        StopRecording(true)
    if (Playing)
        StopPlayback()

    path := SlotPath(n)
    if (path = "" || !FileExist(path)) {
        ShowTip("SLOT " n " EMPTY")
        SetTimer(() => ShowTip(), -1200)
        return
    }
    if !FileExist(A_AhkPath) {
        MsgBox("Can't find AutoHotkey at " A_AhkPath, "Macro Recorder", 4096)
        return
    }

    if (SuspendMaster)
        SuspendMasterScript(true)

    pid := 0
    try {
        if (A_IsCompiled)
            Run(A_AhkPath ' /script /restart "' path '"', , , &pid)
        else
            Run(A_AhkPath ' /restart "' path '"', , , &pid)
    } catch as e {
        if (SuspendMaster)
            SuspendMasterScript(false)
        MsgBox("Could not start playback:`n" e.Message, "Macro Recorder", 4096)
        return
    }

    Playing := true
    PlayPid := pid
    PlayingSlot := n
    Slots[n].lastRun := FormatTime(A_Now, "yyyy-MM-dd HH:mm")
    SaveSlot(n)
    SetTimer(WatchPlayback, 200)
    RefreshSlotList()
}

WatchPlayback() {
    global Playing, PlayPid
    if (PlayPid && ProcessExist(PlayPid))
        return
    SetTimer(WatchPlayback, 0)
    FinishPlayback()
}

StopPlayback() {
    global PlayPid
    if (PlayPid && ProcessExist(PlayPid))
        try ProcessClose(PlayPid)
    SetTimer(WatchPlayback, 0)
    FinishPlayback()
}

FinishPlayback() {
    global Playing, PlayPid, PlayingSlot, SuspendMaster
    Playing := false
    PlayPid := 0
    PlayingSlot := 0
    if (SuspendMaster)
        SuspendMasterScript(false)
    RefreshSlotList()
}

; Suspend / un-suspend ^^AHK_Unified_Master.ahk so replayed keystrokes don't
; re-trigger its remaps. 65305 = ID_FILE_SUSPEND (a toggle).
SuspendMasterScript(on) {
    global MasterPath, MasterWasSuspended
    if (on = MasterWasSuspended)
        return
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    if (hWnd := WinExist(MasterPath " ahk_class AutoHotkey")) {
        PostMessage(0x111, 65305, 0, , "ahk_id " hWnd)
        MasterWasSuspended := on
    }
}

; ============================================================================
; Main GUI
; ============================================================================

ToggleMacroGui() {
    global MacroGui
    if (MacroGui && DllCall("IsWindowVisible", "Ptr", MacroGui.Hwnd))
        MacroGui.Hide()
    else
        ShowMacroGui()
}

ShowMacroGui() {
    global MacroGui, SlotLV, StatusText

    if (MacroGui) {
        RefreshSlotList()
        MacroGui.Show()
        return
    }

    MacroGui := Gui("", "Macro Recorder")
    MacroGui.SetFont("s9", "Segoe UI")
    MacroGui.MarginX := 10
    MacroGui.MarginY := 10

    SlotLV := MacroGui.Add("ListView", "w700 r12 -Multi Grid",
        ["#", "Name", "Play", "Record", "Steps", "Time", "Speed", "Repeat", "Last run"])
    SlotLV.OnEvent("DoubleClick", (*) => GuiPlay())

    ; Row 1 — transport
    MacroGui.Add("Button", "xm y+8 w90", "Record").OnEvent("Click", (*) => GuiRecord())
    MacroGui.Add("Button", "x+5 yp w90", "Play").OnEvent("Click", (*) => GuiPlay())
    MacroGui.Add("Button", "x+5 yp w90", "Stop/Cancel").OnEvent("Click", (*) => PanicStop())
    MacroGui.Add("Button", "x+5 yp w90", "Steps…").OnEvent("Click", (*) => ShowStepGui())
    MacroGui.Add("Button", "x+5 yp w90", "Speed…").OnEvent("Click", (*) => GuiSpeed())
    MacroGui.Add("Button", "x+5 yp w90", "Repeat…").OnEvent("Click", (*) => GuiRepeat())
    MacroGui.Add("Button", "x+5 yp w90", "Rename…").OnEvent("Click", (*) => GuiRename())

    ; Row 2 — library
    MacroGui.Add("Button", "xm y+5 w90", "Save As…").OnEvent("Click", (*) => GuiSaveAs())
    MacroGui.Add("Button", "x+5 yp w90", "Load…").OnEvent("Click", (*) => GuiLoad())
    MacroGui.Add("Button", "x+5 yp w90", "Duplicate").OnEvent("Click", (*) => GuiDuplicate())
    MacroGui.Add("Button", "x+5 yp w90", "Clear slot").OnEvent("Click", (*) => GuiClear())
    MacroGui.Add("Button", "x+5 yp w90", "Edit file").OnEvent("Click", (*) => GuiEdit())
    MacroGui.Add("Button", "x+5 yp w90", "Settings…").OnEvent("Click", (*) => ShowSettingsGui())
    MacroGui.Add("Button", "x+5 yp w90", "Folder").OnEvent("Click", (*) => Run('explorer.exe "' MacroDir '"'))

    StatusText := MacroGui.Add("Text", "xm y+10 w700", "")

    MacroGui.OnEvent("Close", (*) => MacroGui.Hide())
    MacroGui.OnEvent("Escape", (*) => MacroGui.Hide())

    RefreshSlotList()
    MacroGui.Show(GuiSize(720, 380))
}

RefreshSlotList() {
    global SlotLV, Slots, SlotCount, SlotKeys, PlayPrefix, RecordPrefix
    if (!SlotLV)
        return
    sel := SlotLV.GetNext()
    SlotLV.Delete()
    Loop SlotCount {
        n := A_Index
        s := Slots[n]
        key := SlotKeys.Has(n) ? SlotKeys[n] : ""
        filled := SlotFilled(n)
        name := filled ? s.name : "— empty —"
        dur := filled ? Round(MacroDuration(SlotPath(n)) / 1000, 1) "s" : ""
        SlotLV.Add(, n, name,
            (filled && key != "") ? PrettyHotkey(PlayPrefix key) : "",
            (key != "") ? PrettyHotkey(RecordPrefix key) : "",
            filled ? s.steps : "",
            dur,
            filled ? Format("{:.2f}", s.speed) : "",
            filled ? s.repeat : "",
            s.lastRun)
    }
    Loop 9
        SlotLV.ModifyCol(A_Index, "AutoHdr")
    if (sel)
        SlotLV.Modify(sel, "Select Focus")

    st := Recording ? "Recording into slot " RecordSlot " — press the record hotkey again to stop"
        : Playing   ? "Playing slot " PlayingSlot
        : "Ready.  " PrettyHotkey(GuiHotkey) " toggles this window · " PrettyHotkey(PanicHotkey) " stops everything"
    SetStatus(st)
}

; "#!+F1" -> "Win+Alt+Shift+F1"
PrettyHotkey(hk) {
    mods := "", i := 1
    while (i <= StrLen(hk)) {
        c := SubStr(hk, i, 1)
        if (c = "#")
            mods .= "Win+"
        else if (c = "!")
            mods .= "Alt+"
        else if (c = "^")
            mods .= "Ctrl+"
        else if (c = "+")
            mods .= "Shift+"
        else if (c != "<" && c != ">" && c != "*" && c != "~" && c != "$")
            break
        i++
    }
    key := SubStr(hk, i)
    return mods (StrLen(key) = 1 ? StrUpper(key) : key)
}

SelectedSlot() {
    global SlotLV
    if (!SlotLV)
        return 0
    row := SlotLV.GetNext()
    if (!row) {
        MsgBox("Select a slot first.", "Macro Recorder", 4096)
        return 0
    }
    return Integer(SlotLV.GetText(row, 1))
}

GuiRecord() {
    if (n := SelectedSlot())
        StartRecording(n)
}

GuiPlay() {
    if (n := SelectedSlot())
        PlaySlot(n)
}

GuiRename() {
    global Slots
    if !(n := SelectedSlot())
        return
    ib := InputBox("Name for slot " n ":", "Rename", "w320 h130", Slots[n].name)
    if (ib.Result != "OK" || Trim(ib.Value) = "")
        return
    Slots[n].name := Trim(ib.Value)
    if (SlotFilled(n)) {
        old := SlotPath(n)
        newFile := SanitizeFileName(Slots[n].name) ".ahk"
        newPath := MacroDir "\" newFile
        if (newPath != old) {
            if FileExist(newPath) {
                MsgBox("A macro file named `"" newFile "`" already exists.", "Macro Recorder", 4096)
            } else {
                try {
                    FileMove(old, newPath)
                    Slots[n].file := newFile
                }
            }
        }
        SyncMacroHeaderName(SlotPath(n), Slots[n].name)
    }
    SaveSlot(n)
    RefreshSlotList()
}

SyncMacroHeaderName(path, name) {
    if !FileExist(path)
        return
    txt := FileRead(path)
    txt := RegExReplace(txt, "m)^;Name=.*$", ";Name=" name)
    FileDelete(path)
    FileAppend(txt, path, "UTF-8")
}

GuiSpeed() {
    global Slots
    if !(n := SelectedSlot())
        return
    if !SlotFilled(n) {
        MsgBox("Slot " n " is empty.", "Macro Recorder", 4096)
        return
    }
    ib := InputBox("Playback speed for `"" Slots[n].name "`"`n(2.0 = twice as fast, 0.5 = half speed)",
                   "Speed", "w320 h150", Format("{:.2f}", Slots[n].speed))
    if (ib.Result != "OK" || !IsNumber(ib.Value) || Number(ib.Value) <= 0)
        return
    Slots[n].speed := Number(ib.Value)
    ApplyMacroParams(SlotPath(n), Slots[n].speed, Slots[n].repeat)
    SaveSlot(n)
    RefreshSlotList()
}

GuiRepeat() {
    global Slots
    if !(n := SelectedSlot())
        return
    if !SlotFilled(n) {
        MsgBox("Slot " n " is empty.", "Macro Recorder", 4096)
        return
    }
    ib := InputBox("How many times should `"" Slots[n].name "`" run?", "Repeat", "w320 h140", Slots[n].repeat)
    if (ib.Result != "OK" || !IsInteger(ib.Value) || Integer(ib.Value) < 1)
        return
    Slots[n].repeat := Integer(ib.Value)
    ApplyMacroParams(SlotPath(n), Slots[n].speed, Slots[n].repeat)
    SaveSlot(n)
    RefreshSlotList()
}

GuiSaveAs() {
    global Slots
    if !(n := SelectedSlot())
        return
    if !SlotFilled(n) {
        MsgBox("Slot " n " is empty.", "Macro Recorder", 4096)
        return
    }
    sel := FileSelect("S24", MacroDir "\" Slots[n].name ".ahk", "Save macro as", "AutoHotkey (*.ahk)")
    if (sel = "")
        return
    if !(sel ~= "i)\.ahk$")
        sel .= ".ahk"
    try {
        FileCopy(SlotPath(n), sel, true)
        SetStatus("Saved to " sel)
    } catch as e {
        MsgBox("Could not save:`n" e.Message, "Macro Recorder", 4096)
    }
}

GuiLoad() {
    global Slots
    if !(n := SelectedSlot())
        return
    if (SlotFilled(n)) {
        if (MsgBox("Slot " n " already holds `"" Slots[n].name "`".`n`nReplace it?",
                   "Macro Recorder", "YesNo Icon! 4096") != "Yes")
            return
    }
    sel := FileSelect(1, MacroDir, "Load macro into slot " n, "AutoHotkey (*.ahk)")
    if (sel = "")
        return
    SplitPath(sel, &fname, , , &base)
    dest := MacroDir "\" fname
    try {
        if (sel != dest)
            FileCopy(sel, dest, true)
        UpgradeMacroFile(dest)
        Slots[n].file  := fname
        Slots[n].name  := base
        Slots[n].steps := CountSteps(dest)
        Slots[n].speed := ReadMacroNumber(dest, "SPEED", 1.0)
        Slots[n].repeat := Integer(ReadMacroNumber(dest, "REPEAT", 1))
        SaveSlot(n)
        BindSlotHotkeys()
        RefreshSlotList()
    } catch as e {
        MsgBox("Could not load:`n" e.Message, "Macro Recorder", 4096)
    }
}

ReadMacroNumber(path, varName, default) {
    if !FileExist(path)
        return default
    if RegExMatch(FileRead(path), "m)^" varName " := ([\d.]+)", &m)
        return Number(m[1])
    return default
}

GuiDuplicate() {
    global Slots, SlotCount
    if !(n := SelectedSlot())
        return
    if !SlotFilled(n) {
        MsgBox("Slot " n " is empty.", "Macro Recorder", 4096)
        return
    }
    target := 0
    Loop SlotCount {
        if !SlotFilled(A_Index) {
            target := A_Index
            break
        }
    }
    if (!target) {
        MsgBox("No empty slot available.", "Macro Recorder", 4096)
        return
    }
    name := Slots[n].name " copy"
    file := SanitizeFileName(name) ".ahk"
    try {
        FileCopy(SlotPath(n), MacroDir "\" file, true)
        Slots[target].file   := file
        Slots[target].name   := name
        Slots[target].speed  := Slots[n].speed
        Slots[target].repeat := Slots[n].repeat
        Slots[target].steps  := Slots[n].steps
        Slots[target].lastRun := ""
        SyncMacroHeaderName(MacroDir "\" file, name)
        SaveSlot(target)
        BindSlotHotkeys()
        RefreshSlotList()
        SetStatus("Duplicated slot " n " into slot " target)
    } catch as e {
        MsgBox("Could not duplicate:`n" e.Message, "Macro Recorder", 4096)
    }
}

GuiClear() {
    global Slots
    if !(n := SelectedSlot())
        return
    if !SlotFilled(n)
        return
    r := MsgBox("Remove `"" Slots[n].name "`" from slot " n "?`n`n"
              . "Yes  = clear the slot and delete the file`n"
              . "No   = clear the slot, keep the file in the macros folder",
                "Macro Recorder", "YesNoCancel Icon? 4096")
    if (r = "Cancel")
        return
    if (r = "Yes") {
        try FileDelete(SlotPath(n))
    }
    Slots[n].file := "", Slots[n].name := "", Slots[n].steps := 0
    Slots[n].speed := 1.0, Slots[n].repeat := 1, Slots[n].lastRun := ""
    SaveSlot(n)
    BindSlotHotkeys()
    RefreshSlotList()
}

GuiEdit() {
    if !(n := SelectedSlot())
        return
    if !SlotFilled(n) {
        MsgBox("Slot " n " is empty.", "Macro Recorder", 4096)
        return
    }
    vscode := EnvGet("LocalAppData") "\Programs\Microsoft VS Code\Code.exe"
    try {
        if FileExist(vscode)
            Run('"' vscode '" "' SlotPath(n) '"')
        else
            Run('notepad.exe "' SlotPath(n) '"')
    } catch as e {
        MsgBox("Could not open the editor:`n" e.Message, "Macro Recorder", 4096)
    }
}

; ============================================================================
; Step viewer / editor
; ============================================================================

ShowStepGui() {
    global StepGui, StepLV, StepSlot
    if !(n := SelectedSlot())
        return
    if !SlotFilled(n) {
        MsgBox("Slot " n " is empty.", "Macro Recorder", 4096)
        return
    }
    StepSlot := n

    if (StepGui) {
        RefreshStepList()
        StepGui.Show()
        return
    }

    StepGui := Gui("", "Macro steps")
    StepGui.SetFont("s9", "Segoe UI")
    StepLV := StepGui.Add("ListView", "w620 r16 -Multi Grid", ["#", "Type", "Detail", "Enabled"])
    StepLV.OnEvent("DoubleClick", (*) => StepEditDelay())

    StepGui.Add("Button", "xm y+8 w110", "Edit delay…").OnEvent("Click", (*) => StepEditDelay())
    StepGui.Add("Button", "x+5 yp w110", "Insert pause…").OnEvent("Click", (*) => StepInsertPause())
    StepGui.Add("Button", "x+5 yp w110", "Enable/Disable").OnEvent("Click", (*) => StepToggle())
    StepGui.Add("Button", "x+5 yp w110", "Delete step").OnEvent("Click", (*) => StepDelete())
    StepGui.Add("Button", "x+5 yp w110", "Close").OnEvent("Click", (*) => StepGui.Hide())

    StepGui.OnEvent("Close", (*) => StepGui.Hide())
    StepGui.OnEvent("Escape", (*) => StepGui.Hide())
    RefreshStepList()
    StepGui.Show(GuiSize(640, 425))
}

RefreshStepList() {
    global StepLV, StepCache, StepSlot, StepGui, Slots
    if (!StepLV)
        return
    path := SlotPath(StepSlot)
    StepCache := ParseMacro(path)
    StepLV.Delete()
    for i, st in StepCache
        StepLV.Add(, i, st.type, StrLen(st.text) > 90 ? SubStr(st.text, 1, 90) "…" : st.text,
                   st.disabled ? "no" : "yes")
    ; fixed widths: a long window title in Detail would otherwise push the
    ; Enabled column out of view
    StepLV.ModifyCol(1, 35)
    StepLV.ModifyCol(2, 65)
    StepLV.ModifyCol(3, 420)
    StepLV.ModifyCol(4, 65)
    try StepGui.Title := "Macro steps — " Slots[StepSlot].name
         . " (" StepCache.Length " steps, " Round(MacroDuration(path) / 1000, 1) "s of waits)"
}

SelectedStep() {
    global StepLV, StepCache
    row := StepLV.GetNext()
    if (!row) {
        MsgBox("Select a step first.", "Macro Recorder", 4096)
        return 0
    }
    return row
}

StepEditDelay() {
    global StepCache, StepSlot, Slots
    if !(row := SelectedStep())
        return
    st := StepCache[row]
    if (st.type != "Wait") {
        MsgBox("That step is not a delay. Use `"Insert pause`" to add one before it.",
               "Macro Recorder", 4096)
        return
    }
    ib := InputBox("Delay in milliseconds:", "Edit delay", "w280 h130", st.ms)
    if (ib.Result != "OK" || !IsInteger(ib.Value) || Integer(ib.Value) < 0)
        return
    path := SlotPath(StepSlot)
    lines := ReadMacroLines(path)
    prefix := st.disabled ? ";" : ""
    lines[st.first] := prefix "Sleep(Round(" Integer(ib.Value) " / SPEED))"
    WriteMacroLines(path, lines)
    AfterStepEdit()
}

StepInsertPause() {
    global StepCache, StepSlot, DefaultPause
    if !(row := SelectedStep())
        return
    ib := InputBox("Insert a pause before step " row ".`n`nLength in milliseconds:",
                   "Insert pause", "w300 h150", DefaultPause)
    if (ib.Result != "OK" || !IsInteger(ib.Value) || Integer(ib.Value) < 1)
        return
    path := SlotPath(StepSlot)
    lines := ReadMacroLines(path)
    lines.InsertAt(StepCache[row].first, "Sleep(Round(" Integer(ib.Value) " / SPEED))")
    WriteMacroLines(path, lines)
    AfterStepEdit()
}

StepToggle() {
    global StepCache, StepSlot
    if !(row := SelectedStep())
        return
    st := StepCache[row]
    path := SlotPath(StepSlot)
    lines := ReadMacroLines(path)
    Loop (st.last - st.first + 1) {
        idx := st.first + A_Index - 1
        l := lines[idx]
        if (st.disabled)
            lines[idx] := RegExReplace(l, "^(\s*);", "$1")
        else
            lines[idx] := ";" l
    }
    WriteMacroLines(path, lines)
    AfterStepEdit()
}

StepDelete() {
    global StepCache, StepSlot
    if !(row := SelectedStep())
        return
    if (MsgBox("Delete step " row "?", "Macro Recorder", "YesNo Icon? 4096") != "Yes")
        return
    st := StepCache[row]
    path := SlotPath(StepSlot)
    lines := ReadMacroLines(path)
    Loop (st.last - st.first + 1)
        lines.RemoveAt(st.first)
    WriteMacroLines(path, lines)
    AfterStepEdit()
}

AfterStepEdit() {
    global StepSlot, Slots
    Slots[StepSlot].steps := CountSteps(SlotPath(StepSlot))
    SaveSlot(StepSlot)
    RefreshStepList()
    RefreshSlotList()
}

; ============================================================================
; Settings GUI
; ============================================================================

ShowSettingsGui() {
    global CfgGui, MouseMode, RecordSleep, MinGap, DefaultPause, SuspendMaster
    global ShowGuiOnStart, PlayPrefix, RecordPrefix, GuiHotkey, PanicHotkey, PauseHotkey, SlotCount

    if (CfgGui) {
        CfgGui.Destroy()
        CfgGui := ""
    }

    CfgGui := Gui("", "Macro Recorder — Settings")
    CfgGui.SetFont("s9", "Segoe UI")
    CfgGui.MarginX := 12, CfgGui.MarginY := 12

    CfgGui.Add("Text", "xm w175", "Mouse coordinate mode")
    ddMouse := CfgGui.Add("DropDownList", "x+5 yp-3 w150 Choose" MouseModeIndex(),
                          ["screen", "window", "relative"])

    CfgGui.Add("Text", "xm y+12 w175", "Minimum gap to record (ms)")
    edGap := CfgGui.Add("Edit", "x+5 yp-3 w150 Number", MinGap)

    CfgGui.Add("Text", "xm y+12 w175", "Default manual pause (ms)")
    edPause := CfgGui.Add("Edit", "x+5 yp-3 w150 Number", DefaultPause)

    CfgGui.Add("Text", "xm y+12 w175", "Number of slots (1-12)")
    edSlots := CfgGui.Add("Edit", "x+5 yp-3 w150 Number", SlotCount)

    cbSleep  := CfgGui.Add("Checkbox", "xm y+14", "Record pauses between actions")
    cbSleep.Value := RecordSleep
    cbSusp   := CfgGui.Add("Checkbox", "xm y+6", "Suspend the master script during playback")
    cbSusp.Value := SuspendMaster
    cbStart  := CfgGui.Add("Checkbox", "xm y+6", "Show this window on launch")
    cbStart.Value := ShowGuiOnStart

    CfgGui.Add("Text", "xm y+16 w342 0x10")     ; horizontal rule
    CfgGui.Add("Text", "xm y+8", "Hotkeys — AHK notation:  # Win   ! Alt   ^ Ctrl   + Shift")

    CfgGui.Add("Text", "xm y+10 w175", "Play prefix + slot key")
    edPlay := CfgGui.Add("Edit", "x+5 yp-3 w150", PlayPrefix)

    CfgGui.Add("Text", "xm y+10 w175", "Record prefix + slot key")
    edRec := CfgGui.Add("Edit", "x+5 yp-3 w150", RecordPrefix)

    CfgGui.Add("Text", "xm y+10 w175", "Open this GUI")
    edGui := CfgGui.Add("Edit", "x+5 yp-3 w150", GuiHotkey)

    CfgGui.Add("Text", "xm y+10 w175", "Stop everything")
    edPanic := CfgGui.Add("Edit", "x+5 yp-3 w150", PanicHotkey)

    CfgGui.Add("Text", "xm y+10 w175", "Insert pause while recording")
    edPauseHk := CfgGui.Add("Edit", "x+5 yp-3 w150", PauseHotkey)

    CfgGui.Add("Button", "xm y+16 w168 Default", "Save").OnEvent("Click", SaveCfg)
    CfgGui.Add("Button", "x+5 yp w168", "Cancel").OnEvent("Click", (*) => CfgGui.Hide())
    CfgGui.OnEvent("Close", (*) => CfgGui.Hide())
    CfgGui.OnEvent("Escape", (*) => CfgGui.Hide())
    CfgGui.Show(GuiSize(366, 470))

    SaveCfg(*) {
        global MouseMode, RecordSleep, MinGap, DefaultPause, SuspendMaster, ShowGuiOnStart
        global PlayPrefix, RecordPrefix, GuiHotkey, PanicHotkey, PauseHotkey, SlotCount, SlotKeys

        MouseMode      := ddMouse.Text
        MinGap         := Max(1, Integer(edGap.Value))
        DefaultPause   := Max(1, Integer(edPause.Value))
        newSlots       := Min(12, Max(1, Integer(edSlots.Value)))
        RecordSleep    := cbSleep.Value ? true : false
        SuspendMaster  := cbSusp.Value ? true : false
        ShowGuiOnStart := cbStart.Value ? true : false
        PlayPrefix     := Trim(edPlay.Value)
        RecordPrefix   := Trim(edRec.Value)
        GuiHotkey      := Trim(edGui.Value)
        PanicHotkey    := Trim(edPanic.Value)
        PauseHotkey    := Trim(edPauseHk.Value)

        SlotCount := newSlots
        while (SlotKeys.Length < SlotCount)
            SlotKeys.Push("")
        SaveSettings()
        CfgGui.Hide()
        MsgBox("Settings saved. The script will reload to apply the hotkeys.",
               "Macro Recorder", 4096)
        Reload()
    }
}

; Gui.Show() sizes are physical pixels, but control coordinates are scaled by
; the system DPI. On a 125% display a "w700" ListView is really 875px wide, so
; window dimensions have to be scaled by hand or the lower/right controls get
; clipped. (AutoSize has the same blind spot.)
GuiSize(w, h) {
    return "w" Round(w * A_ScreenDPI / 96) " h" Round(h * A_ScreenDPI / 96)
}

MouseModeIndex() {
    global MouseMode
    return MouseMode = "window" ? 2 : MouseMode = "relative" ? 3 : 1
}
