#Requires AutoHotkey v2.0

; Hotkey: Win + Shift + n
#+n::
{
    path := GetActiveExplorerPath()
    if !path
    {
        MsgBox "No valid Explorer window detected."
        return
    }

    base := "New Text Document"
    ext  := ".txt"
    file := base ext
    i := 1

    ; Auto-increment if file exists
    while FileExist(path "\" file)
    {
        file := base " (" i ")" ext
        i++
    }

    ; Create the empty file
    FileAppend "", path "\" file

    ; Optional: Open immediately
    ; Run path "\" file

    ToolTip "Created: " file, 500, 500
    SetTimer () => ToolTip(), -1200
}

GetActiveExplorerPath() {
    winClass := WinGetClass("A")

    if (winClass = "CabinetWClass" or winClass = "ExploreWClass")
        return Explorer_GetPath()

    return ""
}

Explorer_GetPath() {
    try {
        Shell := ComObject("Shell.Application") ; AHK v2 correct COM call
    } catch {
        return ""
    }

    for window in Shell.Windows
    {
        try {
            if (window.hwnd = WinGetID("A"))
                return window.Document.Folder.Self.Path
        }
    }
    return ""
}
