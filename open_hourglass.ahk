#+z::
Process, Exist, Hourglass.exe
If (Errorlevel != 0) ; is running
{
        WinActivate, ahk_exe Hourglass.exe
}
else  ; is NOT running
    Run, "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Hourglass\Hourglass.lnk"
return