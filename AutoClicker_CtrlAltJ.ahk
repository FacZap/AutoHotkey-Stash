; ============================================================
;  AutoClicker  ·  Ctrl+Alt+J
; ─────────────────────────────────────────────────────────────
;  FLUJO:
;    1. Ctrl+Alt+J  →  entrás en modo selección
;    2. Hacé click en el punto donde querés el auto-click
;    3. Cuenta regresiva y arranca el auto-click
;    4. Ctrl+Alt+J  →  cancela en cualquier momento
; ============================================================

#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; ╔══════════════════════════════════════════════════════════╗
; ║                     CONFIGURACIÓN                        ║
; ╠══════════════════════════════════════════════════════════╣
INTERVALO_MS   := 500   ; ms entre cada click  (2000 = 2 s, 500 = 0.5 s)
DELAY_INICIO_S := 2     ; segundos de cuenta regresiva antes de arrancar
; ╚══════════════════════════════════════════════════════════╝

global estado    := "idle"   ; idle | seleccionando | countdown | corriendo
global clickX    := 0
global clickY    := 0
global countdown := 0


; ── Hotkey principal ─────────────────────────────────────────
^!j::
    if (estado = "idle") {
        estado := "seleccionando"
        ToolTip, [AutoClicker]`n>> Hacé click en el punto objetivo`n   Ctrl+Alt+J para cancelar
    } else {
        Gosub, Cancelar
    }
return


; ── Captura el click de selección (transparente al sistema) ──
~LButton::
    if (estado != "seleccionando")
        return
    MouseGetPos, clickX, clickY
    estado    := "countdown"
    countdown := DELAY_INICIO_S
    SetTimer, TickCountdown, 1000
    Gosub, TickCountdown        ; mostrar primer tick al instante
return


; ── Cuenta regresiva ─────────────────────────────────────────
TickCountdown:
    if (estado != "countdown") {
        SetTimer, TickCountdown, Off
        return
    }
    if (countdown <= 0) {
        SetTimer, TickCountdown, Off
        estado := "corriendo"
        segs := INTERVALO_MS / 1000.0
        ToolTip, [AutoClicker]  ACTIVO`n   Destino   : (%clickX%`, %clickY%)`n   Intervalo : %segs% s`n   Ctrl+Alt+J para detener
        SetTimer, HacerClick, %INTERVALO_MS%
        Gosub, HacerClick       ; primer click inmediato sin esperar el timer
        return
    }
    ToolTip, [AutoClicker]`n>> Iniciando en %countdown% s...`n   Ctrl+Alt+J para cancelar
    countdown--
return


; ── Auto-click periódico ─────────────────────────────────────
HacerClick:
    if (estado != "corriendo") {
        SetTimer, HacerClick, Off
        return
    }
    Click, %clickX%, %clickY%
return


; ── Cancelar / resetear estado ───────────────────────────────
Cancelar:
    estadoAnterior := estado
    estado := "idle"
    SetTimer, TickCountdown, Off
    SetTimer, HacerClick, Off
    if (estadoAnterior = "idle")
        return
    ToolTip, [AutoClicker]  Detenido.
    Sleep, 1200
    ToolTip
return
