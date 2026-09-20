^+v::  ; Ctrl + Shift + V
{
    ClipWait 1
    value := A_Clipboard

    if (value is number)
    {
        newValue := value + 1
        A_Clipboard := newValue
        Send ^v
    }
    else
    {
        MsgBox "Clipboard does not contain a number."
    }
}