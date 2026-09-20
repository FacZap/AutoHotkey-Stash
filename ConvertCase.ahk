#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================================
; ConvertCase.ahk  —  Convert the selected text to another case, from a GUI.
;
; Ctrl+F2   Grab the selection (or the clipboard, when nothing is selected)
;           and open the converter window.
;
; The window lists every style with a live preview of the current text, in
; three groups:
;
;   Text   lower / UPPER / Title / Sentence / iNVERTED, and trim-and-collapse
;   Code   camelCase, PascalCase, snake_case, SCREAMING_SNAKE_CASE, Ada_Case,
;          kebab-case, Train-Case, COBOL-CASE, dot.case, path/case, flatcase
;   File   url-slug, file_name, FileName, a date-prefixed slug, a name with
;          the characters Windows rejects removed, and plain ASCII
;
; Pick one (click, or the arrow keys) and the Result box below shows it —
; editable, in case the conversion needs a manual touch. Then:
;
;   Replace       paste the result back over the selection in the original
;                 window (Enter, or double-click a style)
;   Copy          put the result on the clipboard and close
;   Cancel        close, changing nothing (Esc)
;
; The Source box is editable too, so the window works as a scratchpad even
; with no selection: type or paste there and the previews follow.
;
; The clipboard is saved and restored around both the copy and the paste, so
; whatever was on it survives a conversion.
; ============================================================================

global CcGui := ""          ; the converter window, while it is open
global CcSource := ""       ; Source edit control
global CcList := ""         ; ListView of styles + previews
global CcResult := ""       ; Result edit control
global CcLblSource := "", CcLblStyle := "", CcLblResult := ""
global CcButtons := []      ; Replace / Copy / Cancel, for the layout routine
global CcTargetHwnd := 0    ; window the text came from, to paste back into
global CcHadSelection := false

^F2::OpenConvertCase()

; ============================================================================
; Entry point
; ============================================================================

OpenConvertCase() {
    global CcTargetHwnd, CcHadSelection

    hwnd := WinExist("A")
    text := GetSelectedText()

    ; No selection: fall back to the clipboard's text, so a copy from anywhere
    ; can be converted too.
    if (text = "") {
        CcHadSelection := false
        try text := A_Clipboard
    } else {
        CcHadSelection := true
    }

    CcTargetHwnd := hwnd
    ShowConvertGui(text)
}

; ============================================================================
; GUI
; ============================================================================

; Group, style name, converter. The order here is the order in the list; the
; group is only there to keep the three families visually apart.
CcStyles() {
    static styles := [
        ["Text",  "lower case",              ToLowerCase],
        ["Text",  "UPPER CASE",              ToUpperCase],
        ["Text",  "Title Case",              ToTitleCase],
        ["Text",  "Sentence case",           ToSentenceCase],
        ["Text",  "iNVERTED cASE",           ToInvertedCase],
        ["Text",  "Trim + collapse spaces",  ToTrimmed],

        ["Code",  "camelCase",               ToCamelCase],
        ["Code",  "PascalCase",              ToPascalCase],
        ["Code",  "snake_case",              ToSnakeCase],
        ["Code",  "SCREAMING_SNAKE_CASE",    ToScreamingSnake],
        ["Code",  "Ada_Case",                ToAdaCase],
        ["Code",  "kebab-case",              ToKebabCase],
        ["Code",  "Train-Case (HTTP header)", ToTrainCase],
        ["Code",  "COBOL-CASE",              ToCobolCase],
        ["Code",  "dot.case",                ToDotCase],
        ["Code",  "path/case",               ToPathCase],
        ["Code",  "flatcase",                ToFlatCase],
        ["Code",  "UPPERFLATCASE",           ToUpperFlatCase],
        ["Code",  "space separated",         ToSpaceCase],

        ["File",  "url-slug",                ToUrlSlug],
        ["File",  "file_name",               ToFileSnake],
        ["File",  "FileName",                ToFilePascal],
        ["File",  "yyyy-mm-dd-slug (dated)", ToDatedSlug],
        ["File",  "Windows-safe name",       ToWindowsSafeName],
        ["File",  "ASCII (drop accents)",    StripAccents],
    ]
    return styles
}

ShowConvertGui(text) {
    global CcGui, CcSource, CcList, CcResult
    global CcLblSource, CcLblStyle, CcLblResult, CcButtons

    if CcGui {
        try CcGui.Destroy()
        CcGui := ""
    }

    g := Gui("+AlwaysOnTop +Resize +MinSize560x460", "Convert Case")
    g.SetFont("s10", "Segoe UI")
    CcGui := g

    CcLblSource := g.AddText("w480", "Source:")
    CcSource := g.AddEdit("w480 -Wrap +HScroll", text)
    CcSource.OnEvent("Change", (*) => RefreshPreviews())

    CcLblStyle := g.AddText("w480", "Style:")
    CcList := g.AddListView("w480 -Multi +Grid NoSortHdr", ["", "Style", "Preview"])
    CcList.OnEvent("ItemSelect", (*) => ShowSelectedStyle())
    CcList.OnEvent("DoubleClick", (*) => ApplyResult())

    CcLblResult := g.AddText("w480", "Result:")
    CcResult := g.AddEdit("w480 -Wrap +HScroll")

    CcButtons := []
    CcButtons.Push(g.AddButton("w150 Default", "Replace"))
    CcButtons.Push(g.AddButton("w150", "Copy"))
    CcButtons.Push(g.AddButton("w150", "Cancel"))
    CcButtons[1].OnEvent("Click", (*) => ApplyResult())
    CcButtons[2].OnEvent("Click", (*) => CopyResult())
    CcButtons[3].OnEvent("Click", (*) => CloseConvertGui())

    g.OnEvent("Close", (*) => CloseConvertGui())
    g.OnEvent("Escape", (*) => CloseConvertGui())
    g.OnEvent("Size", (guiObj, minMax, w, h) => minMax != -1 ? LayoutConvertGui(w, h) : "")

    RefreshPreviews()
    CcList.Modify(1, "Select Focus")
    ShowSelectedStyle()

    LayoutConvertGui(560, 520)
    g.Show("w560 h520")
    CcList.Focus()
    ; Enter should apply even while the caret sits in one of the edit boxes,
    ; which a Default button does not cover on its own.
    HotIfWinActive("ahk_id " g.Hwnd)
    Hotkey "Enter", (*) => ApplyResult(), "On"
    Hotkey "NumpadEnter", (*) => ApplyResult(), "On"
    HotIfWinActive()
}

; Single layout routine, used for the initial placement and on every resize:
; both edit boxes and the button row keep a fixed height, and the ListView
; absorbs whatever vertical space is left.
LayoutConvertGui(w, h) {
    global CcSource, CcList, CcResult, CcLblSource, CcLblStyle, CcLblResult, CcButtons

    static margin := 10, labelH := 20, editH := 58, btnH := 32, gap := 6

    inner := w - margin * 2
    if (inner < 240)
        return

    ; From the top: label + Source, label, then the list.
    y := margin
    CcLblSource.Move(margin, y, inner, labelH)
    y += labelH
    CcSource.Move(margin, y, inner, editH)
    y += editH + gap
    CcLblStyle.Move(margin, y, inner, labelH)
    y += labelH

    ; From the bottom: buttons, Result, its label. What remains is the list.
    btnY := h - margin - btnH
    resultY := btnY - margin - editH
    lblResultY := resultY - labelH

    listH := lblResultY - gap - y
    if (listH < 80)
        listH := 80

    CcList.Move(margin, y, inner, listH)
    CcLblResult.Move(margin, lblResultY, inner, labelH)
    CcResult.Move(margin, resultY, inner, editH)

    btnW := (inner - margin * 2) // 3
    x := margin
    for btn in CcButtons {
        btn.Move(x, btnY, btnW, btnH)
        x += btnW + margin
    }

    CcList.ModifyCol(1, 44)
    CcList.ModifyCol(2, 176)
    CcList.ModifyCol(3, inner - 44 - 176 - 24)
    CcList.Redraw()
}

; Recompute every preview from the current Source text.
RefreshPreviews() {
    global CcSource, CcList

    text := CcSource.Value
    sel := CcList.GetNext(0, "F")

    CcList.Opt("-Redraw")
    CcList.Delete()
    for style in CcStyles()
        CcList.Add(, style[1], style[2], PreviewOf(style[3](text)))
    if (sel > 0)
        CcList.Modify(sel, "Select Focus")
    CcList.Opt("+Redraw")

    ShowSelectedStyle()
}

; Newlines and tabs would break the single-line row, so show them as symbols.
PreviewOf(s) {
    s := StrReplace(s, "`r`n", " ⏎ ")
    s := StrReplace(s, "`n", " ⏎ ")
    s := StrReplace(s, "`t", " → ")
    return s
}

ShowSelectedStyle() {
    global CcSource, CcList, CcResult

    row := CcList.GetNext(0, "F")
    if (row < 1)
        row := CcList.GetNext(0)
    if (row < 1) {
        CcResult.Value := ""
        return
    }
    styles := CcStyles()
    if (row > styles.Length)
        return
    CcResult.Value := styles[row][3](CcSource.Value)
}

; ============================================================================
; Actions
; ============================================================================

ApplyResult() {
    global CcResult, CcTargetHwnd, CcHadSelection

    text := CcResult.Value
    if (text = "") {
        Flash("Nothing to paste.")
        return
    }
    if !CcTargetHwnd || !WinExist("ahk_id " CcTargetHwnd) {
        Flash("The original window is gone — copying instead.")
        CopyResult()
        return
    }

    CloseConvertGui()

    try WinActivate("ahk_id " CcTargetHwnd)
    if !WinWaitActive("ahk_id " CcTargetHwnd, , 1) {
        SetClipboardText(text)
        Flash("Could not focus the window — result copied.")
        return
    }

    PasteText(text)
    ; With no selection there was nothing to overwrite, which is worth saying:
    ; the text was inserted at the caret.
    if !CcHadSelection
        Flash("Pasted at the caret (nothing was selected).")
}

CopyResult() {
    global CcResult

    text := CcResult.Value
    if (text = "") {
        Flash("Nothing to copy.")
        return
    }
    SetClipboardText(text)
    CloseConvertGui()
    Flash("Copied.")
}

CloseConvertGui() {
    global CcGui

    if !CcGui
        return
    HotIfWinActive("ahk_id " CcGui.Hwnd)
    try Hotkey "Enter", "Off"
    try Hotkey "NumpadEnter", "Off"
    HotIfWinActive()
    try CcGui.Destroy()
    CcGui := ""
}

; ============================================================================
; Clipboard
; ============================================================================

; Copies the current selection without leaving it on the clipboard.
GetSelectedText() {
    saved := ClipboardAll()
    A_Clipboard := ""
    Send "^c"
    got := ClipWait(0.6, 0)
    text := got ? A_Clipboard : ""
    A_Clipboard := saved
    return text
}

; Pastes through the clipboard rather than SendText: it is instant regardless
; of length and does not misfire on accented characters or dead keys.
PasteText(text) {
    saved := ClipboardAll()
    A_Clipboard := text
    if !ClipWait(1, 1) {
        A_Clipboard := saved
        Flash("Clipboard is busy — nothing pasted.")
        return
    }
    Send "^v"
    Sleep 200          ; let the target read the clipboard before we take it back
    A_Clipboard := saved
}

SetClipboardText(text) {
    A_Clipboard := text
    ClipWait(1, 1)
}

Flash(msg) {
    ToolTip msg
    SetTimer () => ToolTip(), -1600
}

; ============================================================================
; Conversions
;
; The word-based styles (camel, snake, kebab, …) all go through SplitWords,
; so any input shape converts to any other: THIS_IS_AN_EXAMPLE, thisIsAnExample
; and "this is an example" all split to the same four words.
; ============================================================================

; Splits on separators, or — when the text has no separator at all — on
; camel-case humps.
;
; Humps are only consulted for separator-less text on purpose. Text that
; already carries separators has said where its words end, and honouring that
; is what keeps erratically-typed input intact: tHIS_Is_an_ExAmPLE splits into
; four words, not into the eight the humps would suggest.
SplitWords(s) {
    if !RegExMatch(s, "[^\p{L}\p{N}]") {
        ; aB and 1B -> a B / 1 B     (lower/digit followed by upper)
        s := RegExReplace(s, "(\p{Ll}|\p{N})(\p{Lu})", "$1 $2")
        ; HTMLParser -> HTML Parser  (run of uppers followed by an upper+lower)
        s := RegExReplace(s, "(\p{Lu})(\p{Lu}\p{Ll})", "$1 $2")
    }
    s := RegExReplace(s, "[^\p{L}\p{N}]+", " ")

    words := []
    for w in StrSplit(Trim(s), " ")
        if (w != "")
            words.Push(w)
    return words
}

Join(words, sep, mode) {
    out := ""
    for i, w in words {
        switch mode {
            case "lower": w := StrLower(w)
            case "upper": w := StrUpper(w)
            case "cap":   w := StrUpper(SubStr(w, 1, 1)) StrLower(SubStr(w, 2))
        }
        out .= (i > 1 ? sep : "") w
    }
    return out
}

ToLowerCase(s) => StrLower(s)
ToUpperCase(s) => StrUpper(s)

ToTitleCase(s) {
    out := ""
    prevAlnum := false
    loop parse s {
        ch := A_LoopField
        isAlnum := RegExMatch(ch, "[\p{L}\p{N}]") > 0
        out .= (isAlnum && !prevAlnum) ? StrUpper(ch) : StrLower(ch)
        prevAlnum := isAlnum
    }
    return out
}

; First letter of every sentence, the rest lowered. A sentence starts at the
; text's beginning and after . ! ? or a line break.
ToSentenceCase(s) {
    s := StrLower(s)
    out := ""
    atStart := true
    loop parse s {
        ch := A_LoopField
        if (atStart && RegExMatch(ch, "[\p{L}\p{N}]")) {
            out .= StrUpper(ch)
            atStart := false
            continue
        }
        out .= ch
        if InStr(".!?`n", ch)
            atStart := true
    }
    return out
}

ToInvertedCase(s) {
    out := ""
    loop parse s {
        ch := A_LoopField
        up := StrUpper(ch)
        out .= (ch == up) ? StrLower(ch) : up
    }
    return out
}

ToCamelCase(s) {
    words := SplitWords(s)
    if !words.Length
        return ""
    out := StrLower(words[1])
    loop words.Length - 1
        out .= StrUpper(SubStr(words[A_Index + 1], 1, 1)) StrLower(SubStr(words[A_Index + 1], 2))
    return out
}

ToPascalCase(s) => Join(SplitWords(s), "", "cap")
ToSnakeCase(s) => Join(SplitWords(s), "_", "lower")
ToScreamingSnake(s) => Join(SplitWords(s), "_", "upper")
ToAdaCase(s) => Join(SplitWords(s), "_", "cap")
ToKebabCase(s) => Join(SplitWords(s), "-", "lower")
ToTrainCase(s) => Join(SplitWords(s), "-", "cap")
ToCobolCase(s) => Join(SplitWords(s), "-", "upper")
ToDotCase(s) => Join(SplitWords(s), ".", "lower")
ToPathCase(s) => Join(SplitWords(s), "/", "lower")
ToFlatCase(s) => Join(SplitWords(s), "", "lower")
ToUpperFlatCase(s) => Join(SplitWords(s), "", "upper")
ToSpaceCase(s) => Join(SplitWords(s), " ", "lower")

; Leaves the case alone: strips leading/trailing blanks and squeezes runs of
; spaces and tabs, which is what mangled pasted text usually needs.
ToTrimmed(s) => Trim(RegExReplace(s, "[ \t]+", " "))

; ============================================================================
; File and URL names
;
; These go through StripAccents first: a name that has to survive a URL, a git
; branch, an S3 key or someone else's filesystem is safer as plain ASCII.
; ============================================================================

ToUrlSlug(s) => Join(SplitWords(StripAccents(s)), "-", "lower")
ToFileSnake(s) => Join(SplitWords(StripAccents(s)), "_", "lower")
ToFilePascal(s) => Join(SplitWords(StripAccents(s)), "", "cap")

; Today's date in front of the slug, for the dated-notes style of filename.
ToDatedSlug(s) {
    slug := ToUrlSlug(s)
    return FormatTime(A_Now, "yyyy-MM-dd") (slug = "" ? "" : "-" slug)
}

; The least destructive option: keeps the words, spaces and case as typed and
; only removes what Windows refuses in a name — \ / : * ? " < > | — plus the
; trailing dots and spaces Explorer silently eats.
ToWindowsSafeName(s) {
    s := StrReplace(s, "`r`n", " ")
    s := StrReplace(s, "`n", " ")
    s := StrReplace(s, "`t", " ")
    s := RegExReplace(s, '[\\/:*?"<>|]', "-")
    s := RegExReplace(s, "[ \t]+", " ")
    s := RegExReplace(s, "-{2,}", "-")
    ; Explorer eats trailing dots and spaces; a dash left where a stripped
    ; character used to be is just noise, at either end.
    return RegExReplace(RegExReplace(Trim(s), "^-+"), "[-. ]+$")
}

; Folds accented Latin letters onto their ASCII base, leaving everything else
; (case, separators, punctuation) alone.
StripAccents(s) {
    static from := "áàäâãåéèëêíìïîóòöôõøúùüûýÿñçšžÁÀÄÂÃÅÉÈËÊÍÌÏÎÓÒÖÔÕØÚÙÜÛÝÑÇŠŽ"
    static to   := "aaaaaaeeeeiiiioooooouuuuyyncszAAAAAAEEEEIIIIOOOOOOUUUUYNCSZ"
    static pairs := Map("ß", "ss", "æ", "ae", "œ", "oe", "Æ", "AE", "Œ", "OE", "Ð", "D", "ð", "d", "þ", "th", "Þ", "Th")

    for bad, good in pairs
        s := StrReplace(s, bad, good)

    out := ""
    loop parse s {
        pos := InStr(from, A_LoopField, true)
        out .= pos ? SubStr(to, pos, 1) : A_LoopField
    }
    return out
}
