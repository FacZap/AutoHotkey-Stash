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

; ——————————————————————————————————————————————————————————————
; TITLE: center it horizontally by giving it the full 460 width and using “Center”
; ——————————————————————————————————————————————————————————————
MyGui.Add(
    "Text",
    "x0 y3 w460 h30 Center cc47cff", 
    "Running AHK Scripts:"
).SetFont("s13 Bold", "Calibri")

; We still want the “List Refresh:” label on the right; its X can stay roughly the same.
MyGui.Add(
    "Text",
    "x350 y3 w120 h30 cffffff",
    "List Refresh:"
).SetFont("s11", "Calibri")

iconPath   := "C:\Windows\System32\Shell32.dll"
iconNumber := 239

; Icon on the top right—no change here.
icon := MyGui.Add(
    "Picture",
    "x436 y5 w20 h20 Icon" . iconNumber,
    iconPath
).OnEvent("Click", (*) => Refresh())

; ——————————————————————————————————————————————————————————————
; LISTBOX: center by moving X from 5 → 55 (since window width is 460 and ListBox width is 350)
; ——————————————————————————————————————————————————————————————
Scripts := MyGui.Add(
    "ListBox",
    "x55 y35 w350 h200 vScriptList Background313131 cFFFFFF"
)
Scripts.SetFont("s9.5")

; Helper to place buttons (unchanged)
AddButton(x, y, w, text, callback) {
    btn := MyGui.AddButton(x " " y " " w, text)
    btn.OnEvent("Click", callback)
    btn.SetFont("s10")
    return btn
}

; --------------------------------------------------------------------------------
; BUTTON LAYOUT (four columns per row). No changes needed here—only the title & list were re‐positioned.
; --------------------------------------------------------------------------------

; == ROW 1 (Manage *All* Scripts) ==
AddButton("x35", "y+m", "w90",   "Reload All",  (*) => ManageAllScripts("Reload"))
AddButton("x+m", "yp", "wp",     "Suspend All", (*) => ManageAllScripts("Suspend"))
AddButton("x+m", "yp", "wp",     "Pause All",   (*) => PauseAllScripts())
AddButton("x+m", "yp", "wp",     "Kill All",    (*) => ManageAllScripts("Kill"))

; == ROW 2 (Manage *Selected* Script) ==
AddButton("x35", "y+m", "wp",    "Reload",       (*) => ReloadScript())
AddButton("x+m", "yp", "wp",     "Suspend",      (*) => SuspendScript())
AddButton("x+m", "yp", "wp",     "Pause Script", (*) => PauseScript())
AddButton("x+m", "yp", "wp",     "Kill",         (*) => ExitScript())

; == ROW 3 (Misc / Utility) ==
AddButton("x35", "y+m", "WP",    "Select - Edit", (*) => EditScript())
AddButton("x+m", "yp", "wp",     "Open Folder",   (*) => Run('explorer "C:\Users\fzpat\Desktop\ahk"'))
AddButton("x+m", "yp", "wp",     "GUI Reload",    (*) => Reload())
AddButton("x+m", "yP", "wp",     "Quit",          (*) => ExitApp())

MyGui.Show("w460 h330")
Refresh()

; --------------------------------------------------------------------------------
; FUNCTIONS (unchanged from before, except for adding PauseScript() and PauseAllScripts())
; --------------------------------------------------------------------------------
Refresh() {
    DetectHiddenWindows(true)
    scriptList := []
    for script in WinGetList("ahk_class AutoHotkey") {
        title := WinGetTitle("ahk_id " script)
        SplitPath(title, &scriptName)
        if !(scriptName ~= "\.exe$") {
            scriptList.Push(scriptName " (" script ")")
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

SendAHKMessage(scriptPath, message) {
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    if (hWnd := WinExist(scriptPath " ahk_class AutoHotkey")) {
        PostMessage(0x111, message, 0,, "ahk_id " hWnd)
        return true
    }
    return false
}

ReloadScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        SendAHKMessage(scriptInfo.path, 65400)  ; WM_COMMAND – Reload
    }
    Refresh()
}

SuspendScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        SendAHKMessage(scriptInfo.path, 65404)  ; WM_COMMAND – Suspend/Unsuspend
    }
    Refresh()
}

PauseScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        SendAHKMessage(scriptInfo.path, 65403)  ; WM_COMMAND – Pause/Unpause
    }
    Refresh()
}

ExitScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        SendAHKMessage(scriptInfo.path, 65405)  ; WM_COMMAND – Exit
    }
    Refresh()
}

PauseAllScripts() {
    DetectHiddenWindows(true)
    for script in WinGetList("ahk_class AutoHotkey") {
        winTitle := WinGetTitle("ahk_id " script)
        scriptPath := RegExReplace(winTitle, " - AutoHotkey v[^\s]+$")
        if (A_ScriptFullPath != scriptPath) {
            SendAHKMessage(scriptPath, 65403)  ; Pause each script
        }
    }
    DetectHiddenWindows(false)
    Refresh()
}

ManageAllScripts(action) {
    DetectHiddenWindows(true)
    for script in WinGetList("ahk_class AutoHotkey") {
        winTitle := WinGetTitle("ahk_id " script)
        scriptPath := RegExReplace(winTitle, " - AutoHotkey v[^\s]+$")
        if (A_ScriptFullPath != scriptPath) {
            switch action {
                case "Reload":  SendAHKMessage(scriptPath, 65400)
                case "Suspend": SendAHKMessage(scriptPath, 65404)
                case "Kill":    SendAHKMessage(scriptPath, 65405)
            }
        }
    }
    DetectHiddenWindows(false)
    Refresh()
}
