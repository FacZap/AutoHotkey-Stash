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
; SendInput % Format("{:T}",CurrentDay)
SendInput %CurrentDay%
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