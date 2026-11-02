; === CONFIGURABLE SETTINGS ===
xPos     := 100        ; X coordinate to move the NitroSense window
yPos     := 100        ; Y coordinate to move the NitroSense window
clickX   := 1470       ; X coordinate where to click inside the NitroSense window
clickY   := 160        ; Y coordinate where to click inside the NitroSense window
;interval := 0.5 * 60 * 1000  ; Interval in milliseconds
;interval := 5 * 60 * 1000  ; Interval in milliseconds (5 minutes)
interval := 3 * 60 * 1000  ; Interval in milliseconds (3 minutes)

SetTitleMatchMode, 2  ; Allow partial matching of window titles

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

