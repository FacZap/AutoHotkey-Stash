#Requires AutoHotkey v2.0.18+
#SingleInstance Force

IniFile := A_ScriptDir "\open-program-GUI.ini"

Programs := Map(
    "Paint", "C:\Windows\System32\mspaint.exe",
    "Notepad++", "C:\Program Files\Notepad++\notepad++.exe",
    "OBS", "C:\Program Files\obs-studio\bin\64bit\obs64.exe"
)

; Load any saved path overrides
for name, defaultPath in Programs
    Programs[name] := IniRead(IniFile, "Paths", name, defaultPath)

^#p::ShowGui()

ShowGui() {
    global Programs
    if WinExist("Open Program ahk_class AutoHotkey") {
        WinActivate
        return
    }

    MyGui := Gui(, "Open Program")
    MyGui.OnEvent("Close", (*) => MyGui.Destroy())
    MyGui.SetFont("s10")

    for name, path in Programs {
        MyGui.Add("Button", "x10 y+10 w150", name).OnEvent("Click", MakeLaunchHandler(name, MyGui))
        MyGui.Add("Button", "x+5 yp w80", "Edit path").OnEvent("Click", MakeEditHandler(name))
    }

    MyGui.Add("Button", "x10 y+15 w235", "Close").OnEvent("Click", (*) => MyGui.Destroy())

    MyGui.Show()
}

MakeLaunchHandler(name, gui) {
    return (*) => LaunchProgram(name, gui)
}

MakeEditHandler(name) {
    return (*) => EditPath(name)
}

LaunchProgram(name, gui) {
    global Programs
    path := Programs[name]
    if !FileExist(path) {
        MsgBox("Unable to find " name " at:`n" path)
        return
    }
    ; Lanzar con el directorio del .exe como working dir: algunos programas
    ; (OBS) buscan sus datos -locale, plugins- relativos al directorio actual.
    SplitPath(path, , &exeDir)
    try
        Run(path, exeDir)
    catch as err {
        MsgBox("Failed to launch " name ":`n" err.Message)
        return
    }
    gui.Destroy()
}

EditPath(name) {
    global Programs, IniFile
    result := InputBox("Path for " name ":", "Edit path", "w400 h130", Programs[name])
    if (result.Result = "OK" && result.Value != "") {
        Programs[name] := result.Value
        IniWrite(result.Value, IniFile, "Paths", name)
    }
}
