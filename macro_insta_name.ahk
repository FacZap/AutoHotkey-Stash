^!x::  ; Ctrl+Alt+X hotkey - customize this combination as needed
    ; Send Esc to de-select any text
    SendInput {Esc}
    Sleep 50  ; Short pause for system response    

    ; Activate Alt+Shift+End
    SendInput !+{End}
    Sleep 1200  ; Short pause for system response
    
    ; Select all content
    SendInput ^a
    Sleep 200
    
    ; Paste from clipboard (ensure clipboard contains desired content first)
    SendInput ^v
    Sleep 80
    
    ; Press Tab key
    SendInput {Tab}
    Sleep 70
    
    ; Press Enter
    SendInput {Enter}
    Sleep 550
    
    ; Type Shift+A (capital A)
    SendInput +a
Return

^!+x::  ; Ctrl+Alt+Shift+X hotkey - customize this combination as needed
    ; Activate Alt+Shift+h
    SendInput !+{h}
    Sleep 1000  ; Short pause for system response
    
    ; Press Down Arrow key
    SendInput {Down}
    Sleep 100
    
    ; Press Enter
    SendInput {Enter}
    Sleep 10
    
Return