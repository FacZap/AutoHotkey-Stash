#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================
; AltTab_Button.ahk
; GUI diminuta, siempre visible, en el centro-derecha de la
; pantalla, con un unico boton que envia Alt+Tab.
; - Clic izquierdo en el boton : Alt+Tab
; - Arrastrar el borde/fondo    : mover la ventanita
; - Clic derecho en la ventana  : salir
; ============================================================

ANCHO  := 34          ; ancho del boton
ALTO   := 26          ; alto del boton
MARGEN := 6           ; separacion del borde derecho de la pantalla

MyGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner", "AltTab")
MyGui.MarginX := 0
MyGui.MarginY := 0
MyGui.BackColor := "313131"

Btn := MyGui.Add("Button", "x0 y0 w" ANCHO " h" ALTO, "⇄")
Btn.SetFont("s10", "Segoe UI Symbol")
Btn.OnEvent("Click", EnviarAltTab)

MyGui.OnEvent("ContextMenu", (*) => ExitApp())

MyGui.Show("w" ANCHO " h" ALTO " NoActivate")

; WS_EX_NOACTIVATE (0x08000000): al hacer clic la ventana no roba el
; foco, asi Alt+Tab actua sobre la ventana que estaba activa.
WinSetExStyle "+0x08000000", MyGui

; Posicion: centro vertical, pegado al borde derecho.
; A_ScreenWidth/Height vienen en pixeles fisicos, pero el GUI usa
; coordenadas logicas (escaladas por DPI), asi que hay que convertir.
AnchoLog := A_ScreenWidth  * 96 // A_ScreenDPI
AltoLog  := A_ScreenHeight * 96 // A_ScreenDPI
MyGui.Move(AnchoLog - ANCHO - MARGEN, (AltoLog - ALTO) // 2)

EnviarAltTab(*)
{
    ; El conmutador de Windows necesita que Alt quede realmente
    ; presionado un instante antes y despues del Tab; mandar todo
    ; de golpe con Send hace que falle de forma intermitente.
    SendEvent "{Alt down}"
    Sleep 80
    SendEvent "{Tab down}"
    Sleep 40
    SendEvent "{Tab up}"
    Sleep 120
    SendEvent "{Alt up}"
}

; Mover la ventanita arrastrando con Win + clic izquierdo sobre ella.
#LButton::
{
    MouseGetPos , , &hWnd
    try {
        if (WinGetTitle("ahk_id " hWnd) = "AltTab")
            PostMessage 0xA1, 2, 0, , "ahk_id " hWnd   ; WM_NCLBUTTONDOWN / HTCAPTION
    }
}
