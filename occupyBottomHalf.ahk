^+Down::  ; Ctrl + Shift + Down Arrow
SysGet, MonitorWorkArea, MonitorWorkArea
WinGet, active_id, ID, A
WinMove, ahk_id %active_id%, , MonitorWorkAreaLeft, MonitorWorkAreaBottom // 2, MonitorWorkAreaRight, MonitorWorkAreaBottom // 2
return
