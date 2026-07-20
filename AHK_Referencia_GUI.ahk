; ============================================================
;  AHK_Referencia_GUI.ahk  --  Popup de referencia (AutoHotkey v1)
; ------------------------------------------------------------
;  Motor: Shell.Explorer (IE embebido)  ->  CERO dependencias externas.
;  Hotkey: Win + Shift + ?   (toggle: 1ra vez abre, 2da cierra)
;  Tambien: Esc cierra cuando el popup tiene el foco.
;
;  Carga el archivo AHK_Referencia.html que esta en esta misma carpeta.
;  El HTML lleva <meta http-equiv="X-UA-Compatible" content="IE=edge">
;  para que el control IE lo dibuje en modo moderno (IE11) y no en IE7.
;
;  NOTA: no ejecutes a la vez esta version y la de WebView2: las dos usan
;  el mismo hotkey (Win+Shift+?) y chocarian. Elegi una.
; ============================================================

#NoEnv
#SingleInstance Force
#Persistent
SetWorkingDir %A_ScriptDir%

global RefHtml  := A_ScriptDir "\AHK_Referencia.html"
global RefOpen  := false
global RefHwnd  := 0
global RefTitle := "Referencia AHK"
return

; ------------------------------------------------------------
;  Win + Shift + ?   (toggle)
; ------------------------------------------------------------
#?::
    if (RefOpen)
        Gosub, RefClose
    else
        Gosub, RefShow
return

RefShow:
    if (!FileExist(RefHtml)) {
        MsgBox, 48, %RefTitle%, No se encontro el archivo:`n%RefHtml%
        return
    }
    Gui, Ref:New, +AlwaysOnTop +ToolWindow -Caption +Border +HwndRefHwnd
    Gui, Ref:Margin, 0, 0
    Gui, Ref:Color, FFFFFF
    Gui, Ref:Add, ActiveX, x0 y0 w740 h640 vRefWB, Shell.Explorer
    RefWB.Silent := true                                   ; sin dialogos de error de script
    RefWB.Navigate("file:///" StrReplace(RefHtml, "\", "/"))
    Gui, Ref:Show, w740 h640 Center, %RefTitle%
    RefOpen := true
return

RefClose:
RefGuiClose:
RefGuiEscape:
    Gui, Ref:Destroy
    RefOpen := false
return

; Esc cierra cuando el popup (o su navegador embebido) tiene el foco.
#If RefOpen && WinActive("ahk_id " RefHwnd)
Esc::Gosub, RefClose
#If
