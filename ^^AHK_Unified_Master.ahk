#Requires AutoHotkey v2.0.18+
#SingleInstance Force
#UseHook
#Include UIA.ahk

; ============================================================================
;  AHK_Unified_Master.ahk
;  Generado automáticamente para reemplazar la cadena de inicio:
;     ^RUN_MANAGER.ahk  ->  AHK_Manager.ahk
;     ^RUN_starters.ahk ->  23 scripts individuales + RBTray.exe + Wise Reminder
;
;  Todo el contenido funcional de esos archivos vive aquí, reescrito a
;  sintaxis AutoHotkey v2 (varios originales estaban en sintaxis v1 y no
;  pueden coexistir con AHK_Manager.ahk, que requiere v2, dentro de un mismo
;  proceso). Los archivos originales NO fueron borrados ni modificados.
;
;  Cambios de comportamiento a tener en cuenta:
;   - Escape y Alt+Espacio (cerrar/recargar) del Manager ahora solo actúan
;     cuando la ventana del Manager está activa (antes era global porque
;     el Manager corría en su propio proceso).
;   - El botón "Quit" del Manager y la tecla Escape (con su ventana activa)
;     cierran TODO este script unificado (antes solo cerraban el Manager).
;   - Ctrl+Alt+R ahora muestra/reactiva la ventana del Manager en lugar de
;     lanzar un proceso nuevo.
; ============================================================================

TraySetIcon "C:\Windows\System32\Shell32.dll", 245

; ---- Variables globales usadas por distintos bloques ----
VSCodePath := "C:\Users\" A_UserName "\AppData\Local\Programs\Microsoft VS Code\Code.exe"

counter := 0
lastControlPress := 0

global gWindows := []
global gIndex := 0
global gListGuiVisible := false
global cyclerListGui := ""

clickX := 600
clickY := 40
clickXX := 500
clickYY := 150

; ---- idle_edit_v2: umbral de inactividad (0 = desactivado, por defecto) ----
global idleMinutes := 0
global idleThresholdMs := idleMinutes * 60 * 1000

; ============================================================================
; arrows-keystrokes.ahk
; ============================================================================
^!W::Send "{Up}"
^!S::Send "{Down}"
<^CapsLock::Send "{Enter}"   ; Ctrl izquierdo + Bloq Mayús -> Enter (anula el toggle de Mayús)

; ============================================================================
; autodate.ahk
; ============================================================================
:R*?:kddd::
{
    SendInput FormatTime(, "dd/MM/yy")
}
:R*?:ksss::
{
    SendInput FormatTime(, "dd/MM")
}
:R*?:knnn::
{
    SendInput FormatTime(, "dddd")
}
:R*?:kxxx::
{
    SendInput FormatTime(, "yyMMdd_HHmm")
}
:R*?:kaaa::
{
    SendInput FormatTime(, "yyMMdd")
}
:R*?:kjjd::
{
    SendInput FormatTime(, "dd-MM-yy")
}
:R*?:kyyy::
{
    SendInput FormatTime(, "dd-MM-yy HH:mm")
}
:R*?:khhh::
{
    SendInput FormatTime(, "HH:mm")
}

; ============================================================================
; backwards-slash.ahk
; ============================================================================
+NumpadDiv::
{
    Send "\"
}

; ============================================================================
; brightness.ahk
; ============================================================================
#,::
{
    AdjustScreenBrightness(-5)
}
#.::
{
    AdjustScreenBrightness(5)
}

AdjustScreenBrightness(step) {
    static service := "winmgmts:{impersonationLevel=impersonate}!\\.\root\WMI"
    monitors := ComObjGet(service).ExecQuery("SELECT * FROM WmiMonitorBrightness WHERE Active=TRUE")
    monMethods := ComObjGet(service).ExecQuery("SELECT * FROM wmiMonitorBrightNessMethods WHERE Active=TRUE")
    curr := 0
    for i in monitors {
        curr := i.CurrentBrightness
        break
    }
    toSet := curr + step
    if (toSet < 10)
        toSet := 10
    if (toSet > 100)
        toSet := 100
    for i in monMethods {
        i.WmiSetBrightness(1, toSet)
        break
    }
    BrightnessOSD()
}

BrightnessOSD() {
    static PostMessagePtr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", "PostMessageW", "Ptr")
    static WM_SHELLHOOK := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt")
    static FindWindowPtr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", "FindWindowW", "Ptr")
    HWND := DllCall(FindWindowPtr, "Str", "NativeHWNDHost", "Str", "", "Ptr")
    if !HWND {
        try {
            if (shellProvider := ComObject("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}")) {
                try {
                    if (flyoutDisp := ComObjQuery(shellProvider, "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}", "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}")) {
                        try {
                            ptr := ComObjValue(flyoutDisp)
                            vtable := NumGet(ptr, "Ptr")
                            fnPtr := NumGet(vtable + 3 * A_PtrSize, "Ptr")
                            DllCall(fnPtr, "Ptr", ptr, "Int", 0, "UInt", 0)
                        }
                        ObjRelease(flyoutDisp)
                    }
                }
                ObjRelease(shellProvider)
            }
        }
        HWND := DllCall(FindWindowPtr, "Str", "NativeHWNDHost", "Str", "", "Ptr")
    }
    DllCall(PostMessagePtr, "Ptr", HWND, "UInt", WM_SHELLHOOK, "Ptr", 0x37, "Ptr", 0)
}

; ============================================================================
; checkmark.ahk
; ============================================================================
!^F10::Send "{✔}"
!^F9::Send "{↑}"

; ============================================================================
; dashes.ahk
; ============================================================================
^NumpadSub::Send "{—}"
!NumpadSub::Send "{–}"

; ============================================================================
; calendar.ahk
; ============================================================================
#Numpad5::ShowCalendarGui()

ShowCalendarGui() {
    cg := Gui("+AlwaysOnTop +ToolWindow", "Calendario")
    cg.BackColor := "FFFFFF"
    cg.SetFont("s10", "Segoe UI")
    cg.Add("Text", "x10 y10 w290 Center", "Selecciona una fecha")
    mc := cg.Add("MonthCal", "x10 y35 vFechaSeleccionada")
    btnCopiar := cg.Add("Button", "x10 y210 w140 Default", "Copiar  (Enter)")
    btnCopiar.OnEvent("Click", (*) => CopiarFechaCal(cg, mc))
    btnCancelar := cg.Add("Button", "x160 y210 w140", "Cancelar  (Esc)")
    btnCancelar.OnEvent("Click", (*) => cg.Destroy())
    cg.OnEvent("Close", (*) => cg.Destroy())
    cg.OnEvent("Escape", (*) => cg.Destroy())
    cg.Show("w310")
}

CopiarFechaCal(cg, mc) {
    Fecha := FormatTime(mc.Value, "dd/MM/yyyy")
    A_Clipboard := Fecha
    ToolTip "Copiado: " Fecha
    SetTimer () => ToolTip(), -2000
    cg.Destroy()
}

; ============================================================================
; logger.ahk
; ============================================================================
!^F7::
{
    SendInput "-------------------"
    SendInput "{Enter}"
    SendInput "{Space}"
    SendInput FormatTime(, "yy/MM/dd HH:mm:ss")
    SendInput "{Enter}"
    SendInput "-------------------"
}

!^l::
{
    ih := InputHook("L1 T2")
    ih.Start()
    ih.Wait()
    if (ih.EndReason = "Timeout")
        return
    UserInput := ih.Input
    if (UserInput = "1") {
        SendInput "---"
        SendInput "{Enter}"
    } else if (UserInput = "2") {
        SendInput "{Space}"
        SendInput "----------------------"
        SendInput "{Enter}"
    } else {
        return
    }
}

; ============================================================================
; Chord: Ctrl+Alt+5  ->  luego  E  (< 2 s)  ->  escribe "%%end flag"
;   Presioná Ctrl+Alt+5 y, dentro de 2 segundos, la tecla E.
;   Si la E llega a tiempo, escribe el texto literal "%%end flag".
; ============================================================================
global waitingForEndFlagKey := false   ; true tras Ctrl+Alt+5, esperando la "E" (< 2 s)

^!5::
{
    global waitingForEndFlagKey
    waitingForEndFlagKey := true
    SetTimer(ResetEndFlagWait, -2000)   ; la "E" debe llegar en < 2 s
}

; La "E" solo es hotkey durante esa ventana de 2 s (con o sin modificadores).
#HotIf waitingForEndFlagKey
*e::
{
    global waitingForEndFlagKey
    waitingForEndFlagKey := false
    SetTimer(ResetEndFlagWait, 0)
    SendText "%%end flag"
}
#HotIf

ResetEndFlagWait() {
    global waitingForEndFlagKey
    waitingForEndFlagKey := false
}

; ============================================================================
; move_resize.ahk
; ============================================================================
Alt & LButton::
{
    CoordMode "Mouse", "Screen"
    MouseGetPos &origMouseX, &origMouseY, &winId
    while GetKeyState("LButton", "P") {
        MouseGetPos &mouseX, &mouseY
        WinGetPos &winX, &winY, , , "ahk_id " winId
        deltaX := mouseX - origMouseX
        deltaY := mouseY - origMouseY
        origMouseX := mouseX
        origMouseY := mouseY
        SetWinDelay -1
        WinMove winX + deltaX, winY + deltaY, , , "ahk_id " winId
        Sleep 10
    }
}

Alt & RButton::
{
    CoordMode "Mouse", "Screen"
    MouseGetPos &origMouseX, &origMouseY, &winId
    WinGetPos &winX, &winY, &winW, &winH, "ahk_id " winId
    relX := (origMouseX - winX) / winW - .5
    relY := (origMouseY - winY) / winH - .5
    resizeLeft := 2 * relX + Abs(relY) < 0
    resizeTop := 2 * relY + Abs(relX) < 0
    resizeRight := 2 * relX - Abs(relY) > 0
    resizeBottom := 2 * relY - Abs(relX) > 0
    while GetKeyState("RButton", "P") {
        MouseGetPos &mouseX, &mouseY
        WinGetPos &winX, &winY, &winW, &winH, "ahk_id " winId
        deltaX := mouseX - origMouseX
        deltaY := mouseY - origMouseY
        origMouseX := mouseX
        origMouseY := mouseY
        SetWinDelay -1
        newWinX := resizeLeft ? winX + deltaX : winX
        newWinY := resizeTop ? winY + deltaY : winY
        newWinW := winW + winX - newWinX + (resizeRight ? deltaX : 0)
        newWinH := winH + winY - newWinY + (resizeBottom ? deltaY : 0)
        WinMove newWinX, newWinY, newWinW, newWinH, "ahk_id " winId
        Sleep 10
    }
}

; ============================================================================
; mute.ahk
; ============================================================================
#Numpad3::
{
    if !SoundGetMute()
        Send "{Volume_Mute}"
}

; ============================================================================
; pauseplay.ahk
; ============================================================================
^!A::Send "{Media_Play_Pause}"
RAlt & Numpad5::Send "{Media_Play_Pause}"
^!Left::Send "{Media_Prev}"
^!Right::Send "{Media_Next}"
^!Numpad4::Send "{Media_Prev}"
^!Numpad6::Send "{Media_Next}"
^!Numpad3::Send "{Volume_Mute}"   ; Numpad* liberado para idle_edit (Win+Numpad*)
^!NumpadAdd::Send "{Volume_Up}"
^!NumpadSub::Send "{Volume_Down}"
^!Numpad8::Send "{Volume_Up}"
^!Numpad2::Send "{Volume_Down}"

; ============================================================================
; idle_edit_v2.ahk
;   Oculta todo al escritorio (Win+D) tras un período de inactividad física
;   y restaura al primer input. Umbral configurable con Win+Numpad*.
;   0 = desactivado (por defecto al iniciar).
; ============================================================================
if (idleMinutes > 0)          ; arranca el monitoreo solo si viene habilitado
    SetTimer(IdleCheck, 1000)

#NumpadMult:: {
    global idleMinutes, idleThresholdMs

    ib := InputBox("Enter minutes of inactivity before hiding to desktop (0 = disabled):"
                 , "Idle time threshold", "w320 h150", idleMinutes)
    if (ib.Result != "OK")   ; usuario canceló o cerró el cuadro
        return

    newMins := Trim(ib.Value)

    ; validación: debe ser un número no negativo (0 = desactivado)
    if (newMins = "" || !RegExMatch(newMins, "^\d+(\.\d+)?$")) {
        IdleShowTip("Invalid value. Keeping " idleMinutes " min.")
        return
    }

    idleMinutes := newMins + 0
    idleThresholdMs := idleMinutes * 60 * 1000

    if (idleMinutes <= 0) {
        SetTimer(IdleCheck, 0)
        SetTimer(IdleCheck2, 0)
        IdleShowTip("Idle hide disabled (0 min).")
    } else {
        SetTimer(IdleCheck2, 0)
        SetTimer(IdleCheck, 1000)
        IdleShowTip("Idle threshold set to " idleMinutes " min.")
    }
}

IdleShowTip(text) {
    ToolTip(text)
    SetTimer(IdleClearTip, -1200)
}

IdleClearTip() {
    ToolTip()
}

IdleCheck() {
    global idleThresholdMs
    if (A_TimeIdlePhysical >= idleThresholdMs) {
        Send("#d")
        ToolTip("Escritorio")
        SetTimer(IdleCheck, 0)
        Sleep(500)
        SetTimer(IdleCheck2, 500)
    }
}

IdleCheck2() {
    if (A_TimeIdlePhysical < 500) {
        Send("#d")
        ToolTip()
        SetTimer(IdleCheck2, 0)
        SetTimer(IdleCheck, 1000)
    }
}

; ============================================================================
; Timer -> Win+Alt+S   (extraído de !_STARTUP_merged.ahk, reescrito a v2)
;   Win+Alt+U  y luego  I  (< 1 s)  -> abre la GUI del timer
;   Al cumplirse el tiempo elegido          -> envía Win+Alt+S
;   Tras X min de inactividad física (GUI)  -> envía Win+Alt+S (0 = off)
; ============================================================================
global timerMinutes := 0          ; último valor de minutos usado en la GUI
global timerSeconds := 30         ; último valor de segundos usado en la GUI
global inactivityMinutes := 10    ; auto-envío por inactividad; 0 = desactivado
global inactivityFired := false   ; evita reenvíos dentro del mismo período inactivo
global waitingForSTimerKey := false ; true tras Win+Alt+U, esperando la "I" (< 1 s)
SetTimer(CheckInactivity, 1000)

#!u::
{
    global waitingForSTimerKey
    waitingForSTimerKey := true
    SetTimer(ResetSTimerWait, -1000)   ; la "I" debe llegar en < 1 s
}

; La "I" solo es hotkey durante esa ventana de 1 s (con o sin modificadores).
#HotIf waitingForSTimerKey
*i::
{
    global waitingForSTimerKey
    waitingForSTimerKey := false
    SetTimer(ResetSTimerWait, 0)
    OpenSTimerGui()
}
#HotIf

ResetSTimerWait() {
    global waitingForSTimerKey
    waitingForSTimerKey := false
}

OpenSTimerGui() {
    global timerMinutes, timerSeconds, inactivityMinutes
    stg := Gui("+AlwaysOnTop", "Timer -> Win+Alt+S")
    stg.SetFont("s10", "Segoe UI")
    stg.Add("Text", "xm", "Tiempo del timer (minutos : segundos):")
    minEdit := stg.Add("Edit", "xm w70 Number Limit3", timerMinutes)
    stg.Add("Text", "x+8 yp+5 w12 Center", ":")
    secEdit := stg.Add("Edit", "x+8 yp-5 w70 Number Limit2", timerSeconds)
    stg.Add("Text", "xm", "Auto-envío por inactividad (minutos, 0 = off):")
    inacEdit := stg.Add("Edit", "xm w70 Number Limit4", inactivityMinutes)
    inacBtn := stg.Add("Button", "x+10 yp-3 w110", "Solo inactividad")
    startBtn := stg.Add("Button", "xm w120 Default", "Iniciar")
    cancelBtn := stg.Add("Button", "x+10 w120", "Cancelar")
    startBtn.OnEvent("Click", (*) => STimerStart(stg, minEdit, secEdit, inacEdit))
    inacBtn.OnEvent("Click", (*) => STimerSetInactivityOnly(stg, inacEdit))
    cancelBtn.OnEvent("Click", (*) => stg.Destroy())
    stg.OnEvent("Close", (*) => stg.Destroy())
    stg.OnEvent("Escape", (*) => stg.Destroy())
    stg.Show()
    minEdit.Focus()
}

STimerStart(stg, minEdit, secEdit, inacEdit) {
    global timerMinutes, timerSeconds, inactivityMinutes, inactivityFired
    ; Guardar valores para la próxima apertura y para la inactividad.
    timerMinutes := minEdit.Value + 0
    timerSeconds := secEdit.Value + 0
    inactivityMinutes := inacEdit.Value + 0
    inactivityFired := false                 ; re-armar el chequeo de inactividad
    stg.Destroy()
    totalMs := (timerMinutes * 60 + timerSeconds) * 1000
    if (totalMs > 0) {
        SetTimer(FireSCombo, -totalMs)       ; one-shot: dispara al cumplirse
        ToolTip "Timer: " timerMinutes " min " timerSeconds " s -> Win+Alt+S"
    } else {
        ToolTip "Sin timer (0:00). Inactividad: " inactivityMinutes " min"
    }
    SetTimer () => ToolTip(), -1500
}

STimerSetInactivityOnly(stg, inacEdit) {
    global inactivityMinutes, inactivityFired
    inactivityMinutes := inacEdit.Value + 0
    inactivityFired := false                 ; re-armar el chequeo de inactividad
    stg.Destroy()
    ToolTip "Inactividad: " inactivityMinutes " min (sin cambiar el timer manual)"
    SetTimer () => ToolTip(), -1500
}

FireSCombo() {
    SetTimer(FireSCombo, 0)
    SendInput "#!s"
}

; Chequeo periódico de inactividad (timer cada 1 s, arrancado al inicio).
; Usa A_TimeIdlePhysical para ignorar el input simulado por el propio script.
CheckInactivity() {
    global inactivityMinutes, inactivityFired
    if (inactivityMinutes <= 0) {
        inactivityFired := false
        return
    }
    if (A_TimeIdlePhysical >= inactivityMinutes * 60000) {
        if (!inactivityFired) {
            inactivityFired := true
            SendInput "#!s"
        }
    } else {
        inactivityFired := false             ; hubo actividad: re-armar
    }
}

; ============================================================================
; right_tab.ahk
; ============================================================================
RCtrl & Numpad5::
{
    Send "{Tab}"
}

; ============================================================================
; selectcellcontent.ahk
; ============================================================================
!F2::
{
    Send "{Backspace}"
    Send "^z"
}

; ============================================================================
; volume.ahk
; ============================================================================
#WheelUp::Send "{Volume_Up}"
#WheelDown::Send "{Volume_Down}"

; ============================================================================
; macro_insta_name.ahk
; ============================================================================
^!x::  ; Ctrl+Alt+X
{
    SendInput "{Esc}"
    Sleep 50
    SendInput "!+{End}"
    Sleep 1200
    SendInput "^a"
    Sleep 200
    SendInput "^v"
    Sleep 80
    SendInput "{Tab}"
    Sleep 70
    SendInput "{Enter}"
    Sleep 550
    SendInput "+a"
}

^!+x::  ; Ctrl+Alt+Shift+X
{
    SendInput "!+{h}"
    Sleep 1000
    SendInput "{Down}"
    Sleep 100
    SendInput "{Enter}"
    Sleep 10
}

; ============================================================================
; find_wise_reminder.ahk
; ============================================================================
#z::
{
    if ProcessExist("WiseReminder.exe") {
        WinState := ""
        try WinState := WinGetMinMax("ahk_exe WiseReminder.exe")
        if (WinState = "") {
            SendInput "#b"
            SendInput "{Enter}"
            Sleep 50
            SendInput "{Up}"
            SendInput "w"
            Sleep 40
            SendInput "w"
            Sleep 40
            SendInput "{Enter}"
            Sleep 100
            Click clickX, clickY
            Sleep 1000
            Click clickXX, clickYY
        } else
            WinActivate "ahk_exe WiseReminder.exe"
    } else
        Run '"C:\Program Files (x86)\Wise\Wise Reminder\WiseReminder.exe"'
}

; ============================================================================
; open_hourglass.ahk
; ============================================================================
#^+z::
{
    if ProcessExist("Hourglass.exe")
        WinActivate "ahk_exe Hourglass.exe"
    else
        Run '"C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Hourglass\Hourglass.lnk"'
}

; ============================================================================
; open-program-GUI.ahk
;   Requiere open-program-GUI.ini (guarda overrides de rutas por programa).
; ============================================================================
OpenProgramIniFile := A_ScriptDir "\open-program-GUI.ini"

OpenProgramPrograms := Map(
    "Paint", "C:\Windows\System32\mspaint.exe",
    "Notepad++", "C:\Program Files\Notepad++\notepad++.exe"
)

for name, defaultPath in OpenProgramPrograms
    OpenProgramPrograms[name] := IniRead(OpenProgramIniFile, "Paths", name, defaultPath)

^#p::ShowOpenProgramGui()

ShowOpenProgramGui() {
    global OpenProgramPrograms
    if WinExist("Open Program ahk_class AutoHotkey") {
        WinActivate
        return
    }

    MyOpenProgramGui := Gui(, "Open Program")
    MyOpenProgramGui.OnEvent("Close", (*) => MyOpenProgramGui.Destroy())
    MyOpenProgramGui.SetFont("s10")

    for name, path in OpenProgramPrograms {
        MyOpenProgramGui.Add("Button", "x10 y+10 w150", name).OnEvent("Click", MakeOpenProgramLaunchHandler(name, MyOpenProgramGui))
        MyOpenProgramGui.Add("Button", "x+5 yp w80", "Edit path").OnEvent("Click", MakeOpenProgramEditHandler(name))
    }

    MyOpenProgramGui.Add("Button", "x10 y+15 w235", "Close").OnEvent("Click", (*) => MyOpenProgramGui.Destroy())

    MyOpenProgramGui.Show()
}

MakeOpenProgramLaunchHandler(name, gui) {
    return (*) => LaunchOpenProgram(name, gui)
}

MakeOpenProgramEditHandler(name) {
    return (*) => EditOpenProgramPath(name)
}

LaunchOpenProgram(name, gui) {
    global OpenProgramPrograms
    path := OpenProgramPrograms[name]
    if !FileExist(path) {
        MsgBox("Unable to find " name " at:`n" path)
        return
    }
    try
        Run(path)
    catch as err {
        MsgBox("Failed to launch " name ":`n" err.Message)
        return
    }
    gui.Destroy()
}

EditOpenProgramPath(name) {
    global OpenProgramPrograms, OpenProgramIniFile
    result := InputBox("Path for " name ":", "Edit path", "w400 h130", OpenProgramPrograms[name])
    if (result.Result = "OK" && result.Value != "") {
        OpenProgramPrograms[name] := result.Value
        IniWrite(result.Value, OpenProgramIniFile, "Paths", name)
    }
}

; ============================================================================
; find_google_calendar.ahk
;   Requiere find_google_calendar.ini (define el navegador: Chrome o Firefox)
;   y UIA.ahk (incluido arriba) para inspeccionar pestañas vía UI Automation.
; ============================================================================
GoogleCalendarIniFile := A_ScriptDir "\find_google_calendar.ini"
GoogleCalendarBrowserExe := Map("Chrome", "chrome.exe", "Firefox", "firefox.exe")
    .Get(IniRead(GoogleCalendarIniFile, "Settings", "Browser", "Chrome"), "chrome.exe")

+NumpadEnter::
{
    global GoogleCalendarBrowserExe
    for hwnd in WinGetList("ahk_exe " GoogleCalendarBrowserExe) {
        root := UIA.ElementFromHandle(hwnd)
        for tab in root.FindElements({Type: "TabItem"}) {
            if InStr(tab.Name, "Calendario") || InStr(tab.Name, "Google Calendar") {
                tab.Select()
                MsgBox(tab.Name)
                WinActivate("ahk_id " hwnd)
                return
            }
        }
    }
}

; ============================================================================
; kill_all.ahk
; ============================================================================
^+!k::  ; Ctrl + Shift + Alt + K
{
    for this_id in WinGetList() {
        try {
            title := WinGetTitle("ahk_id " this_id)
            class := WinGetClass("ahk_id " this_id)
            exe := WinGetProcessName("ahk_id " this_id)
            style := WinGetStyle("ahk_id " this_id)
        } catch {
            continue
        }
        if (class = "Progman" || class = "WorkerW")
            continue
        if (exe = "chrome.exe" || exe = "msedge.exe")
            continue
        if (title = "")
            continue
        if (style & 0x10000000) {
            WinClose "ahk_id " this_id
            Sleep 100
        }
    }
}

; ============================================================================
; Show_Time.ahk
; ============================================================================
#c::  ; Win + C
{
    Send "#{b}"
    Sleep 100
    Send "{Right 5}"
    Sleep 50
    Send "{Enter}"
}

; ============================================================================
; Cycler_Windows_v3.ahk
;   Win+F5 = Add active window | Win+F4 = Cycle stored windows
;   Win+Shift+F5 = Remove active window | Win+Shift+F4 = Show GUI list
; ============================================================================
#F5::AddActiveWindow()
#F4::CycleWindows()
#+F5::RemoveActiveWindow()
#+F4::ShowWindowListGuiIfNeeded()

AddActiveWindow() {
    global gWindows
    hwnd := WinGetID("A")
    if !hwnd
        return
    for v in gWindows {
        if (v = hwnd) {
            TrayTip "Window Already Saved", "This window is already stored.", 2
            return
        }
    }
    gWindows.Push(hwnd)
    title := WinGetTitle("ahk_id " hwnd)
    TrayTip "Window Saved", "Added (" gWindows.Length "):`n" title, 2
}

CycleWindows() {
    global gWindows, gIndex
    if (gWindows.Length = 0) {
        MsgBox "No windows have been stored yet.", "No Windows Stored", 48
        gIndex := 0
        return
    }
    CleanClosedWindows()
    if (gWindows.Length = 0) {
        MsgBox "All stored windows were closed.`nList cleared.", "All Windows Closed", 48
        gIndex := 0
        return
    }
    gIndex++
    if (gIndex > gWindows.Length)
        gIndex := 1
    hwnd := gWindows[gIndex]
    if !WinExist("ahk_id " hwnd) {
        gWindows.RemoveAt(gIndex)
        gIndex--
        CycleWindows()
        return
    }
    WinActivate "ahk_id " hwnd
}

RemoveActiveWindow() {
    global gWindows, gIndex
    if (gWindows.Length = 0) {
        MsgBox "No windows are stored.", "Nothing Stored", 48
        gIndex := 0
        return
    }
    CleanClosedWindows()
    if (gWindows.Length = 0) {
        MsgBox "No windows are stored.", "Nothing Stored", 48
        gIndex := 0
        return
    }
    hwnd := WinGetID("A")
    if !hwnd
        return
    removed := false
    for i, v in gWindows {
        if (v = hwnd) {
            gWindows.RemoveAt(i)
            removed := true
            if (gIndex >= i)
                gIndex--
            break
        }
    }
    if removed {
        title := WinGetTitle("ahk_id " hwnd)
        TrayTip "Removed", "Removed:`n" title, 2
    } else {
        TrayTip "Not Found", "Active window wasn't in the list.", 2
    }
    if (gWindows.Length = 0)
        gIndex := 0
}

ShowWindowListGuiIfNeeded() {
    global gListGuiVisible, gWindows, gIndex
    if gListGuiVisible
        return
    CleanClosedWindows()
    if (gWindows.Length = 0) {
        MsgBox "No windows are stored.", "No Windows Stored", 48
        gIndex := 0
        return
    }
    ShowWindowListGui()
}

CleanClosedWindows() {
    global gWindows, gIndex
    count := gWindows.Length
    Loop count {
        i := count - A_Index + 1
        hwnd := gWindows[i]
        if !WinExist("ahk_id " hwnd) {
            gWindows.RemoveAt(i)
            if (gIndex >= i)
                gIndex--
        }
    }
    if (gIndex < 0)
        gIndex := 0
}

ShowWindowListGui() {
    global gWindows, gIndex, gListGuiVisible, cyclerListGui
    gListGuiVisible := true
    cyclerListGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    cyclerListGui.MarginX := 10
    cyclerListGui.MarginY := 10
    cyclerListGui.SetFont("s9", "Segoe UI")
    cyclerListGui.Add("Text", , "Saved Windows (Win+F4 cycles)")
    lv := cyclerListGui.Add("ListView", "w520 r10 Grid -Multi", ["#", "Current", "Title", "HWND"])
    lv.ModifyCol(1, 40)
    lv.ModifyCol(2, 55)
    lv.ModifyCol(3, 360)
    lv.ModifyCol(4, 80)
    for i, hwnd in gWindows {
        title := WinGetTitle("ahk_id " hwnd)
        cur := (i = gIndex ? "◀" : "")
        lv.Add("", i, cur, title, hwnd)
    }
    cyclerListGui.Show("x100 y100 NoActivate")
    SetTimer(CheckWinReleased, 50)
}

CheckWinReleased() {
    global gListGuiVisible, cyclerListGui
    if (!GetKeyState("LWin", "P") && !GetKeyState("RWin", "P")) {
        SetTimer(CheckWinReleased, 0)
        cyclerListGui.Destroy()
        gListGuiVisible := false
    }
}

; ============================================================================
; url_chrome.ahk
; ============================================================================
^!g::Run('"C:\Program Files\Google\Chrome\Application\chrome.exe" --new-window "https://docs.google.com/spreadsheets/d/1Nnjsc_sP1qFOMX8VNbibMK_C23MlZj2OMOvA_R3gsDQ/edit?gid=0#gid=0"')
^!+g::Run('"C:\Program Files\Google\Chrome\Application\chrome.exe" --new-tab "https://docs.google.com/spreadsheets/d/1Nnjsc_sP1qFOMX8VNbibMK_C23MlZj2OMOvA_R3gsDQ/edit?gid=0#gid=0"')

; ============================================================================
; convCount.ahk
; ============================================================================
^!#t::
{
    global counter
    counter += 1
    timestamp := FormatTime(A_Now, "dd/MM/yyyy - [HH:mm]")
    text := "Conversation User Input n° " counter " @ " timestamp " . "
    SendText text
}

^!#r::
{
    global counter, lastControlPress
    now := A_TickCount
    if lastControlPress && (now - lastControlPress <= 700) {
        lastControlPress := 0
        OpenCounterGui()
        return
    }
    counter := 0
    lastControlPress := now
    ToolTip "Conversation counter reset"
    SetTimer () => ToolTip(), -1000
}

OpenCounterGui() {
    global counter
    g := Gui("+AlwaysOnTop", "Set conversation counter")
    g.SetFont("s10", "Segoe UI")
    g.AddText("w370", "Set current counter number:")
    edit := g.AddEdit("w370 Number", counter)
    saveBtn := g.AddButton("Default w120", "Save")
    cancelBtn := g.AddButton("x+10 w120", "Cancel")
    sendTextBtn := g.AddButton("x+10 w120", "Ask")
    saveBtn.OnEvent("Click", (*) => SaveCounterFromGui(g, edit))
    cancelBtn.OnEvent("Click", (*) => g.Destroy())
    sendTextBtn.OnEvent("Click", (*) => PutAskTextOnClipboardAndClose(g))
    g.OnEvent("Escape", (*) => g.Destroy())
    g.Show()
    edit.Focus()
    SendMessage 0xB1, 0, -1, edit
}

SaveCounterFromGui(g, edit) {
    global counter
    value := Trim(edit.Value)
    if !RegExMatch(value, "^\d+$") {
        MsgBox "Please enter a whole number, for example: 0, 1, 25."
        return
    }
    counter := Integer(value)
    g.Destroy()
    ToolTip "Conversation counter set to " counter
    SetTimer () => ToolTip(), -1000
}

PutAskTextOnClipboardAndClose(g) {
    A_Clipboard := "En que numero de input de chat estoy en esta conversacion (incluyendo este)?"
    g.Destroy()
    ToolTip "Question copied to clipboard"
    SetTimer () => ToolTip(), -1000
}

; ============================================================================
; createTXT.ahk
; ============================================================================
#+t::
{
    path := GetActiveExplorerPath()
    if !path {
        MsgBox "No valid Explorer window detected."
        return
    }
    ShowCreateFileGui(path)
}

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

        if (name = "New Document" || name = "") {
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
    name := RegExReplace(name, "\.[^\.\\/:*?`"<>|]+$")
    name := RegExReplace(name, '[\\/:*?"<>|]', "-")
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
                if DirExist(path) {
                    return path
                }
                return ""
            }
        }
    }

    return ""
}

; ============================================================================
; resize.ahk
; ============================================================================
^!MButton::
{
    winID := WinGetID("A")
    if (winID) {
        WinMove , , 300, 300, "ahk_id " winID
    }
}

^!RButton::
{
    winID := WinGetID("A")
    if (winID) {
        WinRestore "ahk_id " winID
        WinGetPos &X, &Y, &W, &H, "ahk_id " winID
        newX := (A_ScreenWidth - W) // 2
        newY := (A_ScreenHeight - H) // 2
        WinMove newX, newY, , , "ahk_id " winID
    }
}

; ============================================================================
; Referencia de comandos  (Win + Shift + ?  ->  popup flotante con el HTML)
; ============================================================================
; SC00C es la tecla '?' en el layout Latinoamericano (es-AR): '?' = Shift+esa
; tecla, por eso se bindea por scancode y queda independiente del símbolo.
; Carga AHK_Unified_Master_Referencia_ie.html (copia con CSS sin variables,
; porque el control ActiveX usa el motor IE que no soporta var(--x)).
#+SC00C::ShowReferenceGui()

ShowReferenceGui() {
    static refGui := ""   ; instancia única, reutilizada entre llamadas

    ; Toggle: si ya está visible, se cierra.
    if (refGui != "" && DllCall("IsWindowVisible", "ptr", refGui.Hwnd))
    {
        refGui.Hide()
        return
    }

    ; Primera invocación: construir la ventana y cargar el HTML una sola vez.
    if (refGui = "")
    {
        refFile := A_ScriptDir "\AHK_Unified_Master_Referencia_ie.html"
        if !FileExist(refFile)
        {
            MsgBox("No se encontró el archivo de referencia:`n" refFile, "Referencia", "Iconx")
            return
        }
        refGui := Gui("+AlwaysOnTop +ToolWindow +Resize", "Referencia de comandos — AHK")
        refGui.BackColor := "1b1d22"
        refGui.MarginX := 0
        refGui.MarginY := 0
        wb := refGui.Add("ActiveX", "x0 y0 w1020 h740 vRefBrowser", "Shell.Explorer")
        wb.Value.Navigate(refFile)
        refGui.OnEvent("Close", (*) => refGui.Hide())   ; X cierra (oculta, no destruye)
        refGui.OnEvent("Escape", (*) => refGui.Hide())  ; Esc cierra
        refGui.OnEvent("Size", ReferenceGuiResize)       ; el browser sigue el tamaño
    }

    refGui.Show("w1020 h740 Center")
}

; Mantiene el control web ocupando todo el área cliente al redimensionar.
ReferenceGuiResize(thisGui, minMax, w, h) {
    if (minMax = -1)   ; minimizada: no reposicionar
        return
    thisGui["RefBrowser"].Move(0, 0, w, h)
}

; ============================================================================
; AHK_Manager.ahk  (Ctrl+Alt+R reabre/activa la ventana del Manager)
; ============================================================================
^!r::
{
    MyGui.Show()
    Refresh()
}

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

MyGui.OnEvent("Close", (*) => MyGui.Hide())
MyGui.Show("w375 h365")
Refresh()

; Escape / Alt+Espacio solo afectan cuando la ventana del Manager está activa
#HotIf WinActive("ahk_id " MyGui.Hwnd)
~Escape::ExitApp
~!Space::Reload
#HotIf

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
                } else if (style & 0x20000000) {
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

OpenMacroRecorder() {
    macroRecorderPath := "C:\autohotkey\Macro.Recorder.exe"
    if FileExist(macroRecorderPath) {
        Run(macroRecorderPath)
    } else {
        MsgBox("Unable to find Macro.Recorder.exe at: " macroRecorderPath)
    }
}

SendAHKMessage(scriptPath, message) {
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    if (hWnd := WinExist(scriptPath " ahk_class AutoHotkey")) {
        PostMessage(0x111, message, 0, , "ahk_id " hWnd)
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

; ============================================================================
; ^RUN_starters.ahk  (programas externos lanzados al iniciar)
; ============================================================================
Sleep 200
Run "C:\autohotkey\RBTray-4_3\64bit\RBTray.exe"
Run "C:\Users\fzapata\Desktop\Wise Reminder.lnk"

; ----
; Pruebas Manuales de hotkeys (decidir luego si eliminar)
; ----

#ñ::Run "http://youtube.com"