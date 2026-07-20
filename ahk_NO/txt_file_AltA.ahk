<+!a::      ; press Alt+Shift+a to execute the hotkey
    myPath := "C:\Users\fzpat\Desktop\Name.txt"
    SplitPath, myPath,,,,fName 
    Run,% "notepad.exe " . myPath
    If WinExist(fName)
        WinActivate 
    Return