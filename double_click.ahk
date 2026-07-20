#Persistent
~LButton::
    if (A_PriorHotkey = "~LButton" && A_TimeSincePriorHotkey < 120)
    {
        ToolTip, Double click detected too fast! Possible faulty mouse.
        Sleep, 500
        ToolTip
    }
return