
; from https://stackoverflow.com/questions/31865826/right-click-on-tray-icon-in-windows-10-with-autohotkey
#Include %A_Scriptdir%\TrayIcon.ahk
TrayIcon_Button("Docker Desktop.exe", "R")
; TODO sometimes this sleep isn't long enough
Sleep, 1000
Send +{Tab}{Enter}
; RESUME - doesn't work. Clicks above button but either doesn't wait or doesn't find Quit button
;ControlClick, x7 y307, ahk_exe "Docker Desktop.exe"
;ControlClick, x7 y7, ahk_exe "Docker Desktop.exe"
;ControlClick, x50 y878, ahk_exe "Docker Desktop.exe"
; The context menu is 243w 314h
;ControlClick, x3 y311, ahk_pid 51380
;ControlClick, x122 y878, ahk_exe "Docker Desktop.exe"
;ControlClick, x122 y878, ahk_exe "Docker Desktop.exe"

