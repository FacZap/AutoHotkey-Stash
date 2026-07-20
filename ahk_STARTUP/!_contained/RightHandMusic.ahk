#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

RAlt & Numpad2::Send {Volume_Down}
RAlt & Numpad8::Send {Volume_Up}
RAlt & Numpad3::Send {Volume_Mute}
RAlt & Numpad4::Send {Media_Prev}
RAlt & Numpad6::Send {Media_Next}
RAlt & Numpad5::Send {Media_Play_Pause}
^!Numpad2::Send {Volume_Down}
^!Numpad3::Send {Volume_Mute}
^!Numpad8::Send {Volume_Up}