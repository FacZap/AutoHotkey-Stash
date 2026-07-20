~RControl::
    if (A_PriorHotkey != "~RControl" || A_TimeSincePriorHotkey > 1000)
    {
        count := 1
    }
    else
    {
        count += 1
    }

    ToolTip, RControl tapped x%count%

    if (count = 3)
    {
        ToolTip, Listening for key...
        SetTimer, ResetCount, Off

        ih := InputHook("L1 T1 V E")
        ih.KeyOpt("{All}", "E")
        ih.Start()
        ih.Wait()

        ToolTip  ; Clear tooltip after wait

        if (ih.EndReason = "Stopped")
        {
            key := ih.EndKey
            if (key != "RControl")
            {
                modifiers := ""
                if GetKeyState("Shift")
                    modifiers .= "+"
                if GetKeyState("Alt")
                    modifiers .= "!"
                if GetKeyState("LWin") || GetKeyState("RWin")
                    modifiers .= "#"

                sendCombo := "^" modifiers "{" key "}"
                ToolTip, Sending: %sendCombo%
                Sleep, 500  ; Briefly show feedback
                ToolTip
                Send, % sendCombo
            }
        }
        else
        {
            ToolTip, Input canceled or timed out
            Sleep, 1000
            ToolTip
        }

        count := 0
    }

    SetTimer, ResetCount, -1000
return

ResetCount:
    count := 0
    ToolTip  ; Clear tooltip if still shown
return
