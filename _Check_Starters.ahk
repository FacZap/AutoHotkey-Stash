; status_checker.ahk
; AutoHotkey v1.x

#NoEnv
#SingleInstance Force
SetBatchLines, -1
DetectHiddenWindows, On
SetTitleMatchMode, 2   ; allow partial title matches (for script file names, etc.)

; -------------------------------
; Define the items to check
; -------------------------------
scripts := []

; AHK scripts (detected via their AutoHotkey window title)
scripts.Push({ label: "arrows-keystrokes.ahk"
             , kind:  "ahk"
             , id:    "arrows-keystrokes.ahk" })

scripts.Push({ label: "autodate.ahk"
             , kind:  "ahk"
             , id:    "autodate.ahk" })

scripts.Push({ label: "backwards-slash.ahk"
             , kind:  "ahk"
             , id:    "backwards-slash.ahk" })

scripts.Push({ label: "brightness.ahk"
             , kind:  "ahk"
             , id:    "brightness.ahk" })

scripts.Push({ label: "checkmark.ahk"
             , kind:  "ahk"
             , id:    "checkmark.ahk" })

scripts.Push({ label: "dashes.ahk"
             , kind:  "ahk"
             , id:    "dashes.ahk" })

scripts.Push({ label: "calendar.ahk"
             , kind:  "ahk"
             , id:    "Calendar.ahk" })

scripts.Push({ label: "logger.ahk"
             , kind:  "ahk"
             , id:    "logger.ahk" })

scripts.Push({ label: "move_resize.ahk"
             , kind:  "ahk"
             , id:    "move_resize.ahk" })

scripts.Push({ label: "mute.ahk"
             , kind:  "ahk"
             , id:    "mute.ahk" })

scripts.Push({ label: "pauseplay.ahk"
             , kind:  "ahk"
             , id:    "pauseplay.ahk" })

scripts.Push({ label: "right_tab.ahk"
             , kind:  "ahk"
             , id:    "right_tab.ahk" })

scripts.Push({ label: "selectcellcontent.ahk"
             , kind:  "ahk"
             , id:    "selectcellcontent.ahk" })

scripts.Push({ label: "volume.ahk"
             , kind:  "ahk"
             , id:    "volume.ahk" })

scripts.Push({ label: "macro_insta_name.ahk"
             , kind:  "ahk"
             , id:    "macro_insta_name.ahk" })

scripts.Push({ label: "MacroRecorder.ahk"
             , kind:  "ahk"
             , id:    "MacroRecorder.ahk" })

scripts.Push({ label: "find_wise_reminder.ahk"
             , kind:  "ahk"
             , id:    "find_wise_reminder.ahk" })

scripts.Push({ label: "open_hourglass.ahk"
             , kind:  "ahk"
             , id:    "open_hourglass.ahk" })

scripts.Push({ label: "kill_all.ahk"
             , kind:  "ahk"
             , id:    "kill_all.ahk" })

scripts.Push({ label: "Show_Time.ahk"
             , kind:  "ahk"
             , id:    "Show_Time.ahk" })

scripts.Push({ label: "Cycler_Windows_v3.ahk"
             , kind:  "ahk"
             , id:    "Cycler_Windows_v3.ahk" })

scripts.Push({ label: "url_chrome.ahk"
             , kind:  "ahk"
             , id:    "url_chrome.ahk" })

; RBTray.exe – checked by process name
scripts.Push({ label: "RBTray.exe"
             , kind:  "exe"
             , id:    "RBTray.exe" })


; -------------------------------
; Build GUI
; -------------------------------
Gui, New, +AlwaysOnTop +Resize, Script / Program Status

Gui, Add, Text, xm ym w360 Center, Status of configured scripts/programs:
Gui, Add, ListView, xm+0 ym+20 w500 r20 vLVStatus, Name|Status

for index, item in scripts
{
    status := CheckStatus(item)
    LV_Add("", item.label, status)
}

Gui, Add, Button, xm+200 gCloseGUI, Close

Gui, Show
return


; -------------------------------
; Status check function
; -------------------------------
CheckStatus(item) {
    ; item.kind: "ahk", "exe", "app"
    ; item.id:   identifier (file name, process name, or window text)

    if (item.kind = "ahk") {
        ; AHK scripts: window title normally contains "scriptname.ahk"
        if WinExist(item.id " ahk_class AutoHotkey")
            return "Running"
        if WinExist(item.id)   ; fallback: any window containing the script name
            return "Running"
        return "Not running"
    }
    else if (item.kind = "exe") {
        ; Programs checked by process name
        Process, Exist, % item.id
        return ErrorLevel ? "Running" : "Not running"
    }
    else if (item.kind = "app") {
        ; Generic app checked by window title
        if WinExist(item.id)
            return "Running"
        return "Not running"
    }
    return "Unknown"
}

; -------------------------------
; GUI close handlers
; -------------------------------
CloseGUI:
GuiClose:
ExitApp
