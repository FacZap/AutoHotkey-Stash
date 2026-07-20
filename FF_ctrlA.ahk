debug := true  ; <--- Set to false to disable MsgBox debugging

#IfWinActive ahk_exe firefox.exe

$^!a::
Start := A_TickCount
KeyWait, a  ; wait for release of "A"
pressTime := A_TickCount - Start

if (pressTime < 2000)
{
    if (debug)
        MsgBox, 64, Debug, [FIREFOX] Short press detected (%pressTime% ms)`nSending Ctrl+Alt+L
    SendInput, ^!l
}
else
{
    if (debug)
        MsgBox, 64, Debug, [FIREFOX] Long press detected (%pressTime% ms)`nSending Ctrl+Alt+A
    SendInput, ^!a
}
return

#IfWinActive

; -----------------------
; "Elsewhere" version (if not in Firefox)
; -----------------------
#IfWinActive  ; no condition = all other windows

$^!a::
Start := A_TickCount
KeyWait, a
pressTime := A_TickCount - Start

if (pressTime < 2000)
{
    if (debug)
        MsgBox, 64, Debug, [NOT FIREFOX] Short press detected (%pressTime% ms)
    ; Do nothing or put alternative behavior here
}
else
{
    if (debug)
        MsgBox, 64, Debug, [NOT FIREFOX] Long press detected (%pressTime% ms)
    ; Do nothing or put alternative behavior here
}
return

#IfWinActive
