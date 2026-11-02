j:: ;key hold time ≈ Count * PressDuration
T := A_TickCount ;only for test
SendMode, Event
SetKeyDelay,, 20 ;PressDuration = 20ms
Loop, 5 ;Count = 5
	Send, {1 Down}
Send, {1 Up}
ToolTip,% A_TickCount - T "ms" ;only for test
Return

