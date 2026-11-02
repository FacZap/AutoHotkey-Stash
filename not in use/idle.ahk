#NoEnv
#SingleInstance Force
#Persistent
Goto, Work


Work:
SetTimer, Check, 1000 ;check every second
return


Check:
If (A_TimeIdlePhysical>=1000*60*3)
{
Send, #d
ToolTip, Escritorio  
SetTimer, Check, off
Sleep, 500
SetTimer, Check2, 500
}
return


Check2:
If (A_TimeIdlePhysical<500)
{
Send, #d
ToolTip
SetTimer, Check2, off
SetTimer, Check, on
}
return