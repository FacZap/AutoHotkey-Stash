!^F7::
SendInput, -------------------
SendInput, {Enter}
SendInput, {Space}
FormatTime, CurrentDateTime,, yy/MM/dd HH:mm:ss
SendInput %CurrentDateTime%
SendInput, {Enter}
SendInput -------------------
return

!^l::
    ; Set a timer to wait for 2 seconds for input
    Input, UserInput, L1 T2
    if (ErrorLevel = "Timeout") {
        ; If timeout occurs, do nothing (cancel)
        return
    }
    if (UserInput = "1") {
        ; If '1' is pressed, send the first set of inputs
        SendInput, ---
        SendInput, {Enter}
    } else if (UserInput = "2") {
        ; If '2' is pressed, send the second set of inputs
        SendInput, {Space}
        SendInput, ----------------------
        SendInput, {Enter}
    } else {
        ; If any other key is pressed, do nothing (cancel)
        return
    }
return

