^!d::  ; Ctrl+Alt+d hotkey - customize this combination as needed
    ; Activate Alt+D
    SendInput !d
    Sleep 50  ; Short pause for system response

    SendInput {Home}
    Sleep 50
    
    Send ^{Right}
    Sleep 10  
    Send ^{Right}
    Sleep 10
    Send ^{Right}

    SendInput +{End}
    Sleep 50

    SendInput ^c
    Sleep 10
    
    SendInput ^a
    SendInput ^v
    SendInput {Enter}
Return