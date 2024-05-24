global lastChecked 												;lastChecked 		target menu item
global currentlyChecked 										;currentlyChecked 	target menu item
global listBoxChoice = 1										;listBoxChoice 		selected list box item                     - Default 1(first item)
global targetExists = 0											;targetExists		Boolean for target menu 				   - Default 0(False)
global doubleClickedLast = 0									;doubleClickedLast  Boolean for double clicking list box items - Default 0(False)
global autoClearChecked = 0										;autoClear  		Boolean for Settings Menu - Default 0(False)
global autoEnterChecked = 0										;autoEnter		    Boolean for Settings Menu - Default 0(False)
global autoMaxChecked = 0										;autoMaximize	    Boolean for Settings Menu - Default 0(False)
global cafinated = 0								

;Startup - targeted environment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Initialize GUI
Menu, SettingsMenu, Add, AutoEnter, settingsToggle
Menu, SettingsMenu, Add, AutoClearScreen, settingsToggle
Menu, SettingsMenu, Add, AutoMaximizeScreen, settingsToggle
Menu, SettingsMenu, Add, Refresh Target, refreshHanlder
Menu, MyMenuBar, Add, &Settings, :SettingsMenu
Menu, MyMenuBar, Add, Tray Menu, :TRAY
Gui, Menu, MyMenuBar

dynamicWindowSetup()

Gui, Add, ListBox, h600 w400 vscriptData gListBox				;Add listbox named scirptData and include gListBox properties
Gui, +AlwaysOnTop												;Set window to always be on top
Gui, Show														;Show the window
Return
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;										Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Get a list of all open windows, add PCOMM windows to ArrayWindow, increment ArrayWindowCount
; and dynamically create a menu based on the open windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dynamicWindowSetup(){
	WinGet, windows, list,,, Program Manager					;Get a list of all open windows
	Loop, %windows%												;Loop through list of windows
	{	
		id := windows%A_Index%
		WinGetClass, wc, ahk_id %id%
		WinGetTitle wt, ahk_id %id%
		IfInString, wc, PCSWS									;Add PCOMM windows to ArrayWindow
		{
			ArrayWindowCount += 1
			ArrayWindow%ArrayWindowCount% := wt		
		}
		IfInString, wc, SunAwtFrame								;Add PCOMM windows to ArrayWindow
		{
			ArrayWindowCount += 1
			ArrayWindow%ArrayWindowCount% := wt	
		}
	}
	;Menu Bar -- Dynamically create a menu based on the open windows
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;;;;;;
	If targetExists { 												;Check that the target menu exists
		Menu, Target, Delete										;Remove the target menu
		targetExists = 0											;Set target menu to 0(False)
	}
	Loop %ArrayWindowCount%											;Loop to add windows to target menu
	{
		Menu, Target, Add, % ArrayWindow%A_Index%, toggle			;Add indexed window to target menu
		if(ArrayWindowCount = A_Index)								;If this is the last array item
		{
				Menu, Target, ToggleCheck, % ArrayWindow%A_Index%	;Add last array item to target menu
				lastChecked = % ArrayWindow%A_Index%				;Set checked menu item as lastChecked(Since it is the first time an item has been checked)
				currentlyChecked = % ArrayWindow%A_Index%			;Set currentlyChecked as checked target menu
		}
	}

	if (ArrayWindowCount > 0)										;If at least one window was found
	{		
		Menu, MyMenuBar, Add, &Target, :Target						;Add Target Menu 
		targetExists = 1											;Set targetExists to 1(True)
	} else {
		currentlyChecked = "No Windows Open"						;Display a message to let the user know there are no supported windows open
	}	
	return
}

;Setup Toggle check for the Target menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Toggle:
currentlyChecked = %A_ThisMenuItem%

if(lastChecked != currentlyChecked)
{
	Menu, Target, ToggleCheck, %lastChecked%				;Uncheck Previous Target
	Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%		;Check New Target
	lastChecked = %A_ThisMenuItem%							;Set New Target as previous target
} 
return

;Setup Toggle for the Settings menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
settingsToggle:
Menu, %A_ThisMenu%, ToggleCheck, %A_ThisMenuItem%

If InStr(A_ThisMenuItem, "AutoEnter")
{	
	if(autoEnterChecked == 0){
		autoEnterChecked = 1
	}
	else{ 
		autoEnterChecked = 0
	}
}

If InStr(A_ThisMenuItem, "AutoClear")
{	
	if(autoClearChecked == 0){
		autoClearChecked = 1
	}
	else{ 
		autoClearChecked = 0		
	}
}

If InStr(A_ThisMenuItem, "AutoMax")
{	
	if(autoMaxChecked == 0){
		autoMaxChecked = 1
	}
	else{ 
		autoMaxChecked = 0		
	}
}
return

;Setup refresh target for the Settings menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
refreshHanlder: 
dynamicWindowSetup()
return

;Setup drag and drop
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GuiDropFiles:
GuiControl,, scriptData, |
GuiControl, -Redraw, scriptData								;;Redraws the listbox to increase performance
Loop, read, %A_GuiEvent%									;;Reads dragged/droped file to listbox
{
    Loop, parse, A_LoopReadLine, %A_Tab%
    {
		GuiControl, , scriptData, %A_LoopField%
    }
}
GuiControl, +Redraw, scriptData								
listBoxChoice = 1											;;Resets listBoxChoice to 1 when script is loaded.
GuiControl, Choose, scriptData, %listBoxChoice%				;;Select the first item in the listbox
doubleClickedLast = 0										;;Set doubleClickedLast to false
Return

;Setup List Box Double Click to send to window
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ListBox:
If(A_GuiEvent = "DoubleClick"){	
	Gui Submit, Nohide										;;Save content of each control to its associated variable
	listBoxChoice = %A_EventInfo%							;;Sets the currently selected listbox item
	sendToWindow()											;;Checks that window exists and sends listbox data to window
	doubleClickedLast = 1   								;;Shows that the last entry was made via Double Clicking
}
Return

;;Select the next listbox entry and send to target
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
]::
	if doubleClickedLast {									;;Check if last item was entered via double click
		listBoxChoice++										;;Increment past last doubleClicked item
		doubleClickedLast = 0								;;Set doubleClickedLast to false
	}
	GuiControl, Choose, scriptData, %listBoxChoice%			;;Select the current listbox item
	Gui Submit, Nohide										;;Save content of each control to its associated variable
	sendToWindow()											
	listBoxChoice++ 										;;Increment to next listbox item	
	GuiControl, Choose, scriptData, %listBoxChoice%			;;Select the next listbox item
	Gui Submit, Nohide										;;Update display to next entry
	Return

;Logic to check window exists and send entries from the listbox
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
sendToWindow(){
	global
	IfWinExist %currentlyChecked%
	{
		WinActivate
		if(autoMaxChecked)
			WinMaximize										  ;;Maximizes Target Screen
		if(autoClearChecked)
			Send {Pause}									  ;Clears the Screen 
		Send %scriptData%									  ;;Sends selected listbox item to target window
		if(autoEnterChecked)
			Send {ENTER}									  ;;Auto Enter the entry sent
	}
	else 
	{
		MsgBox %currentlyChecked% " is no longer open"		;;TODO: Update to set to scan open windows and select one or return message if none exist
	}
	Return
}

;Coffee
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
coffee(){
	if caffinated
	{		
		caffinated = 1
		MsgBox Decaffinate
	}
	else{		
		caffinated = 0
		MsgBox Caffinate
	}
	; While caffinated{
	; 	Random, rand, 30000, 60000
	; 	SLEEP rand
	; 	MouseClick, WheelDown,,, 2
	; }
}


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;						Short cuts and Cleanup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
F5:: dynamicWindowSetup()

#c:: coffee()

#z::Menu, File, Show	

^!r::Reload

GuiClose:
ExitApp

ESC::ExitApp

ExitRoutine:
ExitApp