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
;   - Cerrar TODO este script unificado quedó exclusivamente en el botón "Quit"
;     del Manager (o seleccionar este script en la lista y darle "Kill"). La
;     tecla Escape, con la ventana del Manager activa, solo oculta esa ventana
;     -- igual que la X -- y deja todos los hotkeys andando.
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
+Delete::Send "{Backspace}"   ; Shift+Supr -> Backspace

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
::kfz::fzapata@iea.com.ar
::kzf::zapatafacundo17@gmail.com

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
; New behavior
^NumpadDot::Send "{;}"
!NumpadDot::Send "{:}"

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
;
;   Win+Alt+U  y luego  A  (< 2 s)  -> abre la GUI del timer -> Play/Pausa
;   (esa GUI y su disparo viven en la sección "Timer -> Play/Pausa", más abajo)
; ============================================================================
global timerMinutes := 0          ; último valor de minutos usado en la GUI
global timerSeconds := 30         ; último valor de segundos usado en la GUI
global inactivityMinutes := 10    ; auto-envío por inactividad; 0 = desactivado
global inactivityFired := false   ; evita reenvíos dentro del mismo período inactivo
global waitingForSTimerKey := false ; true tras Win+Alt+U, esperando la "I" (< 1 s)
global waitingForATimerKey := false ; true tras Win+Alt+U, esperando la "A" (< 2 s)
SetTimer(CheckInactivity, 1000)

#!u::
{
    global waitingForSTimerKey, waitingForATimerKey
    waitingForSTimerKey := true
    waitingForATimerKey := true
    SetTimer(ResetSTimerWait, -1000)   ; la "I" debe llegar en < 1 s
    SetTimer(ResetATimerWait, -2000)   ; la "A" debe llegar en < 2 s
}

; La "I" solo es hotkey durante esa ventana de 1 s (con o sin modificadores).
#HotIf waitingForSTimerKey
*i::
{
    ClearTimerChordWait()
    OpenSTimerGui()
}
#HotIf

; La "A" solo es hotkey durante su ventana de 2 s (con o sin modificadores:
; es normal seguir apretando Win+Alt al llegar de Win+Alt+U).
#HotIf waitingForATimerKey
*a::
{
    ClearTimerChordWait()
    OpenATimerGui()
}
#HotIf

ResetSTimerWait() {
    global waitingForSTimerKey
    waitingForSTimerKey := false
}

ResetATimerWait() {
    global waitingForATimerKey
    waitingForATimerKey := false
}

; Al aceptar cualquiera de las dos teclas se cierran las dos ventanas, para que
; la que quede viva no abra además la otra GUI.
ClearTimerChordWait() {
    global waitingForSTimerKey, waitingForATimerKey
    waitingForSTimerKey := false
    waitingForATimerKey := false
    SetTimer(ResetSTimerWait, 0)
    SetTimer(ResetATimerWait, 0)
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
; Timer -> Play/Pausa multimedia
;   Win+Alt+U  y luego  A  (< 2 s)  -> abre esta GUI (el acorde se arma en la
;   sección "Timer -> Win+Alt+S", que es la dueña del hotkey Win+Alt+U)
;   Al cumplirse el tiempo elegido  -> envía Media_Play_Pause
;   Iniciar con 0:00                -> cancela el timer pendiente
; ============================================================================
global aTimerMinutes := 0         ; último valor de minutos usado en la GUI
global aTimerSeconds := 30        ; último valor de segundos usado en la GUI

OpenATimerGui() {
    global aTimerMinutes, aTimerSeconds
    atg := Gui("+AlwaysOnTop", "Timer -> Play/Pausa")
    atg.SetFont("s10", "Segoe UI")
    atg.Add("Text", "xm", "Tiempo del timer (minutos : segundos):")
    minEdit := atg.Add("Edit", "xm w70 Number Limit3", aTimerMinutes)
    atg.Add("Text", "x+8 yp+5 w12 Center", ":")
    secEdit := atg.Add("Edit", "x+8 yp-5 w70 Number Limit2", aTimerSeconds)
    startBtn := atg.Add("Button", "xm w120 Default", "Iniciar")
    cancelBtn := atg.Add("Button", "x+10 w120", "Cancelar")
    startBtn.OnEvent("Click", (*) => ATimerStart(atg, minEdit, secEdit))
    cancelBtn.OnEvent("Click", (*) => atg.Destroy())
    atg.OnEvent("Close", (*) => atg.Destroy())
    atg.OnEvent("Escape", (*) => atg.Destroy())
    atg.Show()
    minEdit.Focus()
}

ATimerStart(atg, minEdit, secEdit) {
    global aTimerMinutes, aTimerSeconds
    ; Guardar valores para la próxima apertura (campo vacío = 0).
    aTimerMinutes := (minEdit.Value = "") ? 0 : minEdit.Value + 0
    aTimerSeconds := (secEdit.Value = "") ? 0 : secEdit.Value + 0
    atg.Destroy()
    totalMs := (aTimerMinutes * 60 + aTimerSeconds) * 1000
    if (totalMs > 0) {
        SetTimer(FirePlayPause, -totalMs)    ; one-shot: dispara al cumplirse
        ToolTip "Timer: " aTimerMinutes " min " aTimerSeconds " s -> Play/Pausa"
    } else {
        SetTimer(FirePlayPause, 0)           ; 0:00 -> cancela lo que hubiera
        ToolTip "Timer Play/Pausa cancelado (0:00)"
    }
    SetTimer () => ToolTip(), -1500
}

FirePlayPause() {
    SetTimer(FirePlayPause, 0)
    ; Se manda la tecla multimedia directamente, igual que hace ^!A. Nadie
    ; hookea Media_Play_Pause en este script, así que no hace falta SendLevel.
    Send "{Media_Play_Pause}"
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
    "Notepad++", "C:\Program Files\Notepad++\notepad++.exe",
    "OBS", "C:\Program Files\obs-studio\bin\64bit\obs64.exe",
    "SpeedCrunch", "C:\Program Files (x86)\SpeedCrunch\speedcrunch.exe"
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
; Ventanas con timer  (lista aparte de la del ciclador Win+F4/F5)
;   Win+F6        = guarda la ventana activa y abre una GUI para elegir en
;                   cuánto tiempo reaparece (+ check "Always on top").
;   Win+Shift+F6  = GUI de administración: ver los timers corriendo, sumar o
;                   restar tiempo, abrir ya o eliminarlos.
;   Al cumplirse el tiempo la ventana se restaura (si estaba minimizada) y se
;   activa; el timer se consume (no se repite).
; ============================================================================
global gTimedWindows := []        ; items: Map("id","hwnd","title","due","aot")
global gTimedNextId  := 1
global gTimedGui     := ""        ; GUI de administración (Win+Shift+F6)
global gTimedGuiLV   := ""
global gTimedGuiHdr  := ""
global gTimedGuiIds  := []        ; id del timer que corresponde a cada fila
global gTimedLastMin := 5         ; últimos valores usados en la GUI de alta
global gTimedLastSec := 0
SetTimer(CheckTimedWindows, 500)

#F6::SaveWindowWithTimer()
#+F6::ShowTimedWindowsGui()

SaveWindowWithTimer() {
    hwnd := WinGetID("A")
    if !hwnd {
        TrayTip "Sin ventana activa", "No hay ninguna ventana para guardar.", 2
        return
    }
    OpenTimedWindowGui(hwnd)
}

OpenTimedWindowGui(hwnd) {
    global gTimedLastMin, gTimedLastSec
    title := ""
    try title := WinGetTitle("ahk_id " hwnd)
    shown := (title = "") ? "(sin título)"
        : (StrLen(title) > 64 ? SubStr(title, 1, 61) "..." : title)

    tw := Gui("+AlwaysOnTop", "Guardar ventana con timer")
    tw.SetFont("s10", "Segoe UI")
    tw.Add("Text", "xm w390", "Ventana guardada:")
    tw.SetFont("s10 bold")
    tw.Add("Text", "xm w390", shown)
    tw.SetFont("s10 norm")
    ; Aviso (no bloqueante) si esta misma ventana ya tenía un timer pendiente.
    if (existing := FindTimedWindowByHwnd(hwnd))
        tw.Add("Text", "xm w390 cRed"
            , "Ojo: ya tenía un timer corriendo (" FormatRemaining(existing["due"]) "). Se suma otro.")
    tw.Add("Text", "xm", "Abrirla dentro de (minutos : segundos):")
    minEdit := tw.Add("Edit", "xm w70 Number Limit4", gTimedLastMin)
    tw.Add("Text", "x+8 yp+5 w12 Center", ":")
    secEdit := tw.Add("Edit", "x+8 yp-5 w70 Number Limit2", gTimedLastSec)
    aotChk := tw.Add("CheckBox", "xm", "Dejarla Always on top al abrirla")
    startBtn := tw.Add("Button", "xm w120 Default", "Iniciar")
    cancelBtn := tw.Add("Button", "x+10 w120", "Cancelar")
    startBtn.OnEvent("Click", (*) => TimedWindowStart(tw, hwnd, title, minEdit, secEdit, aotChk))
    cancelBtn.OnEvent("Click", (*) => tw.Destroy())
    tw.OnEvent("Close", (*) => tw.Destroy())
    tw.OnEvent("Escape", (*) => tw.Destroy())
    tw.Show()
    minEdit.Focus()
}

TimedWindowStart(tw, hwnd, title, minEdit, secEdit, aotChk) {
    global gTimedWindows, gTimedNextId, gTimedLastMin, gTimedLastSec
    totalSec := (minEdit.Value + 0) * 60 + (secEdit.Value + 0)
    if (totalSec <= 0) {
        MsgBox "Ingresá un tiempo mayor a 0.", "Timer de ventana", 48
        return
    }
    if !WinExist("ahk_id " hwnd) {
        MsgBox "La ventana ya no existe.", "Timer de ventana", 48
        tw.Destroy()
        return
    }
    gTimedLastMin := minEdit.Value + 0
    gTimedLastSec := secEdit.Value + 0
    gTimedWindows.Push(Map(
        "id", gTimedNextId,
        "hwnd", hwnd,
        "title", (title = "" ? "(sin título)" : title),
        "due", A_TickCount + totalSec * 1000,
        "aot", aotChk.Value ? true : false))
    gTimedNextId += 1
    tw.Destroy()
    TrayTip "Timer creado"
        , "Se abre en " FormatSeconds(totalSec) "`n" title "`nTimers activos: " gTimedWindows.Length, 2
    RebuildTimedWindowsGui()
}

; Chequeo periódico (cada 0,5 s): dispara los vencidos y descarta los timers
; cuya ventana se cerró mientras tanto.
CheckTimedWindows() {
    global gTimedWindows
    changed := false
    i := gTimedWindows.Length
    while (i >= 1) {
        item := gTimedWindows[i]
        if !WinExist("ahk_id " item["hwnd"]) {
            gTimedWindows.RemoveAt(i)
            changed := true
            TrayTip "Timer cancelado", "Se cerró la ventana:`n" item["title"], 2
        } else if (A_TickCount >= item["due"]) {
            gTimedWindows.RemoveAt(i)
            changed := true
            OpenTimedWindow(item)
        }
        i -= 1
    }
    if changed
        RebuildTimedWindowsGui()
}

OpenTimedWindow(item) {
    hwnd := item["hwnd"]
    if !WinExist("ahk_id " hwnd)
        return
    try {
        if (WinGetMinMax("ahk_id " hwnd) = -1)
            WinRestore "ahk_id " hwnd
        WinActivate "ahk_id " hwnd
        ; if item["aot"]
        ;    WinSetAlwaysOnTop true, "ahk_id " hwnd
    }
    TrayTip "Ventana abierta", item["title"], 2
}

FindTimedWindowByHwnd(hwnd) {
    global gTimedWindows
    for item in gTimedWindows {
        if (item["hwnd"] = hwnd)
            return item
    }
    return ""
}

FormatRemaining(due) {
    ms := due - A_TickCount
    return FormatSeconds(ms > 0 ? Ceil(ms / 1000) : 0)
}

FormatSeconds(totalSec) {
    h := totalSec // 3600
    m := Mod(totalSec // 60, 60)
    s := Mod(totalSec, 60)
    return h > 0 ? Format("{:d}:{:02d}:{:02d}", h, m, s) : Format("{:d}:{:02d}", m, s)
}

; ---- GUI de administración de timers (Win+Shift+F6) ----
ShowTimedWindowsGui() {
    global gTimedGui, gTimedGuiLV, gTimedGuiHdr
    if IsObject(gTimedGui) {
        gTimedGui.Show()
        RebuildTimedWindowsGui()
        return
    }
    g := Gui("+AlwaysOnTop", "Timers de ventanas")
    g.MarginX := 10
    g.MarginY := 10
    g.SetFont("s9", "Segoe UI")
    gTimedGuiHdr := g.Add("Text", "xm w540", "")
    lv := g.Add("ListView", "xm w540 r8 Grid -Multi", ["#", "Restante", "Ventana", "Top"])
    lv.ModifyCol(1, 30)
    lv.ModifyCol(2, 70)
    lv.ModifyCol(3, 390)
    lv.ModifyCol(4, 40)
    add1Btn := g.Add("Button", "xm w76", "+1 min")
    add5Btn := g.Add("Button", "x+6 w76", "+5 min")
    sub1Btn := g.Add("Button", "x+6 w76", "-1 min")
    openBtn := g.Add("Button", "x+6 w96", "Abrir ahora")
    delBtn := g.Add("Button", "x+6 w86", "Eliminar")
    closeBtn := g.Add("Button", "x+6 w76", "Cerrar")
    add1Btn.OnEvent("Click", (*) => TimedGuiAddTime(60))
    add5Btn.OnEvent("Click", (*) => TimedGuiAddTime(300))
    sub1Btn.OnEvent("Click", (*) => TimedGuiAddTime(-60))
    openBtn.OnEvent("Click", (*) => TimedGuiOpenNow())
    delBtn.OnEvent("Click", (*) => TimedGuiDelete())
    closeBtn.OnEvent("Click", (*) => CloseTimedWindowsGui())
    lv.OnEvent("DoubleClick", (*) => TimedGuiOpenNow())
    g.OnEvent("Close", (*) => CloseTimedWindowsGui())
    g.OnEvent("Escape", (*) => CloseTimedWindowsGui())
    gTimedGui := g
    gTimedGuiLV := lv
    RebuildTimedWindowsGui()
    g.Show()
    SetTimer(TickTimedWindowsGui, 500)   ; refresca la cuenta regresiva
}

CloseTimedWindowsGui() {
    global gTimedGui, gTimedGuiLV, gTimedGuiHdr, gTimedGuiIds
    SetTimer(TickTimedWindowsGui, 0)
    if IsObject(gTimedGui)
        gTimedGui.Destroy()
    gTimedGui := ""
    gTimedGuiLV := ""
    gTimedGuiHdr := ""
    gTimedGuiIds := []
}

; Reconstruye la lista completa (cuando cambia la cantidad de timers).
RebuildTimedWindowsGui() {
    global gTimedGui, gTimedGuiLV, gTimedGuiHdr, gTimedGuiIds, gTimedWindows
    if !IsObject(gTimedGui)
        return
    sel := gTimedGuiLV.GetNext(0)
    gTimedGuiLV.Opt("-Redraw")
    gTimedGuiLV.Delete()
    gTimedGuiIds := []
    for i, item in gTimedWindows {
        title := item["title"]
        try {
            live := WinGetTitle("ahk_id " item["hwnd"])
            if (live != "")
                title := live
        }
        gTimedGuiIds.Push(item["id"])
        gTimedGuiLV.Add("", i, FormatRemaining(item["due"]), title, item["aot"] ? "Sí" : "")
    }
    gTimedGuiLV.Opt("+Redraw")
    if (sel >= 1 && sel <= gTimedWindows.Length)
        gTimedGuiLV.Modify(sel, "Select Focus")
    gTimedGuiHdr.Text := gTimedWindows.Length
        ? "Timers corriendo: " gTimedWindows.Length "   (Win+F6 agrega uno nuevo)"
        : "No hay timers corriendo   (Win+F6 agrega uno nuevo)"
}

; Solo actualiza la columna "Restante" para no perder la selección ni parpadear.
TickTimedWindowsGui() {
    global gTimedGui, gTimedGuiLV, gTimedWindows
    if !IsObject(gTimedGui) {
        SetTimer(TickTimedWindowsGui, 0)
        return
    }
    if (gTimedGuiLV.GetCount() != gTimedWindows.Length) {
        RebuildTimedWindowsGui()
        return
    }
    for i, item in gTimedWindows
        gTimedGuiLV.Modify(i, "Col2", FormatRemaining(item["due"]))
}

TimedGuiSelectedIndex() {
    global gTimedGuiLV, gTimedGuiIds, gTimedWindows
    if !IsObject(gTimedGuiLV)
        return 0
    row := gTimedGuiLV.GetNext(0)
    if (row < 1 || row > gTimedGuiIds.Length) {
        TrayTip "Timers de ventanas", "Seleccioná una fila de la lista primero.", 2
        return 0
    }
    id := gTimedGuiIds[row]
    for i, item in gTimedWindows {
        if (item["id"] = id)
            return i
    }
    return 0
}

TimedGuiAddTime(deltaSec) {
    global gTimedWindows
    if !(idx := TimedGuiSelectedIndex())
        return
    item := gTimedWindows[idx]
    newDue := item["due"] + deltaSec * 1000
    if (newDue < A_TickCount + 1000)     ; restando tiempo nunca lo mandamos al pasado
        newDue := A_TickCount + 1000
    item["due"] := newDue
    TickTimedWindowsGui()
}

TimedGuiOpenNow() {
    global gTimedWindows
    if !(idx := TimedGuiSelectedIndex())
        return
    item := gTimedWindows.RemoveAt(idx)
    OpenTimedWindow(item)
    RebuildTimedWindowsGui()
}

TimedGuiDelete() {
    global gTimedWindows
    if !(idx := TimedGuiSelectedIndex())
        return
    item := gTimedWindows.RemoveAt(idx)
    TrayTip "Timer eliminado", item["title"], 2
    RebuildTimedWindowsGui()
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

; HKEnabled() permite apagarlo desde el menú de hotkeys: este #HotIf no es
; alcanzable por Hotkey(), así que se guarda con una flag (tipo "flag").
#HotIf HKEnabled("create_txt.instantTxt") && IsExplorerActive()
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
; Activar / desactivar hotkeys  (botón "Hotkeys…" en la GUI del Manager)
; ============================================================================
;   Permite apagar hotkeys individuales o secciones enteras sin suspender ni
;   matar el script. Apagar usa Hotkey()/Hotstring() con "Off", que devuelve la
;   tecla a su comportamiento nativo de Windows, en lugar de dejarla atrapada
;   por un handler que no hace nada.
;
;   El estado vive solo en memoria: un Reload devuelve todo a activado.
;
;   Tipos de ítem:
;     "hotkey"    -> Hotkey(hk, , "On"/"Off")
;     "hotstring" -> Hotstring(hk, , "On"/"Off")
;     "flag"      -> lo lee HKEnabled() desde un #HotIf ya existente
;
;   Los hotkeys definidos dentro de un #HotIf no son alcanzables por Hotkey(),
;   porque la directiva genera una función anónima que no se puede reproducir
;   con HotIf(). Por eso: los chords (*e, *i) se apagan desde su tecla de
;   entrada (Ctrl+Alt+5 y Win+Alt+U), ~Escape/~!Space del Manager quedan fuera
;   de la lista, y #+MButton (createTXT instantáneo) usa el tipo "flag".
;
;   MANTENIMIENTO: gHKSections repite hotkeys y descripciones que también viven
;   en AHK_Unified_Master_Referencia_ie.html, o sea que hay tres fuentes de
;   verdad (código, HTML, este registro). Los campos title/src/label/desc están
;   pensados para poder generar esa referencia desde acá más adelante y dejar
;   una sola fuente.
; ============================================================================

global gHKState := Map()        ; "seccion.item" -> false cuando está apagado
global gHKGui := ""             ; ventana del menú (singleton)
global gHKTree := ""            ; el TreeView con los checkboxes
global gHKNodes := Map()        ; itemId del TreeView -> descriptor del nodo
global gHKChildren := Map()     ; itemId de sección   -> [itemIds de sus hijos]
global gHKBusy := false         ; guarda de reentrada para el evento ItemCheck

global gHKSections := [
    { id: "ayuda", title: "Ayuda / esta referencia", src: "", items: [
        { id: "ref", type: "hotkey", hk: "#+SC00C", label: "Win + Shift + ?",
          desc: "Abre/cierra la ventana de referencia de comandos" } ] },

    { id: "arrows", title: "Teclado y navegación", src: "arrows-keystrokes.ahk", items: [
        { id: "up",    type: "hotkey", hk: "^!W",        label: "Ctrl + Alt + W",        desc: "Envía Flecha Arriba" },
        { id: "down",  type: "hotkey", hk: "^!S",        label: "Ctrl + Alt + S",        desc: "Envía Flecha Abajo" },
        { id: "enter", type: "hotkey", hk: "<^CapsLock", label: "Ctrl izq + Bloq Mayús", desc: "Envía Enter (anula el toggle de Mayús)" } ] },

    { id: "autodate", title: "Fechas y horas rápidas (hotstrings)", src: "autodate.ahk", items: [
        { id: "kddd", type: "hotstring", hk: ":R*?:kddd", label: "kddd", desc: "Fecha dd/MM/yy" },
        { id: "ksss", type: "hotstring", hk: ":R*?:ksss", label: "ksss", desc: "Fecha dd/MM" },
        { id: "knnn", type: "hotstring", hk: ":R*?:knnn", label: "knnn", desc: "Nombre del día actual" },
        { id: "kxxx", type: "hotstring", hk: ":R*?:kxxx", label: "kxxx", desc: "Fecha y hora yyMMdd_HHmm" },
        { id: "kaaa", type: "hotstring", hk: ":R*?:kaaa", label: "kaaa", desc: "Fecha yyMMdd" },
        { id: "kjjd", type: "hotstring", hk: ":R*?:kjjd", label: "kjjd", desc: "Fecha dd-MM-yy" },
        { id: "kyyy", type: "hotstring", hk: ":R*?:kyyy", label: "kyyy", desc: "Fecha y hora dd-MM-yy HH:mm" },
        { id: "khhh", type: "hotstring", hk: ":R*?:khhh", label: "khhh", desc: "Hora HH:mm" } ] },

    { id: "chord", title: "Texto rápido (chord)", src: "Nuevo", items: [
        { id: "endflag", type: "hotkey", hk: "^!5", label: "Ctrl + Alt + 5, luego E",
          desc: "Escribe el texto literal %%end flag (la E debe llegar en menos de 2 s)" } ] },

    { id: "simbolos", title: "Símbolos rápidos", src: "backwards-slash.ahk · checkmark.ahk · dashes.ahk", items: [
        { id: "slash",   type: "hotkey", hk: "+NumpadDiv", label: "Shift + Numpad /", desc: "Envía la barra invertida \" },
        { id: "check",   type: "hotkey", hk: "!^F10",      label: "Ctrl + Alt + F10", desc: "Envía el símbolo de check ✔" },
        { id: "arrowup", type: "hotkey", hk: "!^F9",       label: "Ctrl + Alt + F9",  desc: "Envía la flecha arriba ↑" },
        { id: "semicolon", type: "hotkey", hk: "^NumpadDot", label: "Ctrl + Numpad .", desc: "Envía un punto y coma `;" },
        { id: "emdash",  type: "hotkey", hk: "^NumpadSub", label: "Ctrl + Numpad -",  desc: "Envía un guion largo — (em dash)" },
        { id: "endash",  type: "hotkey", hk: "!NumpadSub", label: "Alt + Numpad -",   desc: "Envía un guion medio – (en dash)" } ] },

    { id: "brightness", title: "Brillo de pantalla", src: "brightness.ahk", items: [
        { id: "down", type: "hotkey", hk: "#,", label: "Win + ,", desc: "Baja el brillo 5 puntos (mínimo 10)" },
        { id: "up",   type: "hotkey", hk: "#.", label: "Win + .", desc: "Sube el brillo 5 puntos (máximo 100)" } ] },

    { id: "calendar", title: "Calendario emergente", src: "calendar.ahk", items: [
        { id: "show", type: "hotkey", hk: "#Numpad5", label: "Win + Numpad 5",
          desc: "Abre un calendario para copiar una fecha al portapapeles" } ] },

    { id: "logger", title: "Registro de texto / log", src: "logger.ahk", items: [
        { id: "stamp", type: "hotkey", hk: "!^F7", label: "Ctrl + Alt + F7",
          desc: "Escribe separador + fecha/hora + separador" },
        { id: "sep",   type: "hotkey", hk: "!^l",  label: "Ctrl + Alt + L",
          desc: "Espera 1 o 2 y escribe un separador corto o largo" } ] },

    { id: "move_resize", title: "Mover y redimensionar ventanas con el mouse", src: "move_resize.ahk", items: [
        { id: "move",   type: "hotkey", hk: "Alt & LButton", label: "Alt + Click Izq (mantener)",
          desc: "Arrastra la ventana que está bajo el cursor" },
        { id: "resize", type: "hotkey", hk: "Alt & RButton", label: "Alt + Click Der (mantener)",
          desc: "Redimensiona la ventana bajo el cursor según el cuadrante" } ] },

    { id: "mute", title: "Silenciar audio", src: "mute.ahk", items: [
        { id: "mute", type: "hotkey", hk: "#Numpad3", label: "Win + Numpad 3",
          desc: "Mutea el audio si no estaba muteado (no alterna)" } ] },

    { id: "idle", title: "Ocultar al escritorio por inactividad", src: "idle_edit_v2.ahk", items: [
        { id: "config", type: "hotkey", hk: "#NumpadMult", label: "Win + Numpad *",
          desc: "Fija los minutos de inactividad tras los que se oculta todo (0 = off)" } ] },

    { id: "stimer", title: "Timer → Win+Alt+S", src: "!_STARTUP_merged.ahk", items: [
        { id: "open", type: "hotkey", hk: "#!u", label: "Win + Alt + U, luego I",
          desc: "Abre la ventana del temporizador (la I debe llegar en menos de 1 s)" } ] },

    { id: "media", title: "Multimedia y volumen", src: "pauseplay.ahk", items: [
        { id: "playpause",  type: "hotkey", hk: "^!A",             label: "Ctrl + Alt + A",        desc: "Play / Pausa" },
        { id: "playpause2", type: "hotkey", hk: "RAlt & Numpad5",  label: "AltGr + Numpad 5",      desc: "Play / Pausa" },
        { id: "prev",       type: "hotkey", hk: "^!Left",          label: "Ctrl + Alt + Izquierda", desc: "Pista anterior" },
        { id: "next",       type: "hotkey", hk: "^!Right",         label: "Ctrl + Alt + Derecha",  desc: "Pista siguiente" },
        { id: "prev2",      type: "hotkey", hk: "^!Numpad4",       label: "Ctrl + Alt + Numpad 4", desc: "Pista anterior" },
        { id: "next2",      type: "hotkey", hk: "^!Numpad6",       label: "Ctrl + Alt + Numpad 6", desc: "Pista siguiente" },
        { id: "mute",       type: "hotkey", hk: "^!Numpad3",       label: "Ctrl + Alt + Numpad 3", desc: "Mute de volumen" },
        { id: "volup",      type: "hotkey", hk: "^!NumpadAdd",     label: "Ctrl + Alt + Numpad +", desc: "Sube el volumen" },
        { id: "voldown",    type: "hotkey", hk: "^!NumpadSub",     label: "Ctrl + Alt + Numpad -", desc: "Baja el volumen" },
        { id: "volup2",     type: "hotkey", hk: "^!Numpad8",       label: "Ctrl + Alt + Numpad 8", desc: "Sube el volumen" },
        { id: "voldown2",   type: "hotkey", hk: "^!Numpad2",       label: "Ctrl + Alt + Numpad 2", desc: "Baja el volumen" } ] },

    { id: "timer_media", title: "Timer para PausePlayMedia", src: "Nuevo", items: [
	{ id: "timer_playpause", type: "hotkey", hk:"#!u", label: "Win + Alt + U, luego A",
	  desc: "Abre la ventana del temporizador de pausa/reanudar (la A debe llegar en menos de 2 s)" } ] },

    { id: "tabsel", title: "Tabulación y selección", src: "right_tab.ahk · selectcellcontent.ahk · volume.ahk", items: [
        { id: "tab",     type: "hotkey", hk: "RCtrl & Numpad5", label: "Ctrl der + Numpad 5", desc: "Envía Tab" },
        { id: "cell",    type: "hotkey", hk: "!F2",             label: "Alt + F2",            desc: "Backspace + Ctrl+Z (limpia una celda y deshace)" },
        { id: "volup",   type: "hotkey", hk: "#WheelUp",        label: "Win + Rueda arriba",  desc: "Sube el volumen" },
        { id: "voldown", type: "hotkey", hk: "#WheelDown",      label: "Win + Rueda abajo",   desc: "Baja el volumen" } ] },

    { id: "macro_name", title: "Macro de nombre/firma", src: "macro_insta_name.ahk", items: [
        { id: "main", type: "hotkey", hk: "^!x",  label: "Ctrl + Alt + X",
          desc: "Secuencia Esc, Alt+Shift+Fin, Ctrl+A, Ctrl+V, Tab, Enter, Shift+A" },
        { id: "alt",  type: "hotkey", hk: "^!+x", label: "Ctrl + Alt + Shift + X",
          desc: "Secuencia Alt+Shift+H, Flecha Abajo, Enter" } ] },

    { id: "wise", title: "Wise Reminder", src: "find_wise_reminder.ahk", items: [
        { id: "find", type: "hotkey", hk: "#z", label: "Win + Z",
          desc: "Activa Wise Reminder (lo rescata de la bandeja o lo lanza)" } ] },

    { id: "hourglass", title: "Hourglass", src: "open_hourglass.ahk", items: [
        { id: "open", type: "hotkey", hk: "#^+z", label: "Win + Ctrl + Shift + Z",
          desc: "Activa Hourglass, o lo lanza si no está corriendo" } ] },

    { id: "open_program", title: "Abrir programa", src: "open-program-GUI.ahk", items: [
        { id: "gui", type: "hotkey", hk: "^#p", label: "Ctrl + Win + P",
          desc: "Abre la ventana con un botón por programa configurado" } ] },

    { id: "gcal", title: "Buscar pestaña de Google Calendar", src: "find_google_calendar.ahk", items: [
        { id: "find", type: "hotkey", hk: "+NumpadEnter", label: "Shift + Numpad Enter",
          desc: "Busca y activa la pestaña de Google Calendar en el navegador" } ] },

    { id: "kill_all", title: "Cerrar ventanas masivamente", src: "kill_all.ahk", items: [
        { id: "kill", type: "hotkey", hk: "^+!k", label: "Ctrl + Shift + Alt + K",
          desc: "Cierra todas las ventanas visibles excepto Chrome/Edge y el escritorio" } ] },

    { id: "show_time", title: "Atajo Mostrar hora", src: "Show_Time.ahk", items: [
        { id: "clock", type: "hotkey", hk: "#c", label: "Win + C",
          desc: "Win+B, 5 veces Derecha y Enter para llegar al reloj" } ] },

    { id: "cycler", title: "Ciclador de ventanas guardadas", src: "Cycler_Windows_v3.ahk", items: [
        { id: "add",    type: "hotkey", hk: "#F5",  label: "Win + F5",         desc: "Guarda la ventana activa en la lista" },
        { id: "cycle",  type: "hotkey", hk: "#F4",  label: "Win + F4",         desc: "Cicla a la siguiente ventana guardada" },
        { id: "remove", type: "hotkey", hk: "#+F5", label: "Win + Shift + F5", desc: "Quita la ventana activa de la lista" },
        { id: "list",   type: "hotkey", hk: "#+F4", label: "Win + Shift + F4", desc: "Muestra la lista flotante de ventanas guardadas" } ] },

    { id: "sheets", title: "Accesos a Google Sheets", src: "url_chrome.ahk", items: [
        { id: "window", type: "hotkey", hk: "^!g",  label: "Ctrl + Alt + G",         desc: "Abre la planilla en una ventana nueva de Chrome" },
        { id: "tab",    type: "hotkey", hk: "^!+g", label: "Ctrl + Alt + Shift + G", desc: "Abre la planilla en una pestaña nueva de Chrome" } ] },

    { id: "conv_count", title: "Contador de conversación", src: "convCount.ahk", items: [
        { id: "add",   type: "hotkey", hk: "^!#t", label: "Ctrl + Alt + Win + T",
          desc: "Incrementa el contador y escribe el marcador de texto" },
        { id: "reset", type: "hotkey", hk: "^!#r", label: "Ctrl + Alt + Win + R",
          desc: "Reinicia el contador; doble pulsación abre la ventana para fijarlo" } ] },

    { id: "create_txt", title: "Crear archivos rápido", src: "createTXT.ahk", items: [
        { id: "gui",        type: "hotkey", hk: "#+t", label: "Win + Shift + T",
          desc: "Abre la ventana para crear un archivo en la carpeta del Explorador" },
        { id: "instantTxt", type: "flag",   hk: "",    label: "Win + Shift + Click central",
          desc: "Crea al instante New Text Document.txt (solo con el Explorador activo)" } ] },

    { id: "resize_kb", title: "Mover/redimensionar con teclado", src: "resize.ahk", items: [
        { id: "small",  type: "hotkey", hk: "^!MButton", label: "Ctrl + Alt + Click central",
          desc: "Redimensiona la ventana activa a 300x300 px" },
        { id: "center", type: "hotkey", hk: "^!RButton", label: "Ctrl + Alt + Click derecho",
          desc: "Restaura y centra la ventana activa" } ] },

    { id: "manager", title: "AHK Manager", src: "AHK_Manager.ahk", items: [
        { id: "show", type: "hotkey", hk: "^!r", label: "Ctrl + Alt + R", protected: true,
          desc: "Muestra la ventana del Manager (no se puede apagar)" } ] },

    { id: "pruebas", title: "Pruebas manuales", src: "", items: [
        { id: "youtube", type: "hotkey", hk: "#ñ", label: "Win + Ñ", desc: "Abre youtube.com" } ] }
]

; Estado de una entrada. Todo arranca activado, así que la ausencia de clave
; equivale a "prendido".
HKEnabled(key) {
    global gHKState
    if !IsSet(gHKState)
        return true
    return !gHKState.Has(key) || gHKState[key]
}

; Aplica el estado a una entrada. Devuelve "" si salió bien, o el mensaje de
; error (típicamente porque el string de gHKSections no matchea la definición
; real del hotkey).
HKApply(entry, key, enabled) {
    global gHKState
    switch entry.type {
        case "hotkey":
            HotIf()   ; contexto global explícito: apunta a la variante sin #HotIf
            try
                Hotkey(entry.hk, , enabled ? "On" : "Off")
            catch as err
                return err.Message
        case "hotstring":
            try
                Hotstring(entry.hk, , enabled ? "On" : "Off")
            catch as err
                return err.Message
        case "flag":
            ; no hay nada que registrar: HKEnabled() lo lee desde el #HotIf
    }
    gHKState[key] := enabled
    return ""
}

HKToggleTip(msg) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -2500)
}

HKAddButton(g, opts, text, cb) {
    btn := g.AddButton(opts, text)
    btn.OnEvent("Click", cb)
    btn.SetFont("s10", "Calibri")
    return btn
}

ShowHotkeyTogglesGui() {
    global gHKGui, gHKTree, gHKNodes, gHKChildren, gHKSections

    ; Toggle: si ya está visible, se cierra. La ventana se construye una sola vez.
    if (gHKGui != "") {
        if DllCall("IsWindowVisible", "ptr", gHKGui.Hwnd)
            gHKGui.Hide()
        else
            gHKGui.Show()
        return
    }

    gHKNodes := Map()
    gHKChildren := Map()

    gHKGui := Gui("+AlwaysOnTop", "Hotkeys del master — activar / desactivar")
    gHKGui.BackColor := "313131"
    gHKGui.Add("Text", "x10 y8 w720 h24 cc47cff", "Hotkeys del script maestro:").SetFont("s13 Bold", "Calibri")
    gHKGui.Add("Text", "x10 y+2 w720 h18 cffffff",
        "Destildá un hotkey para devolverle su comportamiento nativo de Windows. "
        "Destildar una sección apaga el bloque completo. El estado se pierde al recargar el script.")
        .SetFont("s9", "Calibri")

    gHKTree := gHKGui.Add("TreeView", "x10 y+6 w720 h460 Checked Background313131 cFFFFFF")
    gHKTree.SetFont("s9.5", "Calibri")

    ; Al construir, cada entrada se reaplica con su estado actual. Es un no-op
    ; funcional, pero valida que el string de hotkey exista de verdad: las que
    ; fallan se marcan con [!] en lugar de quedar como un checkbox muerto.
    badCount := 0
    for sec in gHKSections {
        secNode := gHKTree.Add(sec.title (sec.src = "" ? "" : "   (" sec.src ")"), 0, "Check")
        gHKNodes[secNode] := { kind: "section", sec: sec }
        gHKChildren[secNode] := []

        for entry in sec.items {
            key := sec.id "." entry.id
            err := HKApply(entry, key, HKEnabled(key))
            isBad := (err != "")
            label := entry.label "  —  " entry.desc
            if isBad {
                label .= "   [!] " err
                badCount++
            }
            itemNode := gHKTree.Add(label, secNode, HKEnabled(key) ? "Check" : "")
            gHKNodes[itemNode] := { kind: "item", key: key, entry: entry, bad: isBad,
                                    protected: entry.HasOwnProp("protected") && entry.protected }
            gHKChildren[secNode].Push(itemNode)
        }
        HKSyncSection(secNode)
    }

    gHKTree.OnEvent("ItemCheck", HKTreeItemCheck)

    HKAddButton(gHKGui, "x10 y+8 w140", "Todo On",       (*) => HKSetAll(true))
    HKAddButton(gHKGui, "x+5 yp  w140", "Todo Off",      (*) => HKSetAll(false))
    HKAddButton(gHKGui, "x+5 yp  w140", "Expandir todo", (*) => HKExpandAll(true))
    HKAddButton(gHKGui, "x+5 yp  w140", "Colapsar todo", (*) => HKExpandAll(false))
    HKAddButton(gHKGui, "x+5 yp  w140", "Cerrar",        (*) => gHKGui.Hide())

    if (badCount > 0)
        gHKGui.Add("Text", "x10 y+6 w720 cffb86c",
            badCount " entrada(s) marcada(s) con [!]: el string de gHKSections no matchea "
            "la definición real del hotkey y no se puede apagar.").SetFont("s9", "Calibri")

    gHKGui.OnEvent("Close",  (*) => gHKGui.Hide())
    gHKGui.OnEvent("Escape", (*) => gHKGui.Hide())
    gHKGui.Show()
}

; El TreeView de AHK no tiene checkbox tri-estado, así que la sección queda
; tildada mientras al menos uno de sus hijos esté activo.
HKSyncSection(secNode) {
    global gHKTree, gHKNodes, gHKChildren
    if !gHKChildren.Has(secNode)
        return
    anyOn := false
    for child in gHKChildren[secNode] {
        cn := gHKNodes[child]
        if (cn.bad || HKEnabled(cn.key)) {
            anyOn := true
            break
        }
    }
    gHKTree.Modify(secNode, anyOn ? "Check" : "-Check")
}

; Aplica el estado de un hijo, respetando protegidos e inválidos. Devuelve el
; estado que quedó realmente.
HKApplyChild(child, enabled) {
    global gHKTree, gHKNodes
    cn := gHKNodes[child]
    if (cn.bad || (cn.protected && !enabled)) {
        gHKTree.Modify(child, "Check")
        return true
    }
    HKApply(cn.entry, cn.key, enabled)
    gHKTree.Modify(child, enabled ? "Check" : "-Check")
    return enabled
}

HKTreeItemCheck(tv, item, checked) {
    global gHKNodes, gHKChildren, gHKBusy, gHKTree

    ; Modify() vuelve a disparar ItemCheck: sin esta guarda, la cascada de una
    ; sección con 8 hijos se convierte en una tormenta de eventos.
    if (gHKBusy || !gHKNodes.Has(item))
        return
    gHKBusy := true

    node := gHKNodes[item]
    if (node.kind = "section") {
        for child in gHKChildren[item]
            HKApplyChild(child, checked)
        HKSyncSection(item)
    } else if (node.bad) {
        gHKTree.Modify(item, "Check")
        HKToggleTip("Ese hotkey no se encontró en el script (ver [!]): no se puede apagar.")
    } else if (node.protected && !checked) {
        gHKTree.Modify(item, "Check")
        HKToggleTip("Ctrl+Alt+R no se puede apagar: es la única forma de reabrir este menú.")
    } else {
        HKApply(node.entry, node.key, checked)
        ; Redundante cuando lo dispara un clic (Windows ya movió el tilde), pero
        ; deja el checkbox y el estado siempre consistentes.
        gHKTree.Modify(item, checked ? "Check" : "-Check")
        HKSyncSection(gHKTree.GetParent(item))
    }

    gHKBusy := false
}

HKSetAll(enabled) {
    global gHKChildren, gHKBusy
    gHKBusy := true
    for secNode, kids in gHKChildren {
        for child in kids
            HKApplyChild(child, enabled)
        HKSyncSection(secNode)
    }
    gHKBusy := false
}

HKExpandAll(expand) {
    global gHKTree, gHKChildren
    for secNode, kids in gHKChildren
        gHKTree.Modify(secNode, expand ? "Expand" : "-Expand")
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
AddButton("x10", "y+5", "w170", "Macro Recorder", (*) => OpenMacroRecorder())
AddButton("x+5", "yp",  "w170", "Hotkeys…",       (*) => ShowHotkeyTogglesGui())

MyGui.OnEvent("Close", (*) => MyGui.Hide())
MyGui.Show("w375 h365")
Refresh()

; Escape / Alt+Espacio solo afectan cuando la ventana del Manager está activa
#HotIf WinActive("ahk_id " MyGui.Hwnd)
~Escape::MyGui.Hide()   ; solo oculta la ventana: para cerrar el script está "Quit"
~!Space::Reload
#HotIf

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

; Launches MacroRecorder.ahk as its own process — it must stay separate,
; because while recording it registers a hotkey for every virtual key and
; would collide with this script's own bindings.
; Alt+F1 opens its window; see README_MacroRecorder.md.
OpenMacroRecorder() {
    macroRecorderPath := "C:\autohotkey\MacroRecorder.ahk"
    if !FileExist(macroRecorderPath) {
        MsgBox("Unable to find MacroRecorder.ahk at: " macroRecorderPath)
        return
    }
    ; already running? just bring its window up
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    if WinExist(macroRecorderPath " ahk_class AutoHotkey") {
        Send "!{F1}"
        return
    }
    Run('"' A_AhkPath '" "' macroRecorderPath '"')
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