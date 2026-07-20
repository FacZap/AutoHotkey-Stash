/*Please help me write a script that can delete the middle names which are usually abbreviated with a dot after it, such as:

-> Stephen M. Merkel

-> Wiliam J. Moran

The result I want after pressing a hotkey:

=> Stephen Merkel

=> Wiliam Moran

Any help would be very appreciated.
*/

SendMode, Input

; -- Ctrl + . -> Delete middle name from selection

^.::
While GetKeyState("Ctrl","P")
    Sleep, 10
Clipboard := ""
Send, ^c
ClipWait, 0
If ErrorLevel
    Return
Sleep, 50
; Clipboard := RegExReplace(Clipboard, "([A-Z][a-z]+) [A-Z]\. ([A-Z][a-z]+)", "$1 $2")
Clipboard := RegExReplace(Clipboard, "([A-Z][a-z]+) [A-Z][a-z]{0,2}\. ([A-Z][a-z]+)", "$1 $2")
Send, ^v
Return