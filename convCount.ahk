#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook

counter := 0
lastControlPress := 0

; ==================================================
; Ctrl + Alt + Win + T
; Sends conversation marker
; ==================================================
^!#t::
{
    global counter

    counter += 1

    timestamp := FormatTime(A_Now, "dd/MM/yyyy - [HH:mm]")
    text := "Conversation User Input n° " counter " @ " timestamp " . "

    SendText text
}

; ==================================================
; Ctrl + Alt + Win + R
; Press once: reset counter
; Press twice within 700ms: open manual counter GUI
; ==================================================
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


OpenCounterGui()
{
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

    ; Select all text in the edit box
    SendMessage 0xB1, 0, -1, edit
}


SaveCounterFromGui(g, edit)
{
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


PutAskTextOnClipboardAndClose(g)
{
    A_Clipboard := "En que numero de input de chat estoy en esta conversacion (incluyendo este)?"

    g.Destroy()

    ToolTip "Question copied to clipboard"
    SetTimer () => ToolTip(), -1000
}

