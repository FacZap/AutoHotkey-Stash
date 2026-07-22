; === CONFIGURABLE SETTINGS ===
xPos     := 100        ; X coordinate to move the NitroSense window
yPos     := 100        ; Y coordinate to move the NitroSense window
clickX   := 1470       ; X coordinate where to click inside the NitroSense window
clickY   := 160        ; Y coordinate where to click inside the NitroSense window

; ⚠ El intervalo ahora se define por menú al inicio, no acá
;interval := 3 * 60 * 1000  ; Interval in milliseconds (3 minutes)

SetTitleMatchMode, 2  ; Allow partial matching of window titles

; === MENÚ INICIAL PARA ELEGIR INTERVALO ===
; Se muestra al correr el script por primera vez

Menu, IntervalMenu, Add, 1 minuto, SetInterval1
Menu, IntervalMenu, Add, 3 minutos, SetInterval3
Menu, IntervalMenu, Add, 5 minutos, SetInterval5
Menu, IntervalMenu, Add, 10 minutos, SetInterval10
Menu, IntervalMenu, Add, Personalizado..., SetIntervalCustom

; Mostrar el menú (se abre donde esté el mouse)
Menu, IntervalMenu, Show
return  ; Fin de la sección autoejecutable, el script espera tu elección


; === HANDLERS DEL MENÚ ===

SetInterval1:
interval := 1 * 60 * 1000
Goto, StartLoop

SetInterval3:
interval := 3 * 60 * 1000
Goto, StartLoop

SetInterval5:
interval := 5 * 60 * 1000
Goto, StartLoop

SetInterval10:
interval := 10 * 60 * 1000
Goto, StartLoop

SetIntervalCustom:
InputBox, minutes, Intervalo personalizado, Ingresa cada cuántos minutos se ejecuta el loop:, , 250, 120
if ErrorLevel
{
    ; Si cancela, cerramos el script
    ExitApp
}
if (minutes <= 0)
{
    MsgBox, 16, Error, Valor inválido. Se usará 3 minutos por defecto.
    minutes := 3
}
interval := minutes * 60 * 1000
Goto, StartLoop


; === LOOP PRINCIPAL ===

StartLoop:
Loop
{
    ; Show 3-second warning tooltip in center of screen
    ShowTip("About to switch applications...", "yCenter", "Red")
    Sleep, 3000
    ShowTip("")  ; Clear it

    ; Save current mouse position
    MouseGetPos, origX, origY

    ; Run NitroSense UWP app
    Run, shell:AppsFolder\AcerIncorporated.NitroSenseV31_48frkmn4z8aw4!App

    ; Wait for NitroSense window to appear
    WinWait, NitroSense, , 10
    if ErrorLevel
    {
        MsgBox, 16, Error, NitroSense window not found within 10 seconds.
    }
    else
    {
        ; Move the window
        WinMove, NitroSense, , %xPos%, %yPos%

        ; Give the window focus
        WinActivate, NitroSense
        Sleep, 500

        ; Click at the specified position
        Click, %clickX%, %clickY%
        Sleep, 50
        Click, %clickX%, %clickY%
        Sleep, 100
        Send !{Tab}

        ; Restore mouse to original position
        MouseMove, %origX%, %origY%, 0
    }

    ; Wait for the defined interval before repeating
    Sleep, %interval%
}

; === ShowTip Function for AutoHotkey v1 (Simple version, no color cycling) ===
ShowTip(s := "", pos := "yCenter", color := "Red") {
    global ShowTipGui

    if (s = "") {
        ; Destroy the tooltip if it exists
        Gui, ShowTipGui:Destroy
        ShowTipGui := ""  ; clear reference
        return
    }

    ; Create new tooltip
    if (ShowTipGui)
        Gui, ShowTipGui:Destroy

    Gui, ShowTipGui:+LastFound +AlwaysOnTop +ToolWindow -Caption +E0x08000020
    Gui, ShowTipGui:Color, FFFFF0
    Gui, ShowTipGui:Font, s20 bold c%color%, Segoe UI
    Gui, ShowTipGui:Add, Text, , %s%
    Gui, ShowTipGui:Show, NA %pos%, ShowTip
    WinSet, TransColor, FFFFF0 150, ShowTip
}
