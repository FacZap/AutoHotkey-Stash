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

:*X:knnn::
FormatTime, CurrentDay,, dddd
; SendInput % Format("{:T}",CurrentDay)
SendInput %CurrentDay%
return

:*X:kddd:: 
FormatTime, CurrentDateTime,, dd/MM/yy
SendInput %CurrentDateTime%
return

:*X:kdd1:: ; tomorrow
today = %A_Now%
today += 1, Days
FormatTime, formatted, %today%, dd/MM/yy
SendInput %formatted%
return

:*X:kd1d:: ; yesterday
today = %A_Now%
today += -1, Days
FormatTime, formatted, %today%, dd/MM/yy
SendInput %formatted%
return


:*X:ksss:: ; Simplified
FormatTime, CurrentDateTime,, dd/MM
SendInput %CurrentDateTime%
return 

:*X:skkk:: ; Inverse Simplified
FormatTime, CurrentDateTime,, MM.dd
SendInput %CurrentDateTime%
return 

:*X:kss1:: ; tomorrow's date Simplified
today = %A_Now%
today += +1, days
FormatTime, formatted, %today%, dd/MM
SendInput %formatted%
return

:*X:ks1s:: ; tomorrow's date Simplified
today = %A_Now%
today += -1, days
FormatTime, formatted, %today%, dd/MM
SendInput %formatted%
return

:*X:kxxx::
FormatTime, CurrentDateTime,, yyMMddHHmmss
SendInput %CurrentDateTime%
return

:*X:kzzz::
FormatTime, CurrentDateTime,, yy_MM_dd_HHmm
SendInput %CurrentDateTime%
return

:*X:kaaa::
FormatTime, CurrentDateTime,, yyMMdd
SendInput %CurrentDateTime%
return

:*X:kjjd::
FormatTime, CurrentDateTime,, dd-MM-yy
SendInput %CurrentDateTime%
return

:*X:kjj1::
today = %A_Now%
today += +1, days
FormatTime, formatted, %today%, dd-MM-yy
SendInput %formatted%
return 

:*X:kyyy::
FormatTime, CurrentDateTime,, dd-MM-yy HH:mm
SendInput %CurrentDateTime%
return

:*X:khhh::
FormatTime, CurrentDateTime,, HH:mm
SendInput %CurrentDateTime%
return

:*X:khdx::
FormatTime, CurrentDateTime,, yy-MM-dd_HH-mm
SendInput %CurrentDateTime%
return

:*X:kmmd:: ; MonthDay
FormatTime, CurrentDateTime,, MM.dd
SendInput %CurrentDateTime%
return