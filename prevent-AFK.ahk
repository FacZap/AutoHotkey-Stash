#Requires AutoHotkey v2.0
SetTimer(Jiggle, 60000)  ; every 60 seconds

Jiggle() {
    MouseMove(2, 0, 0, "R")   
    MouseMove(-2, 0, 0, "R")  
}