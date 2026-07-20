; ============================================================
;  !_STARTUP_merged.ahk  --  Script de arranque unico (AutoHotkey v1)
; ------------------------------------------------------------
;  Fusion de los scripts sueltos de ahk_STARTUP en un solo archivo:
;    - !_STARTUP.ahk          (base: multimedia, autotexto, GUIs, timers)
;    - Brightness.ahk         (brillo con RAlt+PgUp/PgDn)
;    - AltWindowsControl.ahk  (arrastrar/redimensionar con Alt; doble Caps)
;    - CapsWindowsControl.ahk (arrastrar con CapsLock / boton central)
;    - Open-Show-Apps.ahk     (abrir/mostrar apps y carpetas, Shift/Ctrl+F7..F10)
;    - run_Manager.ahk        (lanzar AHK Manager, Ctrl+Alt+R)
;
;  NO incluye: la carpeta !_contained (ya representada en la base),
;  AHK_Manager.ahk (es v2 y se ejecuta aparte con Ctrl+Alt+R), ni el
;  guardado/ciclado de ventanas (ver Cycler-Window-v3.ahk, standalone).
;
;  Estructura del archivo:
;    1) Directivas y seccion de auto-ejecucion (estado inicial)
;    2) Hotkeys y hotstrings, agrupados por tema
;    3) Subrutinas (labels) junto a su funcionalidad
;    4) Funciones
;    5) Clases (BrightnessSetter, al final)
; ============================================================

; ------------------------------------------------------------
;  Directivas
; ------------------------------------------------------------
#NoEnv
#SingleInstance Force
#Persistent
#Warn All, Off
#ErrorStdOut
#WinActivateForce            ; evita parpadeo de la barra al activar ventanas rapido
SetWorkingDir %A_ScriptDir%
CoordMode, Mouse, Screen     ; coordenadas de mouse absolutas (para arrastres)
SetWinDelay, 2               ; movimiento de ventanas mas fluido

; Datos personales (mails, DNI, telefono, legajos) en archivo aparte.
; *i = opcional: si el archivo no existe, no da error.
#Include *i %A_ScriptDir%\!_personal.ahk

; ------------------------------------------------------------
;  Seccion de auto-ejecucion: estado inicial
;  (todo lo que sigue, hasta la primera hotkey, corre al iniciar)
; ------------------------------------------------------------

; Estado del contador de conversacion (ver "Contador de inputs").
counter := 0
lastControlPress := 0

; Estado del timer -> Win+Alt+S (ver "Timer -> Win+Alt+S").
timerMinutes := 0            ; ultimo valor usado en la GUI (minutos)
timerSeconds := 30           ; ultimo valor usado en la GUI (segundos)
inactivityMinutes := 10      ; auto-envio por inactividad; 0 = desactivado
inactivityFired := false     ; evita reenvios dentro del mismo periodo inactivo
waitingForSTimerKey := false ; true tras Win+Alt+U, esperando la "I" (< 1 s)
SetTimer, CheckInactivity, 1000

; Controlador de brillo (ver "Brillo"). Clase definida al final del archivo.
BS := new BrightnessSetter()

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
;  Brillo de pantalla (RAlt + RePag / AvPag)
;  Logica en la clase BrightnessSetter (final del archivo).
; ============================================================

RAlt & PgDn::BS.SetBrightness(10)
RAlt & PgUp::BS.SetBrightness(-10)

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

^F3::SendCaseFromClip("U")       ; a MAYUSCULAS
^+F3::SendCaseFromClip("L")      ; a minusculas
^F4::SendCaseFromClip("T")       ; Capitalizado (Title)

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
;  Lanzar AHK Manager (Ctrl + Alt + R)   [run_Manager.ahk]
;  AHK_Manager.ahk es v2 y corre como proceso aparte.
; ============================================================

^!r::Run, "C:\Users\fzpat\Desktop\ahk\ahk_STARTUP\AHK_Manager.ahk"

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

; ============================================================
;  Abrir / mostrar apps y carpetas   [Open-Show-Apps.ahk]
;    Shift+F7   -> Chrome (abrir / activar / minimizar)
;    Shift+F8   -> carpeta Downloads
;    Ctrl(Izq)+F8  -> carpeta Tesina
;    Ctrl(Izq)+F9  -> D:\Facultad
;    Shift+F9   -> D:\Archivos\Lectura
;    Shift+F10  -> E:\DESCARGAS st250807
;    Ctrl(Izq)+F10 -> Escritorio
;  Funciones OpenOrShowApp* al final (seccion Funciones).
; ============================================================

+F7::OpenOrShowAppBasedOnExeName("C:\Program Files\Google\Chrome\Application\chrome.exe")
+F8::Run, C:\Users\fzpat\Downloads
<^F8::Run, D:\Facultad\!PROYECTO\Tesina - Zapata 2025
<^F9::Run, D:\Facultad
+F9::Run, D:\Archivos\Lectura
+F10::Run, E:\DESCARGAS st250807
<^F10::Run, C:\Users\fzpat\Desktop

; ============================================================
;  Arrastrar ventanas con Alt (estilo KDE)   [AltWindowsControl.ahk]
;    Alt + clic izq.     -> mover ventana
;    Alt + clic der.     -> redimensionar ventana
;    Doble CapsLock y, sin soltar el 2do, clic:
;       izq.    -> minimizar la ventana bajo el cursor
;       der.    -> maximizar / restaurar
;       central -> cerrar
;  Nota: hay tres formas de arrastrar ventanas en este script
;  (Alt+clic aqui, CapsLock/boton-central abajo). Conviven sin
;  conflicto; podes podar la que no uses.
; ============================================================

!LButton::
    If DoubleAlt
    {
        MouseGetPos,,,KDE_id
        ; Equivalente a WinMinimize, pero evita un bug con PSPad.
        PostMessage, 0x112, 0xf020,,, ahk_id %KDE_id%
        DoubleAlt := false
        return
    }
    ; Posicion inicial del mouse y de la ventana; abortar si esta maximizada.
    MouseGetPos, KDE_X1, KDE_Y1, KDE_id
    WinGet, KDE_Win, MinMax, ahk_id %KDE_id%
    If KDE_Win
        return
    WinGetPos, KDE_WinX1, KDE_WinY1,,, ahk_id %KDE_id%
    Loop
    {
        GetKeyState, KDE_Button, LButton, P    ; cortar al soltar el boton
        If KDE_Button = U
            break
        MouseGetPos, KDE_X2, KDE_Y2            ; posicion actual del mouse
        KDE_X2 -= KDE_X1                       ; desplazamiento respecto al inicio
        KDE_Y2 -= KDE_Y1
        KDE_WinX2 := (KDE_WinX1 + KDE_X2)      ; aplicar el desplazamiento
        KDE_WinY2 := (KDE_WinY1 + KDE_Y2)
        WinMove, ahk_id %KDE_id%,, %KDE_WinX2%, %KDE_WinY2%
    }
return

!RButton::
    If DoubleAlt
    {
        MouseGetPos,,,KDE_id
        WinGet, KDE_Win, MinMax, ahk_id %KDE_id%
        If KDE_Win
            WinRestore, ahk_id %KDE_id%
        Else
            WinMaximize, ahk_id %KDE_id%
        DoubleAlt := false
        return
    }
    MouseGetPos, KDE_X1, KDE_Y1, KDE_id
    WinGet, KDE_Win, MinMax, ahk_id %KDE_id%
    If KDE_Win
        return
    WinGetPos, KDE_WinX1, KDE_WinY1, KDE_WinW, KDE_WinH, ahk_id %KDE_id%
    ; Region de la ventana donde esta el mouse (Arriba/Abajo x Izq/Der).
    If (KDE_X1 < KDE_WinX1 + KDE_WinW / 2)
        KDE_WinLeft := 1
    Else
        KDE_WinLeft := -1
    If (KDE_Y1 < KDE_WinY1 + KDE_WinH / 2)
        KDE_WinUp := 1
    Else
        KDE_WinUp := -1
    Loop
    {
        GetKeyState, KDE_Button, RButton, P    ; cortar al soltar el boton
        If KDE_Button = U
            break
        MouseGetPos, KDE_X2, KDE_Y2
        WinGetPos, KDE_WinX1, KDE_WinY1, KDE_WinW, KDE_WinH, ahk_id %KDE_id%
        KDE_X2 -= KDE_X1
        KDE_Y2 -= KDE_Y1
        WinMove, ahk_id %KDE_id%,, KDE_WinX1 + (KDE_WinLeft+1)/2*KDE_X2  ; X
                                , KDE_WinY1 +   (KDE_WinUp+1)/2*KDE_Y2  ; Y
                                , KDE_WinW  -     KDE_WinLeft  *KDE_X2  ; W
                                , KDE_WinH  -       KDE_WinUp  *KDE_Y2  ; H
        KDE_X1 := (KDE_X2 + KDE_X1)             ; reiniciar para la proxima vuelta
        KDE_Y1 := (KDE_Y2 + KDE_Y1)
    }
return

; "Alt + MButton" solo cierra tras doble CapsLock (medida de seguridad).
!MButton::
    If DoubleAlt
    {
        MouseGetPos,,,KDE_id
        WinClose, ahk_id %KDE_id%
        DoubleAlt := false
        return
    }
return

; Detecta "doble pulsacion" de CapsLock para habilitar las acciones de arriba.
~CapsLock::
    DoubleAlt := A_PriorHotkey = "~CapsLock" AND A_TimeSincePriorHotkey < 400
    Sleep 0
    KeyWait CapsLock   ; evita que la auto-repeticion interfiera
return

; ============================================================
;  Arrastrar ventanas con CapsLock / boton central   [CapsWindowsControl.ahk]
;    CapsLock + clic izq.       -> mover ventana
;    Boton central + clic izq.  -> mover ventana
;    (Escape durante el arrastre cancela y restaura la posicion)
; ============================================================

~MButton & LButton::
CapsLock & LButton::
    CoordMode, Mouse                           ; coordenadas absolutas
    MouseGetPos, EWD_MouseStartX, EWD_MouseStartY, EWD_MouseWin
    WinGetPos, EWD_OriginalPosX, EWD_OriginalPosY,,, ahk_id %EWD_MouseWin%
    WinGet, EWD_WinState, MinMax, ahk_id %EWD_MouseWin%
    if EWD_WinState = 0                         ; solo si no esta maximizada
        SetTimer, EWD_WatchMouse, 10            ; seguir el mouse durante el arrastre
return

EWD_WatchMouse:
    GetKeyState, EWD_LButtonState, LButton, P
    if EWD_LButtonState = U                     ; boton soltado: arrastre terminado
    {
        SetTimer, EWD_WatchMouse, Off
        return
    }
    GetKeyState, EWD_EscapeState, Escape, P
    if EWD_EscapeState = D                       ; Escape: cancelar y restaurar
    {
        SetTimer, EWD_WatchMouse, Off
        WinMove, ahk_id %EWD_MouseWin%,, %EWD_OriginalPosX%, %EWD_OriginalPosY%
        return
    }
    ; Reposicionar la ventana segun el desplazamiento del mouse.
    CoordMode, Mouse
    MouseGetPos, EWD_MouseX, EWD_MouseY
    WinGetPos, EWD_WinX, EWD_WinY,,, ahk_id %EWD_MouseWin%
    SetWinDelay, -1                              ; movimiento mas fluido
    WinMove, ahk_id %EWD_MouseWin%,, EWD_WinX + EWD_MouseX - EWD_MouseStartX, EWD_WinY + EWD_MouseY - EWD_MouseStartY
    EWD_MouseStartX := EWD_MouseX                ; actualizar para la proxima vuelta
    EWD_MouseStartY := EWD_MouseY
return

; ============================================================
;  Funciones
; ============================================================

; --- Fecha / hora (autotexto) ---
SendNow(fmt, offsetDays := 0, titleCase := false) {
    t := A_Now
    if (offsetDays != 0)
        t += offsetDays, Days
    FormatTime, out, %t%, %fmt%
    if (titleCase)
        out := Format("{:T}", out)
    SendInput %out%
}

; --- Convertir texto ---
ReplaceClipSpaces(repl) {
    Old := ClipboardAll
    Clipboard := ""
    Send ^c
    ClipWait, 2
    Clipboard := StrReplace(Clipboard, " ", repl)
    Send ^v
    Clipboard := Old
}

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

; --- Abrir / mostrar apps (Open-Show-Apps) ---
; AppAddress: ruta al .exe (ej: "C:\Windows\System32\SnippingTool.exe")
OpenOrShowAppBasedOnExeName(AppAddress)
{
    AppExeName := SubStr(AppAddress, InStr(AppAddress, "\", false, -1) + 1)

    IfWinExist ahk_exe %AppExeName%
    {
        IfWinActive
        {
            WinMinimize
            Return
        }
        else
        {
            WinActivate
            Return
        }
    }
    else
    {
        Run, %AppAddress%, UseErrorLevel
        If ErrorLevel
        {
            Msgbox, File %AppAddress% Not Found
            Return
        }
        else
        {
            WinWait, ahk_exe %AppExeName%
            WinActivate ahk_exe %AppExeName%
            Return
        }
    }
}

; WindowTitleWord: palabra al final del titulo (ej: "...- Word" -> "Word")
OpenOrShowAppBasedOnWindowTitle(WindowTitleWord, AppAddress)
{
    SetTitleMatchMode, 2

    IfWinExist, %WindowTitleWord%
    {
        IfWinActive
        {
            WinMinimize
            Return
        }
        else
        {
            WinActivate
            Return
        }
    }
    else
    {
        Run, %AppAddress%, UseErrorLevel
        If ErrorLevel
        {
            Msgbox, File %AppAddress% Not Found
            Return
        }
        else
        {
            WinActivate
            Return
        }
    }
}

; Apps de la Store (shell:AppsFolder\). Guia para hallar el AppModelUserID:
; https://jcutrer.com/windows/find-aumid
OpenOrShowAppBasedOnAppModelUserID(AppTitle, AppModelUserID)
{
    SetTitleMatchMode, 2

    IfWinExist, %AppTitle%
    {
        IfWinActive
        {
            WinMinimize
            Return
        }
        else
        {
            WinActivateBottom %AppTitle%
        }
    }
    else
    {
        Run, shell:AppsFolder\%AppModelUserID%, UseErrorLevel
        If ErrorLevel
        {
            Msgbox, File %AppModelUserID% Not Found
            Return
        }
    }
}

ExtractAppTitle(FullTitle)
{
    AppTitle := SubStr(FullTitle, InStr(FullTitle, " ", false, -1) + 1)
    Return AppTitle
}

; ============================================================
;  Clase: BrightnessSetter   [Brightness.ahk]
;  Por qwerty12 - https://github.com/qwerty12/AutoHotkeyScripts
;  Ajusta el brillo via powrprof.dll y muestra el OSD de Windows.
; ============================================================

class BrightnessSetter {
    static _WM_POWERBROADCAST := 0x218, _osdHwnd := 0, hPowrprofMod := DllCall("LoadLibrary", "Str", "powrprof.dll", "Ptr")

    __New() {
        if (BrightnessSetter.IsOnAc(AC))
            this._AC := AC
        if ((this.pwrAcNotifyHandle := DllCall("RegisterPowerSettingNotification", "Ptr", A_ScriptHwnd, "Ptr", BrightnessSetter._GUID_ACDC_POWER_SOURCE(), "UInt", DEVICE_NOTIFY_WINDOW_HANDLE := 0x00000000, "Ptr"))) ; Sadly the callback passed to *PowerSettingRegister*Notification runs on a new threadl
            OnMessage(this._WM_POWERBROADCAST, ((this.pwrBroadcastFunc := ObjBindMethod(this, "_On_WM_POWERBROADCAST"))))
    }

    __Delete() {
        if (this.pwrAcNotifyHandle) {
            OnMessage(BrightnessSetter._WM_POWERBROADCAST, this.pwrBroadcastFunc, 0)
            ,DllCall("UnregisterPowerSettingNotification", "Ptr", this.pwrAcNotifyHandle)
            ,this.pwrAcNotifyHandle := 0
            ,this.pwrBroadcastFunc := ""
        }
    }

    SetBrightness(increment, jump := False, showOSD := True, autoDcOrAc := -1, ptrAnotherScheme := 0)
    {
        static PowerGetActiveScheme := DllCall("GetProcAddress", "Ptr", BrightnessSetter.hPowrprofMod, "AStr", "PowerGetActiveScheme", "Ptr")
              ,PowerSetActiveScheme := DllCall("GetProcAddress", "Ptr", BrightnessSetter.hPowrprofMod, "AStr", "PowerSetActiveScheme", "Ptr")
              ,PowerWriteACValueIndex := DllCall("GetProcAddress", "Ptr", BrightnessSetter.hPowrprofMod, "AStr", "PowerWriteACValueIndex", "Ptr")
              ,PowerWriteDCValueIndex := DllCall("GetProcAddress", "Ptr", BrightnessSetter.hPowrprofMod, "AStr", "PowerWriteDCValueIndex", "Ptr")
              ,PowerApplySettingChanges := DllCall("GetProcAddress", "Ptr", BrightnessSetter.hPowrprofMod, "AStr", "PowerApplySettingChanges", "Ptr")

        if (increment == 0 && !jump) {
            if (showOSD)
                BrightnessSetter._ShowBrightnessOSD()
            return
        }

        if (!ptrAnotherScheme ? DllCall(PowerGetActiveScheme, "Ptr", 0, "Ptr*", currSchemeGuid, "UInt") == 0 : DllCall("powrprof\PowerDuplicateScheme", "Ptr", 0, "Ptr", ptrAnotherScheme, "Ptr*", currSchemeGuid, "UInt") == 0) {
            if (autoDcOrAc == -1) {
                if (this != BrightnessSetter) {
                    AC := this._AC
                } else {
                    if (!BrightnessSetter.IsOnAc(AC)) {
                        DllCall("LocalFree", "Ptr", currSchemeGuid, "Ptr")
                        return
                    }
                }
            } else {
                AC := !!autoDcOrAc
            }

            currBrightness := 0
            if (jump || BrightnessSetter._GetCurrentBrightness(currSchemeGuid, AC, currBrightness)) {
                 maxBrightness := BrightnessSetter.GetMaxBrightness()
                ,minBrightness := BrightnessSetter.GetMinBrightness()

                if (jump || !((currBrightness == maxBrightness && increment > 0) || (currBrightness == minBrightness && increment < minBrightness))) {
                    if (currBrightness + increment > maxBrightness)
                        increment := maxBrightness
                    else if (currBrightness + increment < minBrightness)
                        increment := minBrightness
                    else
                        increment += currBrightness

                    if (DllCall(AC ? PowerWriteACValueIndex : PowerWriteDCValueIndex, "Ptr", 0, "Ptr", currSchemeGuid, "Ptr", BrightnessSetter._GUID_VIDEO_SUBGROUP(), "Ptr", BrightnessSetter._GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS(), "UInt", increment, "UInt") == 0) {
                        ; PowerApplySettingChanges is undocumented and exists only in Windows 8+. Since both the Power control panel and the brightness slider use this, we'll do the same, but fallback to PowerSetActiveScheme if on Windows 7 or something
                        if (!PowerApplySettingChanges || DllCall(PowerApplySettingChanges, "Ptr", BrightnessSetter._GUID_VIDEO_SUBGROUP(), "Ptr", BrightnessSetter._GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS(), "UInt") != 0)
                            DllCall(PowerSetActiveScheme, "Ptr", 0, "Ptr", currSchemeGuid, "UInt")
                    }
                }

                if (showOSD)
                    BrightnessSetter._ShowBrightnessOSD()
            }
            DllCall("LocalFree", "Ptr", currSchemeGuid, "Ptr")
        }
    }

    IsOnAc(ByRef acStatus)
    {
        static SystemPowerStatus
        if (!VarSetCapacity(SystemPowerStatus))
            VarSetCapacity(SystemPowerStatus, 12)

        if (DllCall("GetSystemPowerStatus", "Ptr", &SystemPowerStatus)) {
            acStatus := NumGet(SystemPowerStatus, 0, "UChar") == 1
            return True
        }

        return False
    }

    GetDefaultBrightnessIncrement()
    {
        static ret := 10
        DllCall("powrprof\PowerReadValueIncrement", "Ptr", BrightnessSetter._GUID_VIDEO_SUBGROUP(), "Ptr", BrightnessSetter._GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS(), "UInt*", ret, "UInt")
        return ret
    }

    GetMinBrightness()
    {
        static ret := -1
        if (ret == -1)
            if (DllCall("powrprof\PowerReadValueMin", "Ptr", BrightnessSetter._GUID_VIDEO_SUBGROUP(), "Ptr", BrightnessSetter._GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS(), "UInt*", ret, "UInt"))
                ret := 0
        return ret
    }

    GetMaxBrightness()
    {
        static ret := -1
        if (ret == -1)
            if (DllCall("powrprof\PowerReadValueMax", "Ptr", BrightnessSetter._GUID_VIDEO_SUBGROUP(), "Ptr", BrightnessSetter._GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS(), "UInt*", ret, "UInt"))
                ret := 100
        return ret
    }

    _GetCurrentBrightness(schemeGuid, AC, ByRef currBrightness)
    {
        static PowerReadACValueIndex := DllCall("GetProcAddress", "Ptr", BrightnessSetter.hPowrprofMod, "AStr", "PowerReadACValueIndex", "Ptr")
              ,PowerReadDCValueIndex := DllCall("GetProcAddress", "Ptr", BrightnessSetter.hPowrprofMod, "AStr", "PowerReadDCValueIndex", "Ptr")
        return DllCall(AC ? PowerReadACValueIndex : PowerReadDCValueIndex, "Ptr", 0, "Ptr", schemeGuid, "Ptr", BrightnessSetter._GUID_VIDEO_SUBGROUP(), "Ptr", BrightnessSetter._GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS(), "UInt*", currBrightness, "UInt") == 0
    }

    _ShowBrightnessOSD()
    {
        static PostMessagePtr := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "PostMessageW" : "PostMessageA", "Ptr")
              ,WM_SHELLHOOK := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK", "UInt")
        if A_OSVersion in WIN_VISTA,WIN_7
            return
        BrightnessSetter._RealiseOSDWindowIfNeeded()
        ; Thanks to YashMaster @ https://github.com/YashMaster/Tweaky/blob/master/Tweaky/BrightnessHandler.h for realising this could be done:
        if (BrightnessSetter._osdHwnd)
            DllCall(PostMessagePtr, "Ptr", BrightnessSetter._osdHwnd, "UInt", WM_SHELLHOOK, "Ptr", 0x37, "Ptr", 0)
    }

    _RealiseOSDWindowIfNeeded()
    {
        static IsWindow := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", "IsWindow", "Ptr")
        if (!DllCall(IsWindow, "Ptr", BrightnessSetter._osdHwnd) && !BrightnessSetter._FindAndSetOSDWindow()) {
            BrightnessSetter._osdHwnd := 0
            try if ((shellProvider := ComObjCreate("{C2F03A33-21F5-47FA-B4BB-156362A2F239}", "{00000000-0000-0000-C000-000000000046}"))) {
                try if ((flyoutDisp := ComObjQuery(shellProvider, "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}", "{41f9d2fb-7834-4ab6-8b1b-73e74064b465}"))) {
                     DllCall(NumGet(NumGet(flyoutDisp+0)+3*A_PtrSize), "Ptr", flyoutDisp, "Int", 0, "UInt", 0)
                    ,ObjRelease(flyoutDisp)
                }
                ObjRelease(shellProvider)
                if (BrightnessSetter._FindAndSetOSDWindow())
                    return
            }
            ; who knows if the SID & IID above will work for future versions of Windows 10 (or Windows 8). Fall back to this if needs must
            Loop 2 {
                SendEvent {Volume_Mute 2}
                if (BrightnessSetter._FindAndSetOSDWindow())
                    return
                Sleep 100
            }
        }
    }

    _FindAndSetOSDWindow()
    {
        static FindWindow := DllCall("GetProcAddress", "Ptr", DllCall("GetModuleHandle", "Str", "user32.dll", "Ptr"), "AStr", A_IsUnicode ? "FindWindowW" : "FindWindowA", "Ptr")
        return !!((BrightnessSetter._osdHwnd := DllCall(FindWindow, "Str", "NativeHWNDHost", "Str", "", "Ptr")))
    }

    _On_WM_POWERBROADCAST(wParam, lParam)
    {
        ;OutputDebug % &this
        if (wParam == 0x8013 && lParam && NumGet(lParam+0, 0, "UInt") == NumGet(BrightnessSetter._GUID_ACDC_POWER_SOURCE()+0, 0, "UInt")) { ; PBT_POWERSETTINGCHANGE and a lazy comparison
            this._AC := NumGet(lParam+0, 20, "UChar") == 0
            return True
        }
    }

    _GUID_VIDEO_SUBGROUP()
    {
        static GUID_VIDEO_SUBGROUP__
        if (!VarSetCapacity(GUID_VIDEO_SUBGROUP__)) {
             VarSetCapacity(GUID_VIDEO_SUBGROUP__, 16)
            ,NumPut(0x7516B95F, GUID_VIDEO_SUBGROUP__, 0, "UInt"), NumPut(0x4464F776, GUID_VIDEO_SUBGROUP__, 4, "UInt")
            ,NumPut(0x1606538C, GUID_VIDEO_SUBGROUP__, 8, "UInt"), NumPut(0x99CC407F, GUID_VIDEO_SUBGROUP__, 12, "UInt")
        }
        return &GUID_VIDEO_SUBGROUP__
    }

    _GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS()
    {
        static GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS__
        if (!VarSetCapacity(GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS__)) {
             VarSetCapacity(GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS__, 16)
            ,NumPut(0xADED5E82, GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS__, 0, "UInt"), NumPut(0x4619B909, GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS__, 4, "UInt")
            ,NumPut(0xD7F54999, GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS__, 8, "UInt"), NumPut(0xCB0BAC1D, GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS__, 12, "UInt")
        }
        return &GUID_DEVICE_POWER_POLICY_VIDEO_BRIGHTNESS__
    }

    _GUID_ACDC_POWER_SOURCE()
    {
        static GUID_ACDC_POWER_SOURCE_
        if (!VarSetCapacity(GUID_ACDC_POWER_SOURCE_)) {
             VarSetCapacity(GUID_ACDC_POWER_SOURCE_, 16)
            ,NumPut(0x5D3E9A59, GUID_ACDC_POWER_SOURCE_, 0, "UInt"), NumPut(0x4B00E9D5, GUID_ACDC_POWER_SOURCE_, 4, "UInt")
            ,NumPut(0x34FFBDA6, GUID_ACDC_POWER_SOURCE_, 8, "UInt"), NumPut(0x486551FF, GUID_ACDC_POWER_SOURCE_, 12, "UInt")
        }
        return &GUID_ACDC_POWER_SOURCE_
    }
}
