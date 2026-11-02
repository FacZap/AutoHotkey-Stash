#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================================
; SimpleMacroRecorder.ahk — dos slots, sin GUI, sin edición, sin pausas.
;
;   F1, F1 / F1, F2         reproduce slot F1 / F2 (la 2ª tecla dentro de 1 s)
;   F1 mantenido, F1 / F2   graba en slot F1 / F2 (mantener > 0.4 s y soltar)
;                   mientras graba, F1 corta la grabación (F2 se graba)
;                   mientras reproduce, la tecla del slot corta la reproducción
;   Win+Shift+F3    guarda los slots grabados como .ahk en simple-macros\
;   doble clic en un .ahk guardado   lo carga de vuelta en su slot
;
; El master lo lanza y lo mata con Win+F3. Las macros viven en %TEMP% y se
; borran al salir: matarlo limpia los dos slots.
;
; Abrir una macro guardada (doble clic) la carga de vuelta en su slot: el
; archivo relanza este script pasándose como argumento. #SingleInstance Force
; reemplaza a la instancia que corría, y ese reemplazo conserva los slots.
;
; Versión recortada de Macro.Recorder.v2.ahk (branch work): cada macro se
; escribe como un script .ahk y se reproduce en su propio proceso, que define
; la tecla de su slot como ExitApp. Solo coordenadas de pantalla y sin Sleep
; entre acciones (los defaults de aquel script).
; ============================================================================

TempDir   := A_Temp "\ahk_simple_macro"
SaveDir   := A_ScriptDir "\simple-macros"
Slots     := Map("F1", "", "F2", "")   ; tecla -> archivo temporal de la macro
Recording := ""                        ; tecla del slot que se está grabando
LogArr    := []
Pending   := ""                        ; "play" / "rec": F1 espera la 2ª tecla del chord

if (A_Args.Length = 0)
    try DirDelete(TempDir, true)
DirCreate(TempDir)
for key in Slots                       ; lo que dejó la instancia reemplazada
    if FileExist(TempDir "\" key ".ahk")
        Slots[key] := TempDir "\" key ".ahk"
OnExit(Cleanup)

Hotkey("F1", F1Key)
Hotkey("F2", (*) => Chord("F2"), "Off")   ; solo existe como 2ª tecla del chord
Hotkey("#+F3", SaveSlots)

if (A_Args.Length)
    LoadSaved(A_Args[1])
else
    Tip("Simple Macro Recorder: F1 + F1/F2 reproduce, F1 mantenido + F1/F2 graba", 2500)
return

;============ Slots =============

F1Key(*) {
    global Pending
    if (Recording != "") {
        StopRecording()
        KeyWait("F1")
        return
    }
    if (Pending != "")
        return Chord("F1")
    Pending := KeyWait("F1", "T0.4") ? "play" : "rec"
    Tip(Pending = "rec" ? "● REC → F1 / F2" : "▶ PLAY → F1 / F2")
    KeyWait("F1")
    Hotkey("F2", "On")
    SetTimer(ChordEnd, -1000)
}

Chord(key) {
    mode := Pending
    ChordEnd()
    KeyWait(key)
    mode = "rec" ? StartRecording(key) : Play(key)
}

ChordEnd() {
    global Pending := ""
    SetTimer(ChordEnd, 0)
    Hotkey("F2", "Off")
    Tip()
}

StartRecording(key) {
    global Recording := key, LogArr := []
    SetHotkeys(true)
    Tip("● REC " key "  (F1 para terminar)")
}

StopRecording() {
    global Recording, LogArr
    key := Recording
    SetHotkeys(false)
    Recording := ""
    if (LogArr.Length = 0) {
        Tip("Nada grabado en " key, 1500)
        return
    }
    file := TempDir "\" key ".ahk"
    FileOpen(file, "w", "UTF-8").Write(BuildScript(key, LogArr))
    Slots[key] := file
    LogArr := []
    Tip(key " grabada", 1500)
}

Play(key) {
    if (Slots[key] = "" || !FileExist(Slots[key])) {
        Tip(key " está vacío — mantené F1 y después " key " para grabar", 1500)
        return
    }
    Run('"' A_AhkPath '" "' Slots[key] '" play')
}

; Carga una macro guardada en el slot cuya tecla la corta. Se rearma desde las
; acciones, así que también sirve para archivos guardados sin el relanzador.
LoadSaved(path) {
    text := ""
    try text := FileRead(path, "UTF-8")
    if !RegExMatch(text, "m)^(F1|F2)::ExitApp", &k)
      || !RegExMatch(text, 's)CoordMode\("Mouse", "Screen"\)\R(.*?)\R+ExitApp\(\)', &body) {
        Tip("No es una macro de SimpleMacroRecorder:`n" path, 3000)
        return
    }
    lines := []
    for line in StrSplit(body[1], "`n", "`r")
        if (Trim(line) != "")
            lines.Push(line)
    key := k[1]
    file := TempDir "\" key ".ahk"
    FileOpen(file, "w", "UTF-8").Write(BuildScript(key, lines))
    Slots[key] := file
    SplitPath(path, &name)
    Tip(key " cargada: " name, 2500)
}

SaveSlots(*) {
    if (Recording != "")
        StopRecording()
    n := 0
    stamp := FormatTime(, "yyyy-MM-dd HH.mm.ss")
    for key, file in Slots {
        if (file = "" || !FileExist(file))
            continue
        DirCreate(SaveDir)
        FileCopy(file, SaveDir "\" key " " stamp ".ahk", true)
        n++
    }
    Tip(n ? "Guardada(s) " n " macro(s) en simple-macros\" : "No hay macros grabadas", 2000)
}

; Sin el argumento "play" (doble clic sobre un archivo guardado) el script no
; reproduce nada: relanza el grabador para que lo cargue en su slot.
BuildScript(key, lines) {
    s := "#Requires AutoHotkey v2.0`n#SingleInstance Force`n"
       . "; Grabada con SimpleMacroRecorder. " key " corta la reproducción.`n"
       . "; Abrirla la carga en el slot " key " del grabador.`n"
       . "if !(A_Args.Length && A_Args[1] = `"play`") {`n"
       . "    Run('`"' A_AhkPath '`" `"" A_ScriptFullPath "`" `"' A_ScriptFullPath '`"')`n"
       . "    ExitApp()`n}`n`n"
       . "SendMode(`"Event`")`nSetKeyDelay(30)`nCoordMode(`"Mouse`", `"Screen`")`n`n"
    for line in lines
        s .= line "`n"
    return s "`nExitApp()`n`n" key "::ExitApp()`n"
}

; Cierra las reproducciones que sigan corriendo y borra las macros. Si lo
; reemplaza otra instancia (cargar una macro guardada), deja todo como está.
Cleanup(reason, *) {
    if (reason = "Single")
        return
    DetectHiddenWindows(true)
    SetTitleMatchMode(2)
    for key, file in Slots
        if (file != "" && WinExist(file " - AutoHotkey"))
            WinClose()
    try DirDelete(TempDir, true)
}

Tip(s := "", ms := 0) {
    static clear := () => ToolTip()
    ToolTip(s, 10, 10)
    SetTimer(clear, ms ? -ms : 0)   ; un tip fijo cancela el borrado de uno anterior
}

;============ Grabación =============

; Un hook ~* por cada tecla mientras se graba. F1 queda fuera: corta la grabación.
SetHotkeys(on) {
    f := on ? "On" : "Off"
    Loop 254 {
        vk := Format("vk{:X}", A_Index)
        if !(GetKeyName(vk) ~= "^(?i:|Control|Alt|Shift|F1)$")
            Hotkey("~*" vk, LogKey, f)
    }
    for k in ["NumpadEnter", "Home", "End", "PgUp", "PgDn", "Left", "Right", "Up", "Down", "Delete", "Insert"]
        Hotkey("~*" Format("sc{:03X}", GetKeySC(k)), LogKey, f)
}

LogKey(hk) {
    Critical()
    vksc := SubStr(hk, 3)
    k := StrReplace(GetKeyName(vksc), "Control", "Ctrl")
    if (SubStr(k, 2) ~= "^(?i:Alt|Ctrl|Shift|Win)$")
        LogModifier(k)
    else if (k ~= "^(?i:LButton|RButton|MButton)$")
        LogMouse(k)
    else {
        if (k = "NumpadLeft" || k = "NumpadRight") && !GetKeyState(k, "P")
            return
        Log(StrLen(k) > 1 ? "{" k "}" : k ~= "\w" ? k : "{" vksc "}", true)
    }
}

LogModifier(key) {
    k := InStr(key, "Win") ? key : SubStr(key, 2)
    Log("{" k " Down}", true)
    Critical("Off")
    KeyWait(key)
    Critical()
    Log("{" k " Up}", true)
}

; Se loguea el Down antes de esperar al Up para que las teclas apretadas
; durante el click queden en orden; si el mouse no se movió, se vuelve click.
LogMouse(key) {
    b := SubStr(key, 1, 1)
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x1, &y1)
    Log('MouseClick("' b '", ' x1 ', ' y1 ',,, "D")')
    i := LogArr.Length
    Critical("Off")
    KeyWait(key)
    Critical()
    MouseGetPos(&x2, &y2)
    if (Abs(x2 - x1) + Abs(y2 - y1) < 5 && i && i <= LogArr.Length)
        LogArr[i] := 'MouseClick("' b '", ' x1 ', ' y1 ')'
    else
        Log('MouseClick("' b '", ' x2 ', ' y2 ',,, "U")')
}

; Las teclas seguidas se juntan en un solo Send.
Log(str, keyboard := false) {
    if (Recording = "")
        return
    i := LogArr.Length
    if (keyboard && i && InStr(LogArr[i], 'Send("{Blind}') = 1)
        LogArr[i] := SubStr(LogArr[i], 1, -2) str '")'
    else
        LogArr.Push(keyboard ? 'Send("{Blind}' str '")' : str)
}
