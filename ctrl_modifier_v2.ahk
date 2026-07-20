~RControl::
    if (A_PriorHotkey != "~RControl" || A_TimeSincePriorHotkey > 500)
    {
        count := 1
        SetTimer, ResetCount, -500
    }
    else
    {
        count += 1
        SetTimer, ResetCount, -500
    }
    
    if (count = 3)
    {
        Tooltip, [CTRL ACTIVE]  ; Visual feedback
        SetTimer, RemoveTooltip, -2000  ; Remove feedback after 2 seconds
        Send {RControl Up}  ; Release physical Ctrl press
        Input, nextKey, L1 T2, {LControl}{RControl}  ; Wait for next key
        if (nextKey != "")
        {
            modifiers := GetModifiers()
            SendEvent % "{" modifiers "Ctrl Down}" nextKey "{Ctrl Up}"
        }
        count := 0
    }
return


GetModifiers() {
    modifiers := ""
    if GetKeyState("Shift")
        modifiers .= "+"
    if GetKeyState("Alt")
        modifiers .= "!"
    if GetKeyState("LWin") || GetKeyState("RWin")
        modifiers .= "#"
    return modifiers
}

RemoveTooltip:
    Tooltip
return

ResetCount:
    count := 0
    Tooltip
return