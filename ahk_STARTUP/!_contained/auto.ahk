:*X:kdd1::
today = %A_Now%
today += 1, Days
FormatTime, formatted, %today%, dd/MM/yy
SendInput %formatted%
return

:*X:kd1d::
today = %A_Now%
today += -1, Days
FormatTime, formatted, %today%, dd/MM/yy
SendInput %formatted%
return


