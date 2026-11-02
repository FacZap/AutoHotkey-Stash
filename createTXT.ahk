#Requires AutoHotkey v2.0
#SingleInstance Force

; Win + Shift + T: open create-file GUI
#+t::
{
    path := GetActiveExplorerPath()
    if !path {
        MsgBox "No valid Explorer window detected."
        return
    }

    ShowCreateFileGui(path)
}

; Win + Shift + Middle Click: quick-create .txt in active Explorer
#HotIf IsExplorerActive()
#+MButton::
{
    path := GetActiveExplorerPath()
    if !path {
        ToolTip "No valid Explorer folder detected.", 500, 500
        SetTimer () => ToolTip(), -1200
        return
    }

    file := CreateNewFile(path, "New Text Document", ".txt")

    if file {
        ToolTip "Created: " file, 500, 500
        SetTimer () => ToolTip(), -1200
    }
}
#HotIf


ShowCreateFileGui(path) {
    g := Gui("+AlwaysOnTop", "Create New File")
    g.SetFont("s10", "Segoe UI")

    g.AddText("xm ym", "Folder:")
    g.AddEdit("xm w420 ReadOnly", path)

    g.AddText("xm y+12", "File name:")
    nameEdit := g.AddEdit("xm w280", "New Document")

    g.AddText("x+10 yp+3", "Type:")
    extDDL := g.AddDropDownList("x+5 yp-3 w100", [".txt", ".md", ".json", ".py", ".ahk", ".bat", ".ps1"])
    extDDL.Value := 1

    timestampCheck := g.AddCheckbox("xm y+12", "Use timestamp as file name")
    openCheck := g.AddCheckbox("xm y+8", "Open file after creating")

    createBtn := g.AddButton("xm y+16 w100 Default", "Create")
    cancelBtn := g.AddButton("x+10 w100", "Cancel")

    createBtn.OnEvent("Click", (*) => Submit())
    cancelBtn.OnEvent("Click", (*) => g.Destroy())
    g.OnEvent("Close", (*) => g.Destroy())

    Submit() {
	ext := extDDL.Text
	name := nameEdit.Value

	if (name = "New Document" || name = "")
	{
	    defaults := Map(
        	".txt", "New Text Document",
	        ".md",  "New README",
       		".json","New data",
	        ".py",  "New Py script",
	        ".ahk", "New AHK script",
        	".bat", "New batch script",
        	".ps1", "New Powershell script"
    	)

    	if defaults.Has(ext)
        	name := defaults[ext]
	}

        if timestampCheck.Value {
            name := FormatTime(A_Now, "yyyy-MM-dd HH-mm-ss")
        }

        file := CreateNewFile(path, name, ext)

        if !file {
            MsgBox "Could not create file."
            return
        }

        fullPath := path "\" file

        if openCheck.Value {
            Run fullPath
        }

        ToolTip "Created: " file, 500, 500
        SetTimer () => ToolTip(), -1200

        g.Destroy()
    }

    g.Show()
}


CreateNewFile(path, baseName, ext) {
    baseName := SanitizeFileName(baseName)

    if !baseName {
        baseName := "New File"
    }

    if !DirExist(path) {
        return ""
    }

    file := baseName ext
    i := 1

    while FileExist(path "\" file) {
        file := baseName " (" i ")" ext
        i++
    }

    try {
        FileAppend "", path "\" file
    } catch {
        return ""
    }

    return file
}


SanitizeFileName(name) {
    name := Trim(name)

    ; Remove extension if user typed one manually.
    name := RegExReplace(name, "\.[^\.\\/:*?`"<>|]+$")

    ; Replace invalid Windows filename characters.
    name := RegExReplace(name, '[\\/:*?"<>|]', "-")

    ; Windows dislikes trailing spaces/dots.
    name := RegExReplace(name, "[\s\.]+$")

    return name
}


IsExplorerActive() {
    winClass := WinGetClass("A")
    return winClass = "CabinetWClass" || winClass = "ExploreWClass"
}


GetActiveExplorerPath() {
    if !IsExplorerActive() {
        return ""
    }

    return Explorer_GetPath()
}


Explorer_GetPath() {
    try {
        shell := ComObject("Shell.Application")
    } catch {
        return ""
    }

    activeHwnd := WinGetID("A")

    for window in shell.Windows {
        try {
            if window.hwnd = activeHwnd {
                path := window.Document.Folder.Self.Path

                ; Reject virtual locations like This PC, Quick Access, etc.
                if DirExist(path) {
                    return path
                }

                return ""
            }
        }
    }

    return ""
}