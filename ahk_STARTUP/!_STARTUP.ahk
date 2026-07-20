; ============================================================
;  !_STARTUP.ahk  --  Script de arranque (AutoHotkey v1)
;  Limpieza conservadora: mismo comportamiento, codigo unificado.
; ============================================================

#NoEnv
#SingleInstance Force
#Persistent
#Warn All, Off
#ErrorStdOut
SetWorkingDir %A_ScriptDir%

; Datos personales (mails, DNI, telefono, legajos) en archivo aparte.
; *i = opcional: si el archivo no existe, no da error.
#Include *i %A_ScriptDir%\!_personal.ahk

; Estado del contador de conversacion (ver seccion al final).
counter := 0
lastControlPress := 0

; Estado del timer -> Win+Alt+S (ver seccion "Timer -> Win+Alt+S" al final).
timerMinutes := 0            ; ultimo valor usado en la GUI (minutos)
timerSeconds := 30           ; ultimo valor usado en la GUI (segundos)
inactivityMinutes := 10      ; auto-envio por inactividad; 0 = desactivado
inactivityFired := false     ; evita reenvios dentro del mismo periodo inactivo
waitingForSTimerKey := false ; true tras Win+Alt+U, esperando la "I" (< 1 s)
SetTimer, CheckInactivity, 1000

; ============================================================
;  Multimedia / Volumen
; ============================================================

^!Left::Send  {Media_Prev}
^!a::Send     {Media_Play_Pause}
^!Right::Send {Media_Next}

RAlt & Numpad2::Send {Volume_Down}
RAlt & Numpad8::Send {Volume_Up}
RAlt & Numpad3::Send {Volume_Mute}
RAlt & Numpad4::Send {Media_Prev}
RAlt & Numpad6::Send {Media_Next}
RAlt & Numpad5::Send {Media_Play_Pause}

LWin & WheelUp::Send   {Volume_Up}
LWin & WheelDown::Send {Volume_Down}

; ============================================================
;  Simbolos y teclas
; ============================================================

^!.::Send {>}
^!,::Send {<}
^>NumpadDot::Send {,}

^!W::Send {Up}
^!S::Send {Down}

^NumpadSub::Send {–}   ; guion corto
!NumpadSub::Send {—}   ; guion largo

RAlt & {::WinMaximize, A   ; RAlt + {  -> maximizar ventana activa
RAlt & -::WinMinimize, A   ; RAlt + -  -> minimizar ventana activa

+NumpadDiv::Send \         ; Shift + Numpad/  -> "\"
RCtrl & Numpad5::Send {Tab}

; ============================================================
;  Matlab: ejecutar linea (Alt+F9)
; ============================================================

!F9::
    SendInput {End}
    Sleep 50
    SendInput +{Home}      ; seleccionar contenido de la linea
    Sleep 50
    SendInput {F9}
Return

; ============================================================
;  Autotexto: simbolos y rutas
; ============================================================

:R*?:k6ini::<
:R*?:k6fin::>

::kuser::%userprofile%
::kapp::%appdata%

; ============================================================
;  Autotexto: fecha / hora
;  Todas las variantes usan la funcion SendNow() (abajo).
;  Firma: SendNow(formato, offsetDias := 0, titleCase := false)
; ============================================================

:X*?:knnn::SendNow("dddd", 0, true)          ; dia de la semana (Title)
:X*?:kddd::SendNow("dd/MM/yy")
:X:kdd1::SendNow("dd/MM/yy", 1)              ; manana
:X:kd1d::SendNow("dd/MM/yy", -1)             ; ayer
:X*?:ksss::SendNow("dd/MM")                  ; simplificado
:X*?:skkk::SendNow("MM.dd")                  ; simplificado inverso
:X:kss1::SendNow("dd/MM", 1)                 ; manana simplificado
:X:ks1s::SendNow("dd/MM", -1)                ; ayer simplificado
:X*?:kmmd::SendNow("MM.dd")                  ; MonthDay
:X*?:kjjd::SendNow("dd-MM-yy")
:X*?:kjj1::SendNow("dd-MM-yy", 1)            ; manana
:X*?:kyyy::SendNow("dd-MM-yy HH:mm")
:X*?:khhh::SendNow("HH:mm")
:X*?:kaaa::SendNow("yyMMdd")
:X*?:kxxx::SendNow("yyMMddHHmmss")
:X*?:kzzz::SendNow("yy_MM_dd_HHmm")
:X*?:khdx::SendNow("yy-MM-dd_HH-mm")

SendNow(fmt, offsetDays := 0, titleCase := false) {
    t := A_Now
    if (offsetDays != 0)
        t += offsetDays, Days
    FormatTime, out, %t%, %fmt%
    if (titleCase)
        out := Format("{:T}", out)
    SendInput %out%
}

; ============================================================
;  Calendario (Win + Numpad5)
;  Doble clic o Enter = copia la fecha al portapapeles (dd/MM/yyyy)
; ============================================================

#Numpad5::
    Gui, Cal:New
    Gui, Cal:+AlwaysOnTop +ToolWindow
    Gui, Cal:Color, FFFFFF
    Gui, Cal:Font, s10, Segoe UI

    Gui, Cal:Add, MonthCal, x10 y35 vFechaSeleccionada gOnCalendario

    ; Medir el ancho/alto real del calendario para encajar todo a su medida
    GuiControlGet, cal, Cal:Pos, FechaSeleccionada
    margin := 10
    gap := 10
    btnW := (calW - gap) // 2          ; dos botones que suman el ancho del calendario
    btnY := 35 + calH + margin
    btn2X := margin + btnW + gap

    Gui, Cal:Add, Text, x%margin% y10 w%calW% Center, Selecciona una fecha
    Gui, Cal:Add, Button, x%margin% y%btnY% w%btnW% gCopiarFecha Default, Copiar (Enter)
    Gui, Cal:Add, Button, x%btn2X% y%btnY% w%btnW% gCerrarCalendario, Cancelar (Esc)

    winW := calW + (margin * 2)
    Gui, Cal:Show, w%winW%, Calendario
Return

; Doble clic en una fecha = copiar directo
OnCalendario:
    if (A_GuiEvent = "DoubleClick")
        Gosub, CopiarFecha
Return

CopiarFecha:
    Gui, Cal:Submit, NoHide
    FormatTime, Fecha, %FechaSeleccionada%, dd/MM/yyyy
    Clipboard := Fecha
    ToolTip, Copiado: %Fecha%
    SetTimer, QuitarTooltip, 2000
    Gui, Cal:Destroy
Return

CerrarCalendario:
CalGuiClose:
CalGuiEscape:
    Gui, Cal:Destroy
Return

QuitarTooltip:
    SetTimer, QuitarTooltip, Off
    ToolTip
Return

; ============================================================
;  Convertir texto
; ============================================================

^F2::ReplaceClipSpaces("_")     ; espacios -> _
^+F2::ReplaceClipSpaces("-")    ; espacios -> -

ReplaceClipSpaces(repl) {
    Old := ClipboardAll
    Clipboard := ""
    Send ^c
    ClipWait, 2
    Clipboard := StrReplace(Clipboard, " ", repl)
    Send ^v
    Clipboard := Old
}

^F3::SendCaseFromClip("U")       ; a MAYUSCULAS
^+F3::SendCaseFromClip("L")      ; a minusculas
^F4::SendCaseFromClip("T")       ; Capitalizado (Title)

SendCaseFromClip(mode) {
    Old := ClipboardAll
    if (mode = "U")
        StringUpper out, Clipboard
    else if (mode = "L")
        StringLower out, Clipboard
    else
        StringUpper out, Clipboard, T
    Send %out%
    Clipboard := Old             ; restaurar portapapeles
}

^+F4::                           ; invertir mayus/minus
    Lab_Invert_Char_Out := ""
    Loop % StrLen(Clipboard) {
        Lab_Invert_Char := SubStr(Clipboard, A_Index, 1)
        if Lab_Invert_Char is upper
            Lab_Invert_Char_Out := Lab_Invert_Char_Out Chr(Asc(Lab_Invert_Char) + 32)
        else if Lab_Invert_Char is lower
            Lab_Invert_Char_Out := Lab_Invert_Char_Out Chr(Asc(Lab_Invert_Char) - 32)
        else
            Lab_Invert_Char_Out := Lab_Invert_Char_Out Lab_Invert_Char
    }
    Send %Lab_Invert_Char_Out%
Return

; ============================================================
;  Lanzar / activar: WiseReminder (Win + |)
; ============================================================

#|::
    Process, Exist, WiseReminder.exe
    if (ErrorLevel != 0) {                          ; esta corriendo
        WinGet, WinState, MinMax, ahk_exe WiseReminder.exe
        if (WinState = "") {                        ; minimizado a la bandeja
            SendInput #b
            SendInput {Enter}
            Sleep 50
            SendInput {Up}
            SendInput w
            Sleep 60
            SendInput {Enter}
        } else {
            WinActivate, ahk_exe WiseReminder.exe
        }
    } else {                                        ; NO esta corriendo
        Run, "C:\Program Files (x86)\Wise\Wise Reminder\WiseReminder.exe"
    }
Return

; ============================================================
;  Fix PDF Links (Ctrl+Alt+D)
; ============================================================

^!d::
    SendInput !d
    Sleep 50
    SendInput {Home}
    Sleep 50
    Send ^{Right}
    Sleep 10
    Send ^{Right}
    Sleep 10
    Send ^{Right}
    SendInput +{End}
    Sleep 50
    SendInput ^c
    Sleep 10
    SendInput ^a
    SendInput ^v
    SendInput {Enter}
Return

; ============================================================
;  Caps como Enter / Tab
; ============================================================

^CapsLock::Send {Enter}

^+CapsLock::
    Send {Tab}
    Send {Tab}
    Send {Tab}
    Send {Tab}
    Sleep 100
    Send {Enter}
Return

; ============================================================
;  Macros Instagram
; ============================================================

^!x::
    SendInput !+{End}
    Sleep 1500
    SendInput ^a
    Sleep 50
    SendInput ^v
    Sleep 50
    SendInput {Tab}
    Sleep 50
    SendInput {Enter}
    Sleep 700
    SendInput +a
Return

^!+x::
    SendInput !+{h}
    Sleep 1000
    SendInput {Down}
    Sleep 300
    SendInput {Enter}
    Sleep 50
Return

; ============================================================
;  Lanzar / activar: Hourglass (Win + Shift + |)
; ============================================================

#+|::
    Process, Exist, Hourglass.exe
    if (ErrorLevel != 0)                            ; esta corriendo
        WinActivate, ahk_exe Hourglass.exe
    else                                            ; NO esta corriendo
        Run, "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Hourglass\Hourglass.lnk"
Return

; ============================================================
;  Kill All (Ctrl+Shift+Alt+K): cierra ventanas visibles
;  (salta escritorio y navegadores)
; ============================================================

^+!k::
    WinGet, idList, List
    Loop, % idList {
        this_id := idList%A_Index%
        WinGetTitle, title, ahk_id %this_id%
        WinGetClass, class, ahk_id %this_id%
        WinGet, exe, ProcessName, ahk_id %this_id%
        WinGet, style, Style, ahk_id %this_id%

        if (class = "Progman" or class = "WorkerW")
            continue
        if (exe = "chrome.exe" or exe = "msedge.exe" or exe = "firefox.exe")
            continue
        if (title = "")
            continue

        if (style & 0x10000000) {                   ; solo ventanas visibles
            WinClose, ahk_id %this_id%
            Sleep, 100
        }
    }
Return

; ============================================================
;  Lanzar Macro Recorder (Win + F3)
; ============================================================

#F3::Run, "C:\Users\fzpat\Desktop\ahk\Macro.Recorder.exe"

; ============================================================
;  Redimensionar / centrar ventana
;    Ctrl+Alt+Boton central  -> redimensiona la ventana activa a 300x300
;    Ctrl+Alt+Boton derecho  -> restaura y centra la ventana en pantalla
; ============================================================

^!MButton::
    WinGet, winID, ID, A
    if (winID)
        WinMove, ahk_id %winID%, , , , 300, 300   ; mantiene posicion, fija tamano 300x300
Return

^!RButton::
    WinGet, winID, ID, A
    if (winID) {
        WinRestore, ahk_id %winID%                ; restaura si esta min/maximizada
        WinGetPos, X, Y, W, H, ahk_id %winID%
        newX := (A_ScreenWidth  - W) // 2
        newY := (A_ScreenHeight - H) // 2
        WinMove, ahk_id %winID%, , newX, newY      ; centra en la pantalla primaria
    }
Return

; ============================================================
;  Contador de inputs de conversacion
;    Ctrl+Alt+Win+T  -> inserta marcador con n° y timestamp
;    Ctrl+Alt+Win+R  -> 1 vez: resetea contador
;                       2 veces (<700ms): abre GUI manual
; ============================================================

^!#t::
    counter += 1
    FormatTime, ts, %A_Now%, dd/MM/yyyy - [HH:mm]
    text := "Conversation User Input n° " counter " @ " ts " . "
    SendInput {Text}%text%
Return

^!#r::
    now := A_TickCount
    if (lastControlPress && (now - lastControlPress <= 700)) {
        lastControlPress := 0
        Gosub, OpenCounterGui
        return
    }
    counter := 0
    lastControlPress := now
    ToolTip, Conversation counter reset
    SetTimer, QuitarTooltip, -1000
Return

OpenCounterGui:
    Gui, Counter:New, +AlwaysOnTop, Set conversation counter
    Gui, Counter:Font, s10, Segoe UI
    Gui, Counter:Add, Text, w370, Set current counter number:
    Gui, Counter:Add, Edit, w370 Number vCounterEdit hwndCounterEditHwnd, %counter%
    Gui, Counter:Add, Button, Default w120 gCounterSave, Save
    Gui, Counter:Add, Button, x+10 w120 gCounterCancel, Cancel
    Gui, Counter:Add, Button, x+10 w120 gCounterAsk, Ask
    Gui, Counter:Show
    GuiControl, Counter:Focus, CounterEdit
    SendMessage, 0xB1, 0, -1, , ahk_id %CounterEditHwnd%   ; EM_SETSEL: seleccionar todo
Return

CounterSave:
    Gui, Counter:Submit, NoHide
    value := Trim(CounterEdit)
    if !RegExMatch(value, "^\d+$") {
        MsgBox, Please enter a whole number, for example: 0, 1, 25.
        return
    }
    counter := value + 0
    Gui, Counter:Destroy
    ToolTip, Conversation counter set to %counter%
    SetTimer, QuitarTooltip, -1000
Return

CounterAsk:
    Clipboard := "En que numero de input de chat estoy en esta conversacion (incluyendo este)?"
    Gui, Counter:Destroy
    ToolTip, Question copied to clipboard
    SetTimer, QuitarTooltip, -1000
Return

CounterCancel:
CounterGuiClose:
CounterGuiEscape:
    Gui, Counter:Destroy
Return

; ============================================================
;  Timer -> Win+Alt+S
;    Win+Alt+U  y luego  I  (< 1 s)  -> abre la GUI del timer
;    Al cumplirse el tiempo elegido          -> envia Win+Alt+S
;    Tras X min de inactividad (config. GUI) -> envia Win+Alt+S
; ============================================================

#!u::
    waitingForSTimerKey := true
    SetTimer, ResetSTimerWait, -1000     ; la "I" debe llegar en < 1 s
Return

; La "I" solo es hotkey durante esa ventana de 1 s (con o sin modificadores).
#If waitingForSTimerKey
*i::
    waitingForSTimerKey := false
    SetTimer, ResetSTimerWait, Off
    Gosub, OpenSTimerGui
Return
#If

ResetSTimerWait:
    waitingForSTimerKey := false
Return

OpenSTimerGui:
    Gui, STimer:New, +AlwaysOnTop, Timer -> Win+Alt+S
    Gui, STimer:Font, s10, Segoe UI
    Gui, STimer:Add, Text, xm, Tiempo del timer (minutos : segundos):
    Gui, STimer:Add, Edit, xm w70 Number Limit3 vTimerMinEdit, %timerMinutes%
    Gui, STimer:Add, Text, x+8 yp+5 w12 Center, :
    Gui, STimer:Add, Edit, x+8 yp-5 w70 Number Limit2 vTimerSecEdit, %timerSeconds%
    Gui, STimer:Add, Text, xm, Auto-envio por inactividad (minutos, 0 = off):
    Gui, STimer:Add, Edit, xm w70 Number Limit4 vInactivityEdit, %inactivityMinutes%
    Gui, STimer:Add, Button, xm w120 Default gSTimerStart, Iniciar
    Gui, STimer:Add, Button, x+10 w120 gSTimerCancel, Cancelar
    Gui, STimer:Show
    GuiControl, STimer:Focus, TimerMinEdit
Return

STimerStart:
    Gui, STimer:Submit, NoHide
    ; Guardar valores para la proxima apertura y para la inactividad.
    timerMinutes := TimerMinEdit + 0
    timerSeconds := TimerSecEdit + 0
    inactivityMinutes := InactivityEdit + 0
    inactivityFired := false                 ; re-armar el chequeo de inactividad
    Gui, STimer:Destroy
    totalMs := (timerMinutes * 60 + timerSeconds) * 1000
    if (totalMs > 0) {
        SetTimer, FireSCombo, -%totalMs%     ; one-shot: dispara al cumplirse
        ToolTip, Timer: %timerMinutes% min %timerSeconds% s -> Win+Alt+S
    } else {
        ToolTip, Sin timer (0:00). Inactividad: %inactivityMinutes% min
    }
    SetTimer, QuitarTooltip, -1500
Return

STimerCancel:
STimerGuiClose:
STimerGuiEscape:
    Gui, STimer:Destroy
Return

FireSCombo:
    SetTimer, FireSCombo, Off
    SendInput #!s
Return

; Chequeo periodico de inactividad (timer cada 1 s, arrancado al inicio).
; Usa A_TimeIdlePhysical para ignorar el input simulado por el propio script.
CheckInactivity:
    if (inactivityMinutes <= 0) {
        inactivityFired := false
        return
    }
    if (A_TimeIdlePhysical >= inactivityMinutes * 60000) {
        if (!inactivityFired) {
            inactivityFired := true
            SendInput #!s
        }
    } else {
        inactivityFired := false             ; hubo actividad: re-armar
    }
Return
