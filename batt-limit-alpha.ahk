<^F7::
{
	Process, Exist, Battery Limiter
	if (ErrorLevel = 0)
	{
		Run, C:\Users\fzpat\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Battery Limiter\Battery Limiter,,, PID
	}
	else
	{
		WinClose, ahk_pid %PID%
	}
}