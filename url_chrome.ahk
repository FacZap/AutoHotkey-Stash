#Requires AutoHotkey v2.0
; The sheet URL lives in the gitignored url_chrome.ini ([Settings] Url=...)
SheetUrl := IniRead(A_ScriptDir "\url_chrome.ini", "Settings", "Url", "")

^!g::Run('"C:\Program Files\Google\Chrome\Application\chrome.exe" --new-window "' SheetUrl '"')

^!+g::Run('"C:\Program Files\Google\Chrome\Application\chrome.exe" --new-tab "' SheetUrl '"')
