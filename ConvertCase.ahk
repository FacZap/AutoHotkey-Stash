; Quick Text Formatting/Style Changes and Other Helpful Windows Tools
;    - High-compatibility and unifies keyboard shortcuts b/t programs
;    - Shortcuts for converting selected text to the following:
;    All lower: THIS_is-a_tESt -> this_is-a_test
;    All Upper: THIS_is-a_tESt -> THIS_IS-A_TEST
;    Caps case: ThisIsAnExample -> THIS_IS_AN_EXAMPLE
;               thisIsAnExample -> THIS_IS_AN_EXAMPLE
;    Camel Case: THIS_IS_AN_EXAMPLE -> ThisIsAnExample
;                this_is_an_example -> ThisIsAnExample
;                tHIS_Is_an_ExAmPLE -> ThisIsAnExample.
; 
; Copy-Paste Buffer 
; Use Ctrl+Shift+c to copy into the FIFO buffer (can do multiple times)
; Use Ctrl+Shift+v to paste from the FIFO buffer

#z::Run https://autohotkey.com/docs/AutoHotkey.htm
#a::Run https://www.autohotkey.com/docs/KeyList.htm

; Convert selected text to lower case
;    Ex: THIS_is-a_tESt -> this_is-a_test
; Usage: Windows_Key + Alt + Down Arrow
#!Down::
    Convert_Lower()
RETURN
Convert_Lower()
{
    ; save original contents of clipboard
    Clip_Save:= ClipboardAll

    ; empty clipboard
    Clipboard:= ""

    ; copy highlighted text to clipboard
    Send ^c{delete}

    ; convert clipboard to desired case
    StringLower Clipboard, Clipboard

    ; send desired text
    Send %Clipboard%
    Len:= Strlen(Clipboard)

    ; highlight text
    Send +{left %Len%}

    ; restore clipboard
    Clipboard:= Clip_Save
}

; Convert selected text to upper case
;    Ex: THIS_is-a_tESt -> THIS_IS-A_TEST
; Usage: Windows_Key + Alt + Up Arrow
#!Up::
    Convert_Upper()
RETURN
Convert_Upper()
{
    ; save original contents of clipboard
    Clip_Save:= ClipboardAll

    ; empty clipboard
    Clipboard:= ""

    ; copy highlighted text to clipboard
    Send ^c{delete}

    ; convert clipboard to desired case
    StringUpper Clipboard, Clipboard

    ; send desired text
    Send %Clipboard%
    Len:= Strlen(Clipboard)

    ; highlight text
    Send +{left %Len%}

    ; restore clipboard
    Clipboard:= Clip_Save
}

; Convert selected text to inverted case
;    Ex: THIS_is-a_tESt -> this_IS-A_TesT
; Usage: Windows_Key + Alt + I
#!i::
    Convert_Inv()
RETURN
Convert_Inv()
{
    ; save original contents of clipboard
    Clip_Save:= ClipboardAll

    ; empty clipboard
    Clipboard:= ""

    ; copy highlighted text to clipboard
    Send ^c{delete}

    ; clear variable that will hold output string
    Inv_Char_Out:= ""

    ; loop for each character in the clipboard
    Loop % Strlen(Clipboard)
    {
        ; isolate the character
        Inv_Char:= Substr(Clipboard, A_Index, 1)

        ; if upper case
        if Inv_Char is upper
        {
            ; convert to lower case
           Inv_Char_Out:= Inv_Char_Out Chr(Asc(Inv_Char) + 32)
        }
        ; if lower case
        else if Inv_Char is lower
        {
            ; convert to upper case
           Inv_Char_Out:= Inv_Char_Out Chr(Asc(Inv_Char) - 32)
        }
        else
        {
            ; copy character to output var unchanged
           Inv_Char_Out:= Inv_Char_Out Inv_Char
        }
    }
    ; send desired text
    Send %Inv_Char_Out%
    Len:= Strlen(Inv_Char_Out)

    ; highlight desired text
    Send +{left %Len%}

    ; restore original clipboard
    Clipboard:= Clip_Save
}

; Convert selected text from CamelCase to CAPS_CASE
;    Ex: ThisIsAnExample -> THIS_IS_AN_EXAMPLE
; Usage: Windows_Key + Alt + Right Arrow Key
#!Right::
    Convert_cc()
RETURN
Convert_cc()
{
    ; save original contents of clipboard
    Clip_Save:= ClipboardAll

    ; empty clipboard
    Clipboard:= ""

    ; copy highlighted text to clipboard
    Send ^c{delete}

    ; clear variable that will hold output string
    Inv_Char_Out:= ""

    ; loop for each character in the clipboard
    Loop % Strlen(Clipboard)
    {
        ; isolate the character
        Inv_Char:= Substr(Clipboard, A_Index, 1)

        ; if upper case
        if Inv_Char is upper
        {
           if A_Index != 1
           {
               Inv_Char_Out:= Inv_Char_Out Chr(Asc("_"))
           }
           Inv_Char_Out:= Inv_Char_Out Chr(Asc(Inv_Char))
        }
        ; if lower case
        else if Inv_Char is lower
        {
           ; convert to upper case
           Inv_Char_Out:= Inv_Char_Out Chr(Asc(Inv_Char) - 32)
        }
        else
        {
           ; copy character to output var unchanged
           Inv_Char_Out:= Inv_Char_Out Inv_Char
        }
    }
    ; send desired text
    Send %Inv_Char_Out%
    Len:= Strlen(Inv_Char_Out)

    ; highlight desired text
    Send +{left %Len%}

    ; restore original clipboard
    Clipboard:= Clip_Save
}

; Convert selected text from CAPS_CASE to CamelCase
;    Ex: THIS_IS_AN_EXAMPLE -> ThisIsAnExample
; Usage: Windows_Key + Alt + Left Arrow Key
#!Left::
    Convert_underscore_to_cc()
RETURN
Convert_underscore_to_cc()
{
    ; save original contents of clipboard
    Clip_Save:= ClipboardAll

    ; empty clipboard
    Clipboard:= ""

    ; copy highlighted text to clipboard
    Send ^c{delete}

    ; clear variable that will hold output string
    Char_Out:= ""

    ; Find number of _'s in string by replacing with self
    ; and counting how many times we do it with ErrorLevel
    ; Result is in ErrorLevel
    StringReplace Clipboard,Clipboard,_,_,UseErrorLevel

    ; set Index
    Index=1

    ; loop for each character in the clipboard
    Loop % Strlen(Clipboard) - ErrorLevel
    {
        ; isolate the character
        Char:= Substr(Clipboard, Index, 1)
        ; isolate the next character too
        Next_Char:= Substr(Clipboard, Index + 1, 1)

        if Index = 1
        {
            if Char != "_"
            {
                ; convert to upper case
                if Char is lower
                {
                    Char_Out:= Char_Out Chr(Asc(Char) - 32)
                }
                else
                {
                    Char_Out:= Char_Out Char
                }
            }
        }
        else
        {
            ; if _
            if Chr(Asc(Char)) == Chr(Asc("_"))
            {
                if Next_Char != ""
                {
                    ; convert to upper case
                    if Next_Char is lower
                    {
                        Char_Out:= Char_Out Chr(Asc(Next_Char) - 32)
                    }
                    else
                    {
                        Char_Out:= Char_Out Next_Char
                    }
                }
                Index++
            }
            else
            {
                if Char is upper
                {
                    ; convert to lower case
                    Char_Out:= Char_Out Chr(Asc(Char) + 32)
                }
                else
                {
                    Char_Out:= Char_Out Char
                }
            }
        }

        ; increment index
        Index++
    }

    ; send desired text
    Send %Char_Out%
    Len:= Strlen(Char_Out)

    ; highlight desired text
    Send +{left %Len%}

    ; restore original clipboard
    Clipboard:= Clip_Save
}

; Find selected text
;    Ex: Select FindMeInProgram, use this, opens find dialog (if Ctrl-F)
;        and pastes FindMeInProgram
; Usage: Windows_Key + Alt + F
!+f::
Send, ^c
Sleep 100
Send, ^f
Sleep 100
Send, ^v
RETURN

; Open windows identical windows explorer
!+e::
Send, !d
Sleep 50
Send, ^c
Sleep 50
Send, #e
Sleep 300
Send, !d
Sleep 50
Send, ^v
Sleep 50
Send, {enter}
Sleep 50
Send, #{Right}
RETURN

; Copy selected text into a Copy FIFO Buffer (can do multiple times)
^+c::
FileEncoding UTF-8
filename := "C:\Temp\_clipboard_buffer.txt"
Send, ^c
Sleep 50
FileAppend, {{clipboard_buffer_delimiter}}%clipboard%, %filename%
RETURN

; Paste by getting first item from the Copy Buffer (can do multiple times)
; NOTE: Once pasted, you cannot restore that item to the Copy Buffer (e.g. Undo)
; except by re-copying it
^+v::
FileEncoding UTF-8
filename := "C:\Temp\_clipboard_buffer.txt"
clipboard_content := ""
new_file_content := ""
FileRead, file_text, %filename%

copies_array := StrSplit(file_text, "{{clipboard_buffer_delimiter}}")

Loop % copies_array.MaxIndex()
{
    item_content := copies_array[a_index]
    ; first item is empty since we start the items with a delimeter,
    ; so item at index 2 is what we want on the clipboard
    If (a_index == 2)
    {
        clipboard_content := item_content
    }
    ; Keep appending other items to the new file content with delimiter to write back
    Else If (a_index >= 2)
    {
        new_file_content = %new_file_content% {{clipboard_buffer_delimiter}} %item_content%
    }
    Else
    {
        ; Do nothing for first empty items
    }
}
; Rewrite the file with the new content (e.g. last item popped off)
file := FileOpen(filename, "w")
if !IsObject(file)
{
    MsgBox Can't open "%filename%" for reading.
    return
}
file.Write(new_file_content)
file.Close()

; Finally, paste the popped item
clipboard = %clipboard_content%
Send, ^v
Sleep 50

RETURN