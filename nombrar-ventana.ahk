SetTitleMatchMode, 2 ; Set title match mode to find windows with titles that contain the specified WinTitle anywhere inside them

; Function to get the position of the top of the active window
GetWindowTop(hwnd)
{
    WinGetPos, , y, , , ahk_id %hwnd% ; Get the y-coordinate of the active window
    return y
}

; Set mouse position to the top of the active window's header
^F7::
SetTitleMatchMode, 2
WinGet, active_id, ID, A ; Get the active window's ID
MouseGetPos, , y ; Get the current mouse position
y_top := GetWindowTop(active_id) ; Get the top position of the active window
MouseMove, %A_CaretX%, %y_top% ; Move mouse to the top of the active window

; Right click
Click, right

; Press DOWN key 9 times
Loop 9 {
    Send, {Down}
    Sleep, 50 ; Optional: Adjust sleep time as needed
}

; Hit Enter
Send, {Enter}

return ; End of script


