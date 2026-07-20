#Warn All, Off
#ErrorStdOut

^!Left::Send   {Media_Prev}
^!a::Send   {Media_Play_Pause}
^!Right::Send  {Media_Next}
^!.::Send {>}
^!,::Send {<}
^>NumpadDot:: Send {,}
RAlt & Numpad2::Send {Volume_Down}
RAlt & Numpad8::Send {Volume_Up}
RAlt & Numpad3::Send {Volume_Mute}
RAlt & Numpad4::Send {Media_Prev}
RAlt & Numpad6::Send {Media_Next}
RAlt & Numpad5::Send {Media_Play_Pause}
;^!Numpad2::Send {Volume_Down}
;^!Numpad3::Send {Volume_Mute}
;^!Numpad8::Send {Volume_Up}
^!W::Send {Up}
^!S::Send {Down}
^NumpadSub::Send {–}
!NumpadSub::Send {—}
RAlt & {::WinMaximize, A ; Alt + {
RAlt & -::WinMinimize, A ; Alt + -
LWin & WheelUp::send {Volume_Up}
LWin & WheelDown::send {Volume_Down}
;!^F10::Send  ✔✔✔
;Arrows
;!Up::Send {Text}↑
;!Down::SendText "↓"
;!Left::SendText "←"
;!Right::SendText "→"

; AutoHotkey v2 script to send "\" when pressing ; Shift + NumpadDiv (Numpad / key)

; Hotkey definition for Shift + NumpadDiv
+NumpadDiv:: 
{
    Send \
}
return

RCtrl & Numpad5::
Send {Tab}
return

;  ----------------------

; Run Line Matlab
!F9::
    SendInput {End}
    Sleep 50
    ; Select line content
    SendInput +{Home}
    Sleep 50
    SendInput {F9}
Return

;  ----------------------

; Autoname
::kfz::Facundo Zapata
::kzf::zapatafacundo17@gmail.com
::kmail2::facundozapeters@gmail.com
::khmail::FZ.pata99@hotmail.com
::khcds::facundozapata99@hotmail.com
::kleg::Z-1131/2
::kcel::5493413782465
::kdni::41655777
::keugeleg::G-5371/6
:R*?:k6ini::<
:R*?:k6fin::>

::kuser::%userprofile%
::kapp::%appdata%

:R*?:knnn::
FormatTime, CurrentDay,, dddd
SendInput % Format("{:T}",CurrentDay)
return

:R*?:kddd:: 
FormatTime, CurrentDateTime,, dd/MM/yy
SendInput %CurrentDateTime%
return

::kdd1:: ; tomorrow's date
today = %a_now%
today += +1, days
FormatTime, today, %today%, dd/MM/yy
SendInput %today%
return

::kd1d:: ; yesterday's date
today = %a_now%
today += -1, days
FormatTime, today, %today%, dd/MM/yy
SendInput %today%
return

:R*?:ksss:: ; Simplified
FormatTime, CurrentDateTime,, dd/MM
SendInput %CurrentDateTime%
return 

:R*?:skkk:: ; Inverse Simplified
FormatTime, CurrentDateTime,, MM.dd
SendInput %CurrentDateTime%
return 

::kss1:: ; tomorrow's date Simplified
today = %a_now%
today += +1, days
FormatTime, today, %today%, dd/MM
SendInput %today%
return

::ks1s:: ; tomorrow's date Simplified
today = %a_now%
today += +1, days
FormatTime, today, %today%, dd/MM
SendInput %today%
return

:R*?:kxxx::
FormatTime, CurrentDateTime,, yyMMddHHmmss
SendInput %CurrentDateTime%
return

:R*?:kzzz::
FormatTime, CurrentDateTime,, yy_MM_dd_HHmm
SendInput %CurrentDateTime%
return

:R*?:kaaa::
FormatTime, CurrentDateTime,, yyMMdd
SendInput %CurrentDateTime%
return

:R*?:kjjd::
FormatTime, CurrentDateTime,, dd-MM-yy
SendInput %CurrentDateTime%
return

:R*?:kjj1::
today = %a_now%
today += +1, days
FormatTime, today, %today%, dd-MM-yy
SendInput %today%
return

:R*?:kyyy::
FormatTime, CurrentDateTime,, dd-MM-yy HH:mm
SendInput %CurrentDateTime%
return

:R*?:khhh::
FormatTime, CurrentDateTime,, HH:mm
SendInput %CurrentDateTime%
return

:R*?:khdx::
FormatTime, CurrentDateTime,, yy-MM-dd_HH-mm
SendInput %CurrentDateTime%
return

:R*?:kmmd:: ; MonthDay
FormatTime, CurrentDateTime,, MM.dd
SendInput %CurrentDateTime%
return

;  ----------------------

; Calendar GUI
#Numpad5::
  Gui, Add, MonthCal, vDate
  Gui, Add, Button, Default gButtonOK, OK
  Gui, Show
  Return

ButtonOK:
  Gui, Submit
  Gui, Destroy  ; Close the GUI
  Return

;  ----------------------

; Convert Case
^F2::
	Old := Clipboardall
	Clipboard := ""
	Send, ^c
	ClipWait, 2
	Clipboard := StrReplace(Clipboard, " ", "_")
	Send, ^v
	Clipboard := Old
return

^+F2::
	Old := Clipboardall
	Clipboard := ""
	Send, ^c
	ClipWait, 2
	Clipboard := StrReplace(Clipboard, " ", "-")
	Send, ^v
	Clipboard := Old
return

^F3::                                                                 ; Convert text to upper
 StringUpper Clipboard, Clipboard
 Send %Clipboard%
RETURN

^+F3::                                                                 ; Convert text to lower
 StringLower Clipboard, Clipboard
 Send %Clipboard%
RETURN

^F4::                                                                ; Convert text to capitalized
 StringUpper Clipboard, Clipboard, T
 Send %Clipboard%
RETURN

^+F4::                                                                 ; Convert text to inverted
 Lab_Invert_Char_Out:= ""
 Loop % Strlen(Clipboard) {
    Lab_Invert_Char:= Substr(Clipboard, A_Index, 1)
    if Lab_Invert_Char is upper
       Lab_Invert_Char_Out:= Lab_Invert_Char_Out Chr(Asc(Lab_Invert_Char) + 32)
    else if Lab_Invert_Char is lower
       Lab_Invert_Char_Out:= Lab_Invert_Char_Out Chr(Asc(Lab_Invert_Char) - 32)
    else
       Lab_Invert_Char_Out:= Lab_Invert_Char_Out Lab_Invert_Char
 }
 Send %Lab_Invert_Char_Out%
RETURN

;  ----------------------

; Find_Wise_Reminder
#|::
Process, Exist, WiseReminder.exe
If (Errorlevel != 0) ; is running
{
    WinGet, WinState, MinMax, ahk_exe WiseReminder.exe
    If (WinState = "") { ; is minimized to tray
        	SendInput #b
		SendInput {Enter}
		Sleep 50
		SendInput {Up}
		SendInput w
		Sleep 60
		SendInput {Enter}
	} ; Win+b activates the tray, w marks the icon of WiseReminder
    Else
        WinActivate, ahk_exe WiseReminder.exe
}
else  ; is NOT running
    Run, "C:\Program Files (x86)\Wise\Wise Reminder\WiseReminder.exe"
return

;  ----------------------

; Fix PDF Links
^!d::  ; Ctrl+Alt+d hotkey as needed
    ; Activate Alt+D
    SendInput !d
    Sleep 50  ; Short pause for system response

    SendInput {Home}
    Sleep 50
    
    Send ^{Right}
    Sleep 10  
    Send ^{Right}
    Sleep 10
    Send ^{Right}

    SendInput +{End}
    Sleep 50

    SendInput ^c
    Sleep 10
    
    SendInput ^a
    SendInput ^v
    SendInput {Enter}
Return

;  ----------------------

; Left Enter and Volume Master control
^CapsLock::

Send {Enter}
Return

^+CapsLock::

Send {Tab}
Send {Tab}
Send {Tab}
Send {Tab}
Sleep 100
Send {Enter}
Return

;  ----------------------

; Macro Insta
^!x::  ; Ctrl+Alt+x hotkey as needed
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

;  ----------------------

; Find Hourglass
#+|::
Process, Exist, Hourglass.exe
If (Errorlevel != 0) ; is running
{
        WinActivate, ahk_exe Hourglass.exe
}
else  ; is NOT running
    Run, "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Hourglass\Hourglass.lnk"
return

; -------------------------

;Kill All
#Persistent

^+!k:: ; Ctrl + Shift + Alt + K to trigger
WinGet, idList, List
Loop, % idList {
    this_id := idList%A_Index%

    ; Get window properties
    WinGetTitle, title, ahk_id %this_id%
    WinGetClass, class, ahk_id %this_id%
    WinGet, exe, ProcessName, ahk_id %this_id%
    WinGet, style, Style, ahk_id %this_id%

    ; Skip desktop-related classes
    if (class = "Progman" or class = "WorkerW")
        continue

    ; Skip known browsers
    if (exe = "chrome.exe" or exe = "msedge.exe" or exe = "firefox.exe")
        continue

    ; Skip if window has no title (likely background or system)
    if (title = "")
        continue

    ; Only close visible windows
    if (style & 0x10000000) {
        WinClose, ahk_id %this_id%
        Sleep, 100
    }
}
return

; ---------------------

#F3::
Run, "C:\Users\fzpat\Desktop\ahk\Macro.Recorder.exe"
return

