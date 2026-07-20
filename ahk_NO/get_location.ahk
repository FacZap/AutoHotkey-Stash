GroupAdd,ExplorerGroup, ahk_class CabinetWClass
GroupAdd,ExplorerGroup, ahk_class ExploreWClass

#IfWinActive ahk_group ExplorerGroup
^F7::
  fld := ActiveFolderPath()
  MsgBox, 4160, , Current Folder or Location is: %fld%
return

;------------- Explorer Path Functions  ------------

; use #IfWinActive ahk_group ExplorerGroup
; to make sure the active window is an
; Explorer window before calling this function
;
ActiveFolderPath()
{
   return PathCreateFromURL( ExplorerPath(WinExist("A")) )
}

; slightly modified version of function by jethrow
; on AHK forums.
;
ExplorerPath(_hwnd)
{
   for Item in ComObjCreate("Shell.Application").Windows
      if (Item.hwnd = _hwnd)
         return, Item.LocationURL
}

; function by SKAN on AHK forums
;
PathCreateFromURL( URL )
{
 VarSetCapacity( fPath, Sz := 2084, 0 )
 DllCall( "shlwapi\PathCreateFromUrl" ( A_IsUnicode ? "W" : "A" )
         , Str,URL, Str,fPath, UIntP,Sz, UInt,0 )
 return fPath
}