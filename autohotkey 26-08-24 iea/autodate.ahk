:R*?:kddd::
FormatTime, CurrentDateTime,, dd/MM/yy
SendInput %CurrentDateTime%
return
:R*?:ksss::
FormatTime, CurrentDateTime,, dd/MM
SendInput %CurrentDateTime%
return
:R*?:knnn::
FormatTime, CurrentDay, , dddd
SendInput %CurrentDay%
return
:R*?:kxxx::
FormatTime, CurrentDateTime,, yyMMddHHmm
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
:R*?:kyyy::
FormatTime, CurrentDateTime,, dd-MM-yy HH:mm
SendInput %CurrentDateTime%
return
:R*?:khhh::
FormatTime, CurrentDateTime,, HH:mm
SendInput %CurrentDateTime%
return