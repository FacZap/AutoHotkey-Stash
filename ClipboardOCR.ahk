#Requires AutoHotkey v2.0
#SingleInstance Force
; ============================================================================
; ClipboardOCR.ahk  —  OCR the image currently in the clipboard and show the
;                      recognized text in an editable GUI.
;
; Ctrl+Alt+O   OCR the clipboard image
;
; GUI buttons: Copy text / Save .txt / Save image / Discard.
; Both save buttons write to the Windows Downloads folder.
;
; Requires OCR.ahk (Descolada's wrapper around the Windows.Media.Ocr UWP API).
; ============================================================================

#Include OCR.ahk

global OcrGui := "", OcrEdit := "", OcrStatus := ""
global OcrBitmap := 0          ; GDI+ bitmap of the captured image
global OcrGdipToken := 0

^!o::RunClipboardOcr()

RunClipboardOcr() {
    global OcrBitmap

    hBitmap := GetClipboardHBitmap()
    if !hBitmap {
        Flash("No image in the clipboard.")
        return
    }

    Flash("Reading text...")
    try
        text := OCR.FromBitmap(hBitmap).Text
    catch as e {
        DllCall("DeleteObject", "ptr", hBitmap)
        Flash("OCR failed: " e.Message)
        return
    }

    ReleaseOcrBitmap()
    OcrBitmap := HBitmapToGdipBitmap(hBitmap)
    DllCall("DeleteObject", "ptr", hBitmap)

    ToolTip()
    ShowOcrGui(text)
}

; ============================================================================
; Clipboard
; ============================================================================

; Returns a GDI bitmap handle owned by us, or 0 when the clipboard holds no image.
; CF_BITMAP is synthesized by Windows from CF_DIB, so this covers both.
GetClipboardHBitmap() {
    static CF_BITMAP := 2

    if !DllCall("IsClipboardFormatAvailable", "uint", CF_BITMAP)
        return 0

    ; Another process may hold the clipboard open for a moment after copying.
    opened := false
    loop 10 {
        if DllCall("OpenClipboard", "ptr", 0) {
            opened := true
            break
        }
        Sleep 30
    }
    if !opened
        return 0

    hClip := DllCall("GetClipboardData", "uint", CF_BITMAP, "ptr")
    hOwn := hClip ? DllCall("CopyImage", "ptr", hClip, "uint", 0, "int", 0, "int", 0, "uint", 0, "ptr") : 0
    DllCall("CloseClipboard")

    return hOwn
}

; ============================================================================
; GUI
; ============================================================================

ShowOcrGui(text) {
    global OcrGui, OcrEdit, OcrStatus

    if OcrGui
        OcrGui.Destroy()

    OcrGui := Gui("+AlwaysOnTop +Resize", "Clipboard OCR")
    OcrGui.SetFont("s10", "Segoe UI")
    OcrGui.MarginX := 12, OcrGui.MarginY := 12

    OcrEdit := OcrGui.AddEdit("w620 h340 Multi WantReturn VScroll HScroll", text)

    copyBtn := OcrGui.AddButton("xm y+12 w120 Default", "Copy text")
    txtBtn := OcrGui.AddButton("x+8 yp w120", "Save .txt")
    imgBtn := OcrGui.AddButton("x+8 yp w120", "Save image")
    discardBtn := OcrGui.AddButton("x+8 yp w120", "Discard")

    OcrStatus := OcrGui.AddText("xm y+10 w620", text = "" ? "No text recognized." : "")

    copyBtn.OnEvent("Click", (*) => CopyOcrText())
    txtBtn.OnEvent("Click", (*) => SaveOcrText())
    imgBtn.OnEvent("Click", (*) => SaveOcrImage())
    discardBtn.OnEvent("Click", (*) => CloseOcrGui())
    OcrGui.OnEvent("Close", (*) => CloseOcrGui())
    OcrGui.OnEvent("Escape", (*) => CloseOcrGui())
    OcrGui.OnEvent("Size", ResizeOcrGui)

    OcrGui.Show()
    OcrEdit.Focus()
    ; Focusing an Edit selects all of its text, so any keystroke still in flight
    ; from the hotkey would replace the whole result.
    PostMessage 0xB1, 0, 0, OcrEdit   ; EM_SETSEL -> caret at start, nothing selected
}

ResizeOcrGui(g, minMax, w, h) {
    global OcrEdit, OcrStatus
    if minMax = -1
        return
    OcrEdit.Move(, , w - 24, h - 110)
    OcrStatus.Move(, h - 34, w - 24)
}

CloseOcrGui() {
    global OcrGui
    if OcrGui
        OcrGui.Destroy()
    OcrGui := ""
    ReleaseOcrBitmap()
}

CopyOcrText() {
    global OcrEdit
    A_Clipboard := OcrEdit.Value
    SetOcrStatus("Copied to clipboard.")
}

SaveOcrText() {
    global OcrEdit
    file := DownloadsPath("OCR_" FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss") ".txt")
    try
        FileAppend OcrEdit.Value, file, "UTF-8"
    catch as e {
        SetOcrStatus("Could not save: " e.Message)
        return
    }
    SetOcrStatus("Saved " file)
    RevealInExplorer(file)
}

SaveOcrImage() {
    global OcrBitmap
    if !OcrBitmap {
        SetOcrStatus("No image to save.")
        return
    }
    file := DownloadsPath("OCR_" FormatTime(A_Now, "yyyy-MM-dd_HH-mm-ss") ".png")
    try
        ok := SaveGdipBitmapAsPng(OcrBitmap, file)
    catch as e {
        SetOcrStatus("Could not save the image: " e.Message)
        return
    }
    if !ok {
        SetOcrStatus("Could not save the image.")
        return
    }
    SetOcrStatus("Saved " file)
    RevealInExplorer(file)
}

; Opens the containing folder with the saved file selected.
RevealInExplorer(file) {
    try
        Run 'explorer.exe /select,"' file '"'
    catch
        SetOcrStatus("Saved " file " (could not open Explorer)")
}

SetOcrStatus(msg) {
    global OcrStatus
    if OcrStatus
        OcrStatus.Value := msg
}

; ============================================================================
; Files
; ============================================================================

DownloadsPath(name) {
    dir := GetDownloadsDir()
    base := RegExReplace(name, "\.[^.]+$")
    ext := RegExReplace(name, "^.*(\.[^.]+)$", "$1")
    file := dir "\" name
    i := 1
    while FileExist(file)
        file := dir "\" base " (" i++ ")" ext
    return file
}

GetDownloadsDir() {
    static FOLDERID_Downloads := "{374DE290-123F-4565-9164-39C4925E467B}"
    guid := Buffer(16, 0)
    if !DllCall("ole32\CLSIDFromString", "wstr", FOLDERID_Downloads, "ptr", guid)
        && !DllCall("shell32\SHGetKnownFolderPath", "ptr", guid, "uint", 0, "ptr", 0, "ptr*", &pPath := 0) {
        dir := StrGet(pPath, "UTF-16")
        DllCall("ole32\CoTaskMemFree", "ptr", pPath)
        if DirExist(dir)
            return dir
    }
    return EnvGet("USERPROFILE") "\Downloads"
}

; ============================================================================
; GDI+
; ============================================================================

StartGdip() {
    global OcrGdipToken
    if OcrGdipToken
        return true
    DllCall("LoadLibrary", "str", "gdiplus")
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("uint", 1, si)
    DllCall("gdiplus\GdiplusStartup", "ptr*", &token := 0, "ptr", si, "ptr", 0)
    OcrGdipToken := token
    return token != 0
}

HBitmapToGdipBitmap(hBitmap) {
    if !StartGdip()
        return 0
    DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hBitmap, "ptr", 0, "ptr*", &pBitmap := 0)
    return pBitmap
}

SaveGdipBitmapAsPng(pBitmap, file) {
    static PngEncoder := "{557CF406-1A04-11D3-9A73-0000F81EF32E}"
    clsid := Buffer(16, 0)
    if DllCall("ole32\CLSIDFromString", "wstr", PngEncoder, "ptr", clsid)
        return false
    return !DllCall("gdiplus\GdipSaveImageToFile", "ptr", pBitmap, "wstr", file, "ptr", clsid, "ptr", 0)
}

ReleaseOcrBitmap() {
    global OcrBitmap
    if OcrBitmap
        DllCall("gdiplus\GdipDisposeImage", "ptr", OcrBitmap)
    OcrBitmap := 0
}

; ============================================================================
; Misc
; ============================================================================

Flash(msg, ms := 1500) {
    ToolTip msg
    SetTimer () => ToolTip(), -ms
}
