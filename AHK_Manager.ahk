#Requires AutoHotkey v2.0.18+
#SingleInstance Force
TraySetIcon "C:\Windows\System32\Shell32.dll", 245
~Escape::ExitApp
~!Space::Reload

VSCodePath := "C:\Users\" A_UserName "\AppData\Local\Programs\Microsoft VS Code\Code.exe"
TraySetIcon "C:\Windows\System32\Shell32.dll", 245

; GUI Setup
MyGui := Gui()
MyGui.Title := "AHK Manager"
MyGui.BackColor := "313131"
MyGui.Add("Text", "x5 y3 w290 h50 cc47cff", "Running AHK Scripts:").SetFont("s13 Bold", "Calibri")
MyGui.Add("Text", "x265 y3 w120 h50 cffffff", "List Refresh:").SetFont("s11", "Calibri")

iconPath := "C:\Windows\System32\Shell32.dll"
iconNumber := 239
icon := MyGui.Add("Picture", "x347 y3 w20 h20 Icon" . iconNumber, iconPath).OnEvent("Click", (*) => Refresh())

Scripts := MyGui.Add("ListBox", "x5 y25 w365 h200 vScriptList Background313131 cFFFFFF")
Scripts.SetFont("s9.5")

; Add buttons function
AddButton(x, y, w, text, callback) {
    btn := MyGui.AddButton(x " " y " " w, text)
    btn.OnEvent("Click", callback)
    btn.SetFont("s10")
    return btn
}

; Row 1
AddButton("x10", "y+5", "w85", "Reload All", (*) => ManageAllScripts("Reload"))
AddButton("x+5", "yp", "w85", "Suspend All", (*) => ManageAllScripts("Suspend"))
AddButton("x+5", "yp", "w85", "Pause All", (*) => ManageAllScripts("Pause"))
AddButton("x+5", "yp", "w85", "Kill All", (*) => ManageAllScripts("Kill"))

; Row 2
AddButton("x10", "y+5", "w85", "Reload", (*) => ReloadScript())
AddButton("x+5", "yp", "w85", "Suspend", (*) => SuspendScript())
AddButton("x+5", "yp", "w85", "Pause Script", (*) => PauseScript())
AddButton("x+5", "yp", "w85", "Kill", (*) => ExitScript())

; Row 3
AddButton("x10", "y+5", "w85", "Select - Edit", (*) => EditScript())
AddButton("x+5", "yp", "w85", "Open Folder", (*) => Run("explorer.exe 'C:\autohotkey'"))
AddButton("x+5", "yp", "w85", "GUI Reload", (*) => Reload())
AddButton("x+5", "yp", "w85", "Quit", (*) => ExitApp())

; Row 4
AddButton("x103", "y+5", "w170", "Macro Recorder", (*) => OpenMacroRecorder())

MyGui.Show("w375 h365")
Refresh()

; AutoHotkey publishes exactly one piece of run state to other processes: while
; a script is suspended, the "Suspend Hotkeys" item in its own File menu carries
; a check mark. This holds for both v1 and v2 scripts.
IsSuspended(hWnd) {
    static ID_FILE_SUSPEND := 65404, MF_BYCOMMAND := 0, MF_CHECKED := 0x8
    if !(hMenu := DllCall("GetMenu", "Ptr", hWnd, "Ptr"))
        return false
    state := DllCall("GetMenuState", "Ptr", hMenu, "UInt", ID_FILE_SUSPEND, "UInt", MF_BYCOMMAND, "UInt")
    return (state != 0xFFFFFFFF) && (state & MF_CHECKED)
}

; Pause has no such indicator - AutoHotkey ticks it on the tray menu only, and
; another process cannot read that menu - so the Manager remembers which scripts
; it paused itself. Keyed by window handle, which changes when a script is
; reloaded or restarted (both of which start it unpaused); PrunePaused() drops
; handles that are gone. A script paused from its own tray menu or by its own
; hotkey is invisible to us and still shows as [Running].
PausedScripts() {
    static paused := Map()
    return paused
}

IsPaused(hWnd) {
    return PausedScripts().Has(Integer(hWnd))
}

TogglePaused(hWnd) {
    paused := PausedScripts(), hWnd := Integer(hWnd)
    if paused.Has(hWnd)
        paused.Delete(hWnd)
    else
        paused[hWnd] := true
}

ClearPaused(hWnd) {
    paused := PausedScripts(), hWnd := Integer(hWnd)
    if paused.Has(hWnd)
        paused.Delete(hWnd)
}

PrunePaused() {
    paused := PausedScripts()
    DetectHiddenWindows(true)
    for hWnd in paused.Clone()
        if !WinExist("ahk_id " hWnd)
            paused.Delete(hWnd)
}

Refresh() {
    DetectHiddenWindows(true)
    PrunePaused()
    scriptList := []
    for script in WinGetList("ahk_class AutoHotkey") {
        try {
            title := WinGetTitle("ahk_id " script)
            SplitPath(title, &scriptName)
            if !(scriptName ~= "\.exe$") {
                paused := IsPaused(script)
                suspended := IsSuspended(script)

                if (paused && suspended)
                    state := "[Paused+Suspended]"
                else if (paused)
                    state := "[Paused]"
                else if (suspended)
                    state := "[Suspended]"
                else
                    state := "[Running]"

                scriptList.Push(scriptName " " state " (" script ")")
            }
        } catch {
            continue
        }
    }
    Scripts.Delete()
    Scripts.Add(scriptList)
    DetectHiddenWindows(false)
}

GetSelectedScriptInfo() {
    if (selectedItem := Scripts.Text) {
        scriptID := RegExReplace(selectedItem, ".*\((\d+)\).*", "$1")
        DetectHiddenWindows(true)
        winTitle := WinGetTitle("ahk_id " scriptID)
        DetectHiddenWindows(false)
        scriptPath := RegExReplace(winTitle, " - AutoHotkey v[^\s]+$")
        return { path: scriptPath, id: scriptID }
    }
    return false
}

OpenMacroRecorder() {
    macroRecorderPath := "C:\autohotkey\Macro.Recorder.exe"
    if FileExist(macroRecorderPath) {
        Run(macroRecorderPath)
    } else {
        MsgBox("Unable to find Macro.Recorder.exe at: " macroRecorderPath)
    }
}

EditScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        if FileExist(scriptInfo.path) {
            if FileExist(VSCodePath) {
                Run(VSCodePath ' "' scriptInfo.path '"')
            } else {
                MsgBox("VS Code not found at the specified path. Please update the VSCodePath variable.")
            }
        } else {
            MsgBox("Unable to find the script file at path: " scriptInfo.path)
        }
    } else {
        MsgBox("Please select a script to edit.")
    }
    Refresh()
}

; Actions target the exact window handle the list row was built from. Resolving
; by title instead (SetTitleMatchMode 2 + WinExist) returns the FIRST window
; whose title matches, so with two instances of one script running under
; #SingleInstance Off every action landed on instance #1: "Kill All" left the
; second one alive and "Pause All" toggled the first one twice.
PostToScript(hWnd, message) {
    DetectHiddenWindows(true)
    try {
        PostMessage(0x111, message, 0, , "ahk_id " hWnd)
    } catch {
        return false
    }
    return true
}

; Killing is asynchronous (PostMessage), so the script's window is still
; listed for a moment after the exit message is sent. Wait for it to go
; away before refreshing, otherwise the dead script reappears in the list.
WaitScriptClosed(hWnd, timeout := 3) {
    DetectHiddenWindows(true)
    WinWaitClose("ahk_id " hWnd, , timeout)
    DetectHiddenWindows(false)
}

ReloadScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        if PostToScript(scriptInfo.id, 65400)
            ClearPaused(scriptInfo.id)
    }
    Refresh()
}

SuspendScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        PostToScript(scriptInfo.id, 65404)
    }
    Refresh()
}

PauseScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        if PostToScript(scriptInfo.id, 65403)
            TogglePaused(scriptInfo.id)
    }
    Refresh()
}

ExitScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        if PostToScript(scriptInfo.id, 65405)
            WaitScriptClosed(scriptInfo.id)
    }
    Refresh()
}

ManageAllScripts(action) {
    DetectHiddenWindows(true)
    killed := []
    for script in WinGetList("ahk_class AutoHotkey") {
        winTitle := WinGetTitle("ahk_id " script)
        scriptPath := RegExReplace(winTitle, " - AutoHotkey v[^\s]+$")
        if (A_ScriptFullPath != scriptPath) {
            switch action {
                case "Reload":
                    if PostToScript(script, 65400)
                        ClearPaused(script)
                case "Suspend": PostToScript(script, 65404)
                case "Pause":
                    if PostToScript(script, 65403)
                        TogglePaused(script)
                case "Kill":
                    if PostToScript(script, 65405)
                        killed.Push(script)
            }
        }
    }
    for hWnd in killed
        WinWaitClose("ahk_id " hWnd, , 3)
    DetectHiddenWindows(false)
    Refresh()
}
