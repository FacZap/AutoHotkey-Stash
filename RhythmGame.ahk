#Requires AutoHotkey v2.0
#SingleInstance Force
;=============================================================================
; RhythmGame.ahk  -  juego de ritmo de 4 carriles, estilo osu!mania
;
; Sesion corta: 4 tiempos de cuenta de entrada + 25 segundos de juego.
; Nunca pasa de 30 segundos, incluso en HARD.
;
; Corre como proceso aparte del master. Las teclas D F J K se registran con
; HotIfWinActive contra esta ventana, asi que solo existen mientras el juego
; esta al frente y no chocan con ningun binding del master.
;
; Sin hotkey global: se abre corriendo el archivo (o desde Aux Scripts).
;
; Controles
;   D F J K          golpear los carriles 1..4
;   Izq/Der o 1/2/3  elegir dificultad (en el menu)
;   Enter / Espacio  empezar / reintentar
;   R                reintentar (en la pantalla de resultado)
;   M                sonido on/off
;   Esc              volver al menu / salir
;
; El mejor puntaje y precision por dificultad se guardan en RhythmGame.ini
;=============================================================================

global gK := {}     ; constantes: medidas, colores, dificultades
global gU := {}     ; recursos de dibujo (GDI), ventana, sonidos
global gS := {}     ; estado de la partida

InitConst()
InitSounds()
BuildGui()
LoadSettings()
GoMenu()
DllCall("winmm\timeBeginPeriod", "UInt", 1)
SetTimer(Tick, 16)
return

; ---------------------------------------------------------------------------
; Constantes
; ---------------------------------------------------------------------------
InitConst() {
    global gK

    gK.Ini    := A_ScriptDir "\RhythmGame.ini"
    gK.W      := 480
    gK.H      := 680

    gK.PfX    := 40          ; borde izquierdo de la pista
    gK.PfW    := 400
    gK.LaneW  := 100
    gK.Top    := 78          ; arriba de la pista (las notas nacen aca)
    gK.HitY   := 566         ; linea de golpeo
    gK.Fall   := gK.HitY - gK.Top
    gK.NoteH  := 18
    gK.KeyTop := 580
    gK.KeyH   := 54

    gK.PlayMs := 25000       ; duracion fija de la parte jugable

    ; ventanas de juicio, en milisegundos de distancia al tiempo exacto
    gK.WPerfect := 40
    gK.WGreat   := 80
    gK.WGood    := 125

    gK.Col := {
        bg:    0x0E0F16,
        panel: 0x171A26,
        laneA: 0x13151E,     ; carriles externos
        laneB: 0x171A26,     ; carriles internos
        sep:   0x262A3A,
        txt:   0xE9ECF5,
        dim:   0x8B92A8,
        acc:   0x6EE7F9,
        warn:  0xF87171
    }
    gK.Lane  := [0x38BDF8, 0xF472B6, 0xF472B6, 0x38BDF8]
    gK.Keys  := ["D", "F", "J", "K"]
    gK.JName := ["PERFECT", "GREAT", "GOOD", "MISS"]
    gK.JCol  := [0x67E8F9, 0x86EFAC, 0xFDE68A, 0xF87171]
    gK.JVal  := [300, 200, 100, 0]      ; puntaje base
    gK.JW    := [3, 2, 1, 0]            ; peso para la precision

    ; pOn/pOff = probabilidad de poner nota en un tiempo / contratiempo.
    ; Van de pOn0 (arranque) a pOn1 (final): esa es la rampa de dificultad.
    ; offAt/chordAt = a partir de que fraccion de la sesion se habilitan
    ; contratiempos y acordes. gap = separacion minima entre notas.
    ; spd = cuanto se acelera la caida hacia el final (fraccion).
    gK.Diff := [
        { name: "EASY",   bpm: 100, appr: 900, count: 4,
          pOn0: 0.55, pOn1: 0.95, offAt: 9, pOff: 0.00,
          chordAt: 9, pChord: 0.00, gap: 280, spd: 0.10 },

        { name: "NORMAL", bpm: 132, appr: 760, count: 4,
          pOn0: 0.70, pOn1: 1.00, offAt: 0.45, pOff: 0.60,
          chordAt: 9, pChord: 0.00, gap: 200, spd: 0.18 },

        { name: "HARD",   bpm: 166, appr: 620, count: 4,
          pOn0: 0.88, pOn1: 1.00, offAt: 0.18, pOff: 0.90,
          chordAt: 0.55, pChord: 0.16, gap: 150, spd: 0.22 }
    ]
}

; ---------------------------------------------------------------------------
; Reloj de alta precision (A_TickCount tiene ~15 ms de resolucion: muy poco
; para ventanas de juicio de 40 ms)
; ---------------------------------------------------------------------------
NowMs() {
    static freq := 0
    if (!freq)
        DllCall("QueryPerformanceFrequency", "Int64*", &freq)
    c := 0
    DllCall("QueryPerformanceCounter", "Int64*", &c)
    return c * 1000.0 / freq
}

SongTime() {
    global gS
    return NowMs() - gS.songStart
}

; ---------------------------------------------------------------------------
; Sonido: se generan tres WAV chiquitos una sola vez y se reproducen con
; PlaySound en modo asincronico (SoundBeep bloquea el hilo y arruinaria el
; loop de dibujo)
; ---------------------------------------------------------------------------
InitSounds() {
    global gU
    dir := A_Temp "\ahk_rhythm"
    gU.Snd := Map()
    try {
        if !DirExist(dir)
            DirCreate(dir)
        gU.Snd["tick"]   := dir "\tick.wav"
        gU.Snd["tickhi"] := dir "\tickhi.wav"
        gU.Snd["hit"]    := dir "\hit.wav"
        gU.Snd["miss"]   := dir "\miss.wav"
        MakeWav(gU.Snd["tick"],   1200, 0.035, 0.010, 0.13, false)
        MakeWav(gU.Snd["tickhi"], 1800, 0.040, 0.011, 0.17, false)
        MakeWav(gU.Snd["hit"],    1046, 0.055, 0.014, 0.30, false)
        MakeWav(gU.Snd["miss"],    150, 0.150, 0.045, 0.26, true)
    }
}

; WAV mono 16 bits / 22050 Hz, con caida exponencial y un fade-in corto para
; que no chasquee al arrancar.
MakeWav(path, freq, dur, decay, amp, square) {
    if FileExist(path)
        return
    sr := 22050
    n  := Round(sr * dur)
    buf := Buffer(44 + n * 2, 0)

    StrPut("RIFF", buf.Ptr,      4, "CP0")
    NumPut("UInt", 36 + n * 2,   buf, 4)
    StrPut("WAVE", buf.Ptr + 8,  4, "CP0")
    StrPut("fmt ", buf.Ptr + 12, 4, "CP0")
    NumPut("UInt",   16,     buf, 16)
    NumPut("UShort", 1,      buf, 20)   ; PCM
    NumPut("UShort", 1,      buf, 22)   ; mono
    NumPut("UInt",   sr,     buf, 24)
    NumPut("UInt",   sr * 2, buf, 28)
    NumPut("UShort", 2,      buf, 32)
    NumPut("UShort", 16,     buf, 34)
    StrPut("data", buf.Ptr + 36, 4, "CP0")
    NumPut("UInt", n * 2, buf, 40)

    fade := 80
    loop n {
        i := A_Index - 1
        v := Sin(6.283185307 * freq * i / sr)
        if (square)
            v := (v >= 0) ? 0.55 : -0.55
        env := Exp(-i / (sr * decay))
        if (i < fade)
            env *= i / fade
        NumPut("Short", Round(v * env * amp * 32767), buf, 44 + i * 2)
    }
    f := FileOpen(path, "w")
    f.RawWrite(buf)
    f.Close()
}

PlaySnd(name) {
    global gU, gS
    if (!gS.sound || !gU.Snd.Has(name))
        return
    ; SND_ASYNC | SND_FILENAME | SND_NODEFAULT
    DllCall("winmm\PlaySoundW", "Str", gU.Snd[name], "Ptr", 0, "UInt", 0x1 | 0x20000 | 0x2)
}

; ---------------------------------------------------------------------------
; Ventana y recursos GDI
; ---------------------------------------------------------------------------
BuildGui() {
    global gK, gU

    gU.Gui := Gui("-DPIScale -MaximizeBox -Resize", "Rhythm Speed")
    gU.Gui.BackColor := gK.Col.bg
    gU.Gui.OnEvent("Close", (*) => Shutdown())
    gU.Gui.Show("w" gK.W " h" gK.H)
    gU.Hwnd := gU.Gui.Hwnd

    ; backbuffer: se dibuja todo ahi y se copia de un saque, sin parpadeo
    wdc := DllCall("GetDC", "Ptr", gU.Hwnd, "Ptr")
    gU.Mem := DllCall("gdi32\CreateCompatibleDC", "Ptr", wdc, "Ptr")
    gU.Bmp := DllCall("gdi32\CreateCompatibleBitmap", "Ptr", wdc, "Int", gK.W, "Int", gK.H, "Ptr")
    gU.Old := DllCall("gdi32\SelectObject", "Ptr", gU.Mem, "Ptr", gU.Bmp, "Ptr")
    DllCall("ReleaseDC", "Ptr", gU.Hwnd, "Ptr", wdc)

    gU.F := Map()
    gU.F["title"] := MakeFont(40, 700)
    gU.F["rank"]  := MakeFont(62, 700)
    gU.F["big"]   := MakeFont(30, 700)
    gU.F["combo"] := MakeFont(38, 700)
    gU.F["num"]   := MakeFont(23, 700)
    gU.F["judge"] := MakeFont(20, 700)
    gU.F["med"]   := MakeFont(18, 600)
    gU.F["key"]   := MakeFont(16, 700)
    gU.F["small"] := MakeFont(13, 400)
    gU.F["tiny"]  := MakeFont(11, 600)

    OnMessage(0x0014, WmEraseBkgnd)   ; WM_ERASEBKGND
    RegisterKeys()
}

WmEraseBkgnd(wp, lp, msg, hwnd) {
    global gU
    ; que Windows no borre el fondo: el backbuffer ya cubre toda la ventana
    return (hwnd = gU.Hwnd) ? 1 : ""
}

MakeFont(pt, weight := 400, face := "Segoe UI") {
    return DllCall("gdi32\CreateFontW"
        , "Int", -Round(pt * 96 / 72), "Int", 0, "Int", 0, "Int", 0
        , "Int", weight, "UInt", 0, "UInt", 0, "UInt", 0
        , "UInt", 1      ; DEFAULT_CHARSET
        , "UInt", 0, "UInt", 0
        , "UInt", 5      ; CLEARTYPE_QUALITY
        , "UInt", 0, "Str", face, "Ptr")
}

RegisterKeys() {
    global gU
    HotIfWinActive("ahk_id " gU.Hwnd)
    for i, k in ["d", "f", "j", "k"] {
        Hotkey("*" k, LaneDown.Bind(i))
        Hotkey("*" k " up", LaneUp.Bind(i))
    }
    Hotkey("*Escape",      OnEsc)
    Hotkey("*Enter",       OnEnter)
    Hotkey("*NumpadEnter", OnEnter)
    Hotkey("*Space",       OnEnter)
    Hotkey("*r",     (*) => OnEnter())
    Hotkey("*Left",  (*) => MenuMove(-1))
    Hotkey("*Right", (*) => MenuMove(1))
    Hotkey("*1",     (*) => MenuPick(1))
    Hotkey("*2",     (*) => MenuPick(2))
    Hotkey("*3",     (*) => MenuPick(3))
    Hotkey("*m",     (*) => ToggleSound())
    HotIf()
}

Shutdown() {
    global gU
    SetTimer(Tick, 0)
    try DllCall("winmm\timeEndPeriod", "UInt", 1)
    try {
        DllCall("gdi32\SelectObject", "Ptr", gU.Mem, "Ptr", gU.Old)
        DllCall("gdi32\DeleteObject", "Ptr", gU.Bmp)
        DllCall("gdi32\DeleteDC", "Ptr", gU.Mem)
        for , f in gU.F
            DllCall("gdi32\DeleteObject", "Ptr", f)
    }
    ExitApp()
}

; ---------------------------------------------------------------------------
; Ajustes persistidos
; ---------------------------------------------------------------------------
LoadSettings() {
    global gK, gS
    gS.diff  := Integer(IniRead(gK.Ini, "Settings", "Difficulty", "2"))
    gS.sound := Integer(IniRead(gK.Ini, "Settings", "Sound", "1"))
    if (gS.diff < 1 || gS.diff > 3)
        gS.diff := 2
}

SaveSettings() {
    global gK, gS
    try {
        IniWrite(gS.diff,  gK.Ini, "Settings", "Difficulty")
        IniWrite(gS.sound, gK.Ini, "Settings", "Sound")
    }
}

BestScore(i) {
    global gK
    return Integer(IniRead(gK.Ini, "Best", gK.Diff[i].name, "0"))
}

BestAcc(i) {
    global gK
    return Number(IniRead(gK.Ini, "Best", gK.Diff[i].name "_Acc", "0"))
}

ToggleSound() {
    global gS
    gS.sound := !gS.sound
    SaveSettings()
}

; ---------------------------------------------------------------------------
; Flujo de pantallas
; ---------------------------------------------------------------------------
GoMenu() {
    global gS
    gS.state := "menu"
    gS.notes := []
    gS.held  := [false, false, false, false]
}

MenuMove(d) {
    global gS
    if (gS.state != "menu")
        return
    gS.diff := Mod(gS.diff - 1 + d + 3, 3) + 1
    SaveSettings()
}

MenuPick(i) {
    global gS
    if (gS.state != "menu")
        return
    gS.diff := i
    SaveSettings()
}

OnEsc(*) {
    global gS
    if (gS.state = "menu")
        Shutdown()
    else
        GoMenu()
}

OnEnter(*) {
    global gS
    if (gS.state = "menu" || gS.state = "result")
        StartRun()
}

StartRun() {
    global gK, gS
    d := gK.Diff[gS.diff]

    gS.beat    := 60000.0 / d.bpm
    gS.countIn := d.count * gS.beat
    gS.notes   := BuildChart(d, gS.beat, gS.countIn)
    last       := gS.notes.Length ? gS.notes[gS.notes.Length].t : 0
    gS.endT    := Max(gS.countIn + gK.PlayMs, last + 450)

    gS.score    := 0
    gS.combo    := 0
    gS.maxCombo := 0
    gS.cnt      := [0, 0, 0, 0]
    gS.weight   := 0
    gS.judged   := 0
    gS.acc      := 0
    gS.rank     := "D"
    gS.popTxt   := ""
    gS.popAt    := -99999
    gS.popCol   := 0
    gS.laneFx   := [-99999, -99999, -99999, -99999]
    gS.held     := [false, false, false, false]
    gS.nextBeat := 0
    gS.beatAt   := 0
    gS.paused   := false
    gS.pauseAt  := 0
    gS.newBest  := false
    gS.state    := "play"
    gS.songStart := NowMs()
}

Finish() {
    global gK, gS
    gS.acc  := gS.judged ? (gS.weight / (3.0 * gS.judged)) * 100 : 0
    gS.rank := RankOf(gS.acc, gS.cnt[4])
    gS.newBest := false
    if (gS.score > BestScore(gS.diff)) {
        gS.newBest := true
        try {
            IniWrite(gS.score, gK.Ini, "Best", gK.Diff[gS.diff].name)
            IniWrite(Format("{:.2f}", gS.acc), gK.Ini, "Best", gK.Diff[gS.diff].name "_Acc")
        }
    }
    gS.state := "result"
}

RankOf(acc, misses) {
    if (acc >= 99.5 && misses = 0)
        return "SS"
    if (acc >= 96)
        return "S"
    if (acc >= 92)
        return "A"
    if (acc >= 86)
        return "B"
    if (acc >= 78)
        return "C"
    return "D"
}

; ---------------------------------------------------------------------------
; Generacion del mapa
;
; Se recorre la sesion en corcheas. En cada subdivision se tira un dado cuya
; probabilidad crece con el avance de la sesion: esa es la rampa. Los
; contratiempos (y en HARD los acordes de dos carriles) se habilitan recien
; pasada cierta fraccion. gap corta cualquier combinacion imposible de tocar.
; ---------------------------------------------------------------------------
BuildChart(d, beat, countIn) {
    global gK
    notes := []
    sub   := beat / 2
    first := countIn + beat
    last  := countIn + gK.PlayMs - 400
    span  := last - first
    lastLane := 0
    lastT    := -99999

    t := first
    while (t <= last) {
        prog   := span > 0 ? (t - first) / span : 1
        idx    := Round((t - countIn) / sub)
        onBeat := (Mod(idx, 2) = 0)

        if (onBeat)
            p := d.pOn0 + (d.pOn1 - d.pOn0) * prog
        else if (prog < d.offAt)
            p := 0
        else
            p := d.pOff * (prog - d.offAt) / (1 - d.offAt)

        if (Random() < p && t - lastT >= d.gap) {
            lane := PickLane(lastLane)
            notes.Push({ t: t, lane: lane, judged: false })
            if (prog > d.chordAt && Random() < d.pChord)
                notes.Push({ t: t, lane: OtherLane(lane), judged: false })
            lastLane := lane
            lastT    := t
        }
        t += sub
    }
    return notes
}

PickLane(prev) {
    lane := Random(1, 4)
    ; se permite repetir carril, pero poco: dos golpes seguidos con el mismo
    ; dedo es lo que mas rompe una tirada rapida
    if (lane = prev && Random() > 0.25)
        lane := OtherLane(lane)
    return lane
}

OtherLane(lane) {
    return Mod(lane - 1 + Random(1, 3), 4) + 1
}

; ---------------------------------------------------------------------------
; Entrada
; ---------------------------------------------------------------------------
LaneDown(lane, *) {
    global gK, gS
    if (gS.state != "play" || gS.paused)
        return
    if (gS.held[lane])          ; ignorar la repeticion automatica del teclado
        return
    gS.held[lane] := true

    now   := SongTime()
    best  := 0
    bestD := 99999
    for n in gS.notes {
        if (n.t - now > 400)    ; el mapa esta ordenado por tiempo
            break
        if (n.judged || n.lane != lane)
            continue
        dd := Abs(n.t - now)
        if (dd < bestD) {
            bestD := dd
            best  := n
        }
    }
    if (!best || bestD > gK.WGood)
        return                  ; golpe al aire: no descuenta nada

    kind := (bestD <= gK.WPerfect) ? 1 : (bestD <= gK.WGreat) ? 2 : 3
    best.judged := true
    Judge(kind, lane)
}

LaneUp(lane, *) {
    global gS
    gS.held[lane] := false
}

Judge(kind, lane) {
    global gK, gS
    gS.judged++
    gS.cnt[kind]++
    gS.weight += gK.JW[kind]

    if (kind = 4) {
        gS.combo := 0
        PlaySnd("miss")
    } else {
        mult := 1 + Min(gS.combo, 50) / 100.0     ; hasta x1.5
        gS.score += Round(gK.JVal[kind] * mult)
        gS.combo++
        gS.maxCombo := Max(gS.maxCombo, gS.combo)
        gS.laneFx[lane] := SongTime()
        PlaySnd("hit")
    }
    gS.popTxt := gK.JName[kind]
    gS.popCol := gK.JCol[kind]
    gS.popAt  := SongTime()
}

; ---------------------------------------------------------------------------
; Loop principal
; ---------------------------------------------------------------------------
Tick() {
    global gS
    if (gS.state = "play")
        Update()
    Draw()
}

Update() {
    global gK, gS, gU

    ; si la ventana pierde el foco las teclas dejan de existir, asi que se
    ; congela el reloj en vez de comerse las notas
    active := WinActive("ahk_id " gU.Hwnd)
    if (gS.paused) {
        if (!active)
            return
        gS.songStart += NowMs() - gS.pauseAt
        gS.paused := false
    } else if (!active) {
        gS.paused  := true
        gS.pauseAt := NowMs()
        gS.held    := [false, false, false, false]
        return
    }

    now := SongTime()

    ; metronomo
    while (gS.nextBeat * gS.beat <= now) {
        b := gS.nextBeat
        if (b * gS.beat <= gS.countIn + gK.PlayMs) {
            PlaySnd(Mod(b, 4) = 0 ? "tickhi" : "tick")
            gS.beatAt := b * gS.beat
        }
        gS.nextBeat++
    }

    ; notas que se pasaron de la ventana
    for n in gS.notes {
        if (!n.judged && now - n.t > gK.WGood) {
            n.judged := true
            Judge(4, n.lane)
        }
    }

    if (now >= gS.endT)
        Finish()
}

; ---------------------------------------------------------------------------
; Dibujo (GDI sobre el backbuffer)
; ---------------------------------------------------------------------------
Draw() {
    global gK, gS, gU
    R(0, 0, gK.W, gK.H, gK.Col.bg)
    switch gS.state {
        case "menu":   DrawMenu()
        case "play":   DrawPlay()
        case "result": DrawResult()
    }
    hdc := DllCall("GetDC", "Ptr", gU.Hwnd, "Ptr")
    DllCall("gdi32\BitBlt", "Ptr", hdc, "Int", 0, "Int", 0, "Int", gK.W, "Int", gK.H
                          , "Ptr", gU.Mem, "Int", 0, "Int", 0, "UInt", 0x00CC0020)
    DllCall("ReleaseDC", "Ptr", gU.Hwnd, "Ptr", hdc)
}

R(x, y, w, h, col) {
    global gU
    if (w <= 0 || h <= 0)
        return
    rc := Buffer(16)
    NumPut("Int", x, rc, 0), NumPut("Int", y, rc, 4)
    NumPut("Int", x + w, rc, 8), NumPut("Int", y + h, rc, 12)
    br := DllCall("gdi32\CreateSolidBrush", "UInt", BGR(col), "Ptr")
    DllCall("user32\FillRect", "Ptr", gU.Mem, "Ptr", rc, "Ptr", br)
    DllCall("gdi32\DeleteObject", "Ptr", br)
}

Frame(x, y, w, h, col, bw := 1) {
    R(x, y, w, bw, col)
    R(x, y + h - bw, w, bw, col)
    R(x, y, bw, h, col)
    R(x + w - bw, y, bw, h, col)
}

; fmt: 37 = centrado, 36 = izquierda, 38 = derecha (todos vcenter+singleline)
T(txt, x, y, w, h, col, font, fmt := 37) {
    global gU
    DllCall("gdi32\SelectObject", "Ptr", gU.Mem, "Ptr", gU.F[font])
    DllCall("gdi32\SetTextColor", "Ptr", gU.Mem, "UInt", BGR(col))
    DllCall("gdi32\SetBkMode", "Ptr", gU.Mem, "Int", 1)
    rc := Buffer(16)
    NumPut("Int", x, rc, 0), NumPut("Int", y, rc, 4)
    NumPut("Int", x + w, rc, 8), NumPut("Int", y + h, rc, 12)
    DllCall("user32\DrawTextW", "Ptr", gU.Mem, "Str", String(txt), "Int", -1, "Ptr", rc, "UInt", fmt)
}

BGR(c) {
    return ((c & 0xFF) << 16) | (c & 0xFF00) | ((c >> 16) & 0xFF)
}

; GDI no tiene alpha barato, asi que los brillos se hacen mezclando colores
Mix(a, b, t) {
    t := Max(0, Min(1, t))
    r := Round(((a >> 16) & 0xFF) + (((b >> 16) & 0xFF) - ((a >> 16) & 0xFF)) * t)
    g := Round(((a >> 8)  & 0xFF) + (((b >> 8)  & 0xFF) - ((a >> 8)  & 0xFF)) * t)
    l := Round((a & 0xFF) + ((b & 0xFF) - (a & 0xFF)) * t)
    return (r << 16) | (g << 8) | l
}

Comma(n) {
    s   := String(Round(n))
    out := ""
    len := StrLen(s)
    loop len {
        i   := len - A_Index + 1
        out := SubStr(s, i, 1) . out
        if (Mod(A_Index, 3) = 0 && A_Index < len)
            out := "," . out
    }
    return out
}

; ---------------------------------------------------------------------------
DrawMenu() {
    global gK, gS

    T("RHYTHM SPEED", 0, 38, gK.W, 52, gK.Col.txt, "title")
    T("4 carriles - sesion de 25 segundos", 0, 92, gK.W, 20, gK.Col.dim, "small")

    cy := 140, ch := 168, cw := 130
    loop 3 {
        i  := A_Index
        d  := gK.Diff[i]
        cx := 25 + (i - 1) * 150
        on := (i = gS.diff)

        R(cx, cy, cw, ch, on ? Mix(gK.Col.panel, gK.Col.acc, 0.16) : gK.Col.panel)
        Frame(cx, cy, cw, ch, on ? gK.Col.acc : gK.Col.sep, on ? 2 : 1)

        T(d.name, cx, cy + 14, cw, 26, on ? gK.Col.txt : gK.Col.dim, "med")
        T(d.bpm " BPM", cx, cy + 40, cw, 18, gK.Col.dim, "tiny")
        R(cx + 20, cy + 66, cw - 40, 1, gK.Col.sep)
        T("MEJOR", cx, cy + 76, cw, 16, gK.Col.dim, "tiny")
        T(Comma(BestScore(i)), cx, cy + 96, cw, 30, on ? gK.Col.acc : gK.Col.txt, "num")
        b := BestAcc(i)
        T(b > 0 ? Format("{:.2f}%", b) : "-", cx, cy + 128, cw, 18, gK.Col.dim, "small")
    }

    ; muestra de los cuatro carriles con sus teclas
    ky := 344
    loop 4 {
        i  := A_Index
        lx := gK.PfX + (i - 1) * gK.LaneW
        R(lx, ky, gK.LaneW - 2, 54, Mix(gK.Col.bg, gK.Lane[i], 0.16))
        R(lx, ky, gK.LaneW - 2, 3, gK.Lane[i])
        T(gK.Keys[i], lx, ky, gK.LaneW - 2, 54, gK.Lane[i], "key")
    }

    T("Enter  empezar          Izq / Der  elegir dificultad", 0, 424, gK.W, 20, gK.Col.dim, "small")
    T("Esc  salir          M  sonido: " (gS.sound ? "ON" : "OFF"), 0, 448, gK.W, 20, gK.Col.dim, "small")

    R(60, 494, gK.W - 120, 1, gK.Col.sep)
    T("Ventanas de juicio", 0, 502, gK.W, 20, gK.Col.dim, "tiny")
    loop 3 {
        i := A_Index
        w := (i = 1) ? gK.WPerfect : (i = 2) ? gK.WGreat : gK.WGood
        x := 40 + (i - 1) * 134
        T(gK.JName[i], x, 526, 132, 20, gK.JCol[i], "tiny")
        T("+-" w " ms", x, 546, 132, 20, gK.Col.dim, "small")
    }

    T("El combo multiplica el puntaje hasta x1.5 (tope: 50 de combo)",
      0, 596, gK.W, 20, gK.Col.dim, "small")
    T("La ventana se pausa sola si pierde el foco", 0, 618, gK.W, 20, gK.Col.dim, "small")
}

; ---------------------------------------------------------------------------
DrawPlay() {
    global gK, gS
    d   := gK.Diff[gS.diff]
    now := SongTime()

    ; --- pista ---
    loop 4 {
        i  := A_Index
        lx := gK.PfX + (i - 1) * gK.LaneW
        base := (i = 1 || i = 4) ? gK.Col.laneA : gK.Col.laneB
        if (gS.held[i])
            base := Mix(base, gK.Lane[i], 0.22)
        R(lx, gK.Top, gK.LaneW, gK.HitY - gK.Top + 4, base)
        if (i > 1)
            R(lx, gK.Top, 1, gK.HitY - gK.Top + 4, gK.Col.sep)
    }
    Frame(gK.PfX, gK.Top, gK.PfW, gK.HitY - gK.Top + 4, gK.Col.sep)

    ; --- notas ---
    for n in gS.notes {
        if (n.judged)
            continue
        prog := Max(0, Min(1, (n.t - gS.countIn) / gK.PlayMs))
        appr := d.appr * (1 - d.spd * prog)        ; la caida se acelera de a poco
        dt   := n.t - now
        if (dt > appr || dt < -gK.WGood - 60)
            continue
        cyc := gK.HitY - (dt / appr) * gK.Fall
        y1  := Max(Round(cyc - gK.NoteH / 2), gK.Top + 1)
        y2  := Min(Round(cyc + gK.NoteH / 2), gK.HitY + 20)
        if (y2 <= y1)
            continue
        lx := gK.PfX + (n.lane - 1) * gK.LaneW
        R(lx + 8, y1, gK.LaneW - 16, y2 - y1, gK.Lane[n.lane])
        if (y1 > gK.Top + 1)
            R(lx + 8, y1, gK.LaneW - 16, 3, Mix(gK.Lane[n.lane], 0xFFFFFF, 0.55))
    }

    ; --- linea de golpeo, con pulso en cada tiempo ---
    pulse := 0
    if (gS.beatAt > 0) {
        age := (now - gS.beatAt) / 220
        if (age >= 0 && age < 1)
            pulse := (1 - age) * 0.5
    }
    loop 4 {
        i  := A_Index
        lx := gK.PfX + (i - 1) * gK.LaneW
        fx := (now - gS.laneFx[i]) / 160
        if (fx >= 0 && fx < 1)
            R(lx + 2, gK.HitY - 26, gK.LaneW - 4, 26, Mix(gK.Col.laneB, gK.Lane[i], 0.45 * (1 - fx)))
    }
    R(gK.PfX, gK.HitY - 2, gK.PfW, 4, Mix(gK.Col.sep, gK.Col.acc, 0.35 + pulse))

    ; --- teclas ---
    loop 4 {
        i  := A_Index
        lx := gK.PfX + (i - 1) * gK.LaneW
        bg := gS.held[i] ? Mix(gK.Col.panel, gK.Lane[i], 0.55) : gK.Col.panel
        R(lx + 2, gK.KeyTop, gK.LaneW - 4, gK.KeyH, bg)
        Frame(lx + 2, gK.KeyTop, gK.LaneW - 4, gK.KeyH, gS.held[i] ? gK.Lane[i] : gK.Col.sep)
        T(gK.Keys[i], lx + 2, gK.KeyTop, gK.LaneW - 4, gK.KeyH
          , gS.held[i] ? 0xFFFFFF : gK.Lane[i], "key")
    }

    ; --- combo ---
    if (gS.combo >= 2) {
        T(gS.combo, 0, 236, gK.W, 46, Mix(gK.Col.bg, gK.Col.txt, 0.42), "combo")
        T("COMBO", 0, 282, gK.W, 18, Mix(gK.Col.bg, gK.Col.dim, 0.60), "tiny")
    }

    ; --- juicio ---
    age := now - gS.popAt
    if (gS.popTxt != "" && age >= 0 && age < 400)
        T(gS.popTxt, 0, 456 - Round(age / 40), gK.W, 26
          , Mix(gK.Col.bg, gS.popCol, 1 - age / 400), "judge")

    ; --- encabezado ---
    T(Comma(gS.score), gK.PfX, 12, 240, 30, gK.Col.txt, "num", 36)
    acc := gS.judged ? (gS.weight / (3.0 * gS.judged)) * 100 : 100
    T(Format("{:.2f}%", acc), gK.W - gK.PfX - 240, 12, 240, 30, gK.Col.acc, "num", 38)
    T(d.name "  -  " d.bpm " BPM", gK.PfX, 40, 240, 18, gK.Col.dim, "small", 36)
    T("Esc  menu", gK.W - gK.PfX - 240, 40, 240, 18, gK.Col.dim, "small", 38)

    R(gK.PfX, 64, gK.PfW, 5, gK.Col.panel)
    tp := Max(0, Min(1, (now - gS.countIn) / gK.PlayMs))
    R(gK.PfX, 64, Round(gK.PfW * tp), 5, gK.Col.acc)

    ; --- cuenta de entrada y pausa ---
    if (now < gS.countIn) {
        left := Ceil((gS.countIn - now) / gS.beat)
        T(left >= 4 ? "LISTO" : String(left), 0, 300, gK.W, 70, gK.Col.txt, "title")
    } else if (now < gS.countIn + 400) {
        T("YA", 0, 300, gK.W, 70, gK.Col.acc, "title")
    }
    if (gS.paused) {
        R(gK.PfX, 280, gK.PfW, 110, gK.Col.panel)
        Frame(gK.PfX, 280, gK.PfW, 110, gK.Col.acc, 2)
        T("EN PAUSA", 0, 300, gK.W, 34, gK.Col.txt, "big")
        T("Volve a la ventana para seguir", 0, 344, gK.W, 20, gK.Col.dim, "small")
    }
}

; ---------------------------------------------------------------------------
DrawResult() {
    global gK, gS
    d := gK.Diff[gS.diff]

    T("RESULTADO  -  " d.name, 0, 30, gK.W, 22, gK.Col.dim, "small")

    rc := (gS.rank = "SS" || gS.rank = "S") ? gK.Col.acc
        : (gS.rank = "A" || gS.rank = "B")  ? 0x86EFAC
        : (gS.rank = "C")                   ? 0xFDE68A : gK.Col.warn
    T(gS.rank, 0, 58, gK.W, 84, rc, "rank")

    T("PUNTAJE", 0, 152, gK.W, 18, gK.Col.dim, "tiny")
    T(Comma(gS.score), 0, 172, gK.W, 40, gK.Col.txt, "big")

    T("PRECISION", 40, 224, 190, 18, gK.Col.dim, "tiny")
    T(Format("{:.2f}%", gS.acc), 40, 244, 190, 30, gK.Col.acc, "num")
    T("COMBO MAX", 250, 224, 190, 18, gK.Col.dim, "tiny")
    T(gS.maxCombo, 250, 244, 190, 30, gK.Col.txt, "num")

    R(60, 292, gK.W - 120, 1, gK.Col.sep)
    loop 4 {
        i := A_Index
        y := 302 + (i - 1) * 34
        R(70, y + 10, 10, 10, gK.JCol[i])
        T(gK.JName[i], 92, y, 180, 30, gK.Col.txt, "med", 36)
        T(gS.cnt[i], gK.W - 250, y, 180, 30, gK.JCol[i], "med", 38)
    }
    R(60, 444, gK.W - 120, 1, gK.Col.sep)

    T("Notas: " gS.notes.Length, 0, 456, gK.W, 20, gK.Col.dim, "small")
    if (gS.newBest)
        T("NUEVO RECORD", 0, 486, gK.W, 26, gK.Col.acc, "judge")
    else
        T("Mejor: " Comma(BestScore(gS.diff)) "   ("
          Format("{:.2f}%", BestAcc(gS.diff)) ")", 0, 486, gK.W, 26, gK.Col.dim, "small")

    T("Enter o R   otra vez", 0, 592, gK.W, 22, gK.Col.txt, "small")
    T("Esc   volver al menu", 0, 616, gK.W, 22, gK.Col.dim, "small")
}
