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

Refresh() {
    DetectHiddenWindows(true)
    scriptList := []
    for script in WinGetList("ahk_class AutoHotkey") {
        try {
            title := WinGetTitle("ahk_id " script)
            SplitPath(title, &scriptName)
            if !(scriptName ~= "\.exe$") {
                state := "[Running]"
                text := WinGetText("ahk_id " script)
                style := WinGetStyle("ahk_id " script)

                if InStr(text, "Paused") {
                    state := "[Paused]"
                } else if (style & 0x20000000) {  ; WS_DISABLED = 0x20000000
                    state := "[Suspended]"
                }

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
        SendAHKMessage(scriptInfo.path, 65400)
    }
    Refresh()
}

SuspendScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        SendAHKMessage(scriptInfo.path, 65404)
    }
    Refresh()
}

PauseScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        SendAHKMessage(scriptInfo.path, 65403)
    }
    Refresh()
}

ExitScript() {
    if (scriptInfo := GetSelectedScriptInfo()) {
        SendAHKMessage(scriptInfo.path, 65405)
    }
    Refresh()
}

ManageAllScripts(action) {
    DetectHiddenWindows(true)
    for script in WinGetList("ahk_class AutoHotkey") {
        winTitle := WinGetTitle("ahk_id " script)
        scriptPath := RegExReplace(winTitle, " - AutoHotkey v[^\s]+$")
        if (A_ScriptFullPath != scriptPath) {
            switch action {
                case "Reload": SendAHKMessage(scriptPath, 65400)
                case "Suspend": SendAHKMessage(scriptPath, 65404)
                case "Pause": SendAHKMessage(scriptPath, 65403)
                case "Kill": SendAHKMessage(scriptPath, 65405)
            }
        }
    }
    DetectHiddenWindows(false)
    Refresh()
}
