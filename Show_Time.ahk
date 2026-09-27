#Requires AutoHotkey v2.0
#SingleInstance Force

; Win+C (sostenido) = reloj flotante hh:mm:ss; se cierra al soltar Win o C.
#c::  ; Win + C
{
    clockGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    clockGui.BackColor := "1E1E1E"
    clockGui.MarginX := 24
    clockGui.MarginY := 12
    clockGui.SetFont("s36 bold cFFFFFF", "Consolas")
    txt := clockGui.Add("Text", "Center", FormatTime(, "HH:mm:ss"))
    clockGui.Show("Hide AutoSize")
    clockGui.GetPos(, , &w, &h)
    MonitorGetWorkArea(MonitorGetPrimary(), &l, &t, &r, &b)
    clockGui.Show("NoActivate x" (l + (r - l - w) // 2) " y" (t + (b - t - h) // 2))
    last := ""
    while (GetKeyState("c", "P") && (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))) {
        now := FormatTime(, "HH:mm:ss")
        if (now != last) {
            txt.Value := now
            last := now
        }
        Sleep 30
    }
    clockGui.Destroy()
}
