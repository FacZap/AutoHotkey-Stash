^!x::  ; Ctrl+Alt+x hotkey - customize this combination as needed
    ; Activate Alt+Shift+End
    SendInput !+{End}
    Sleep 1500  ; Short pause for system response
    
    ; Select all content
    SendInput ^a
    Sleep 50
    
    ; Paste from clipboard (ensure clipboard contains desired content first)
    SendInput ^v
    Sleep 50
    
    ; Press Tab key
    SendInput {Tab}
    Sleep 50
    
    ; Press Enter
    SendInput {Enter}
    Sleep 700
    
    ; Type Shift+A (capital A)
    SendInput +a
Return

^!+x::  ; Ctrl+Alt+Shift+x hotkey - customize this combination as needed
    ; Activate Alt+Shift+h
    SendInput !+{h}
    Sleep 1000  ; Short pause for system response
    
    ; Downkey
    SendInput {Down}
    Sleep 300
    
    ; Press Enter
    SendInput {Enter}
    Sleep 50
    
Return