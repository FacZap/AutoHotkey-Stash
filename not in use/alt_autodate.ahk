FormatTime, TimeString
MsgBox %TimeString%

:R*?:kddw1::
FormatTime, Today,, dd-MM-yyyy
Today := Today - 1 ; Decrement today's date by 1 day
FormatTime, UpdatedDate, %Today%, WDay ; Format the updated date
SendInput %UpdatedDate% ; Send the updated date
return

:R*?:kddw2::
FormatTime, CurrentDateTime,, YDay
SendInput %CurrentDateTime%
return

:R*?:kddw3::
FormatTime, CurrentDateTime,, YWeek
SendInput %CurrentDateTime%
return

:R*?:kddw4::
FormatTime, CurrentDateTime,, YearMonth
SendInput %CurrentDateTime%
return