j:: ;key hold time ≈ Count * PressDuration
T := A_TickCount ;only for test
SendMode, Event
SetKeyDelay,, 20 ;PressDuration = 50ms
Loop, 5 ;Count = 5
	Send, {LWin Down}
Send, {LWin Up}
ToolTip,% A_TickCount - T "ms" ;only for test
Return

