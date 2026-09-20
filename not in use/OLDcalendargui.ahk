#Numpad5::
  Gui, Add, MonthCal, vDate
  Gui, Add, Button, Default gButtonOK, OK
  Gui, Show
  Return

ButtonOK:
  Gui, Submit
  Gui, Destroy  ; Close the GUI
  Return

; Add the following lines to close the GUI on ESC or Spacebar press
~Esc::
~Space::
  Gui, Destroy
  Return
