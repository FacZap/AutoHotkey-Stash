#Requires AutoHotkey v2.0
#SingleInstance Force

; Ctrl+Alt+K -> GUI (or instant kill, depending on kill_preferences.ini) to kill Firefox/Chrome.
; Settings are read fresh from kill_preferences.ini every time the hotkey fires,
; so edits to the ini take effect without reloading the script.

IniPath := A_ScriptDir "\kill_preferences.ini"

ProcessNames := Map("Firefox", "firefox.exe", "Chrome", "chrome.exe")

^!k::KillBrowsers_Trigger()

KillBrowsers_Trigger() {
    order := KillBrowsers_ReadOrder()
    doNotOpenGUI := IniRead(IniPath, "Settings", "DoNotOpenGUI", 0)

    if (doNotOpenGUI = "1") {
        if (order.Length > 0)
            KillBrowsers_Kill(order[1])
        return
    }

    KillBrowsers_ShowGUI(order)
}

KillBrowsers_ReadOrder() {
    global ProcessNames
    raw := IniRead(IniPath, "Settings", "Order", "Firefox,Chrome")
    order := []
    for name in StrSplit(raw, ",") {
        name := Trim(name)
        if ProcessNames.Has(name)
            order.Push(name)
    }
    ; Fall back to default order if the ini entry was empty/invalid
    if (order.Length = 0)
        order := ["Firefox", "Chrome"]
    return order
}

KillBrowsers_ShowGUI(order) {
    closeAfter := IniRead(IniPath, "Settings", "CloseGUIAfterPress", 1)

    myGui := Gui("+AlwaysOnTop", "Kill Browsers")
    myGui.SetFont("s10")
    myGui.MarginX := 15
    myGui.MarginY := 15

    firstControl := ""
    for name in order {
        opts := (A_Index = 1) ? "w160 Default" : "w160"
        btn := myGui.Add("Button", opts, "Kill " name)
        btn.OnEvent("Click", KillBrowsers_MakeHandler(name, myGui, closeAfter))
        if (A_Index = 1)
            firstControl := btn
    }

    exitBtn := myGui.Add("Button", "w160", "Exit")
    exitBtn.OnEvent("Click", (*) => myGui.Destroy())

    myGui.OnEvent("Escape", (*) => myGui.Destroy())
    myGui.OnEvent("Close", (*) => myGui.Destroy())

    myGui.Show()
    if firstControl
        firstControl.Focus()
}

KillBrowsers_MakeHandler(name, myGui, closeAfter) {
    return (*) => KillBrowsers_OnButtonPress(name, myGui, closeAfter)
}

KillBrowsers_OnButtonPress(name, myGui, closeAfter) {
    KillBrowsers_Kill(name)
    if (closeAfter = "1")
        myGui.Destroy()
}

KillBrowsers_Kill(name) {
    global ProcessNames
    exeName := ProcessNames[name]
    if ProcessExist(exeName)
        ProcessClose(exeName)
}
