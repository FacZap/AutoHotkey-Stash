#NoEnv
#SingleInstance Force
SetWorkingDir %A_ScriptDir%

; Win + Numpad5 abre el calendario
#Numpad5::
    Gui, Cal:New
    Gui, Cal:+AlwaysOnTop +ToolWindow
    Gui, Cal:Color, FFFFFF
    Gui, Cal:Font, s10, Segoe UI

    Gui, Cal:Add, Text, x10 y10 w290 Center, Selecciona una fecha
    Gui, Cal:Add, MonthCal, x10 y35 vFechaSeleccionada gOnCalendario

    ; Los botones se colocan debajo del MonthCal (altura aprox 165px desde y35)
    Gui, Cal:Add, Button, x10 y210 w140 gCopiarFecha Default, Copiar  (Enter)
    Gui, Cal:Add, Button, x160 y210 w140 gCerrarCalendario,    Cancelar  (Esc)

    Gui, Cal:Show, w310, Calendario
return

; Doble clic en una fecha = copiar directo
OnCalendario:
    if (A_GuiEvent = "DoubleClick")
        Gosub, CopiarFecha
return

CopiarFecha:
    Gui, Cal:Submit, NoHide
    FormatTime, Fecha, %FechaSeleccionada%, dd/MM/yyyy
    Clipboard := Fecha
    ToolTip, Copiado: %Fecha%
    SetTimer, QuitarTooltip, 2000
    Gui, Cal:Destroy
return

CerrarCalendario:
CalGuiClose:
CalGuiEscape:
    Gui, Cal:Destroy
return

QuitarTooltip:
    SetTimer, QuitarTooltip, Off
    ToolTip
return
