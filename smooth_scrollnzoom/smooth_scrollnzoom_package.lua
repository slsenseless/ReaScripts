--[[
@description
	Smooth Scroll'n Zoom
@author
	slsenseless
@license
	GNU GPLv3
@version
	1.1
@links
	GitHub (Source code) https://github.com/slsenseless/ReaScripts
@metapackage
@provides
	[main=main] Arrange*.lua
	[main=midi_editor] Midi*.lua
	[main=midi_editor] sleep.lua
@changelog
	# Version 1.1
		- Update about section
	# Version 1.0
		- Smooth scroll and zoom on arrange view / midi editor.
		- Midi editor zoom should be made with custom actions
@about
	# What is it ?
	
	Smooth Scroll'n Zoom gives you smooth transition when scrolling/zooming even with stepped scroll-wheels.
	
	# How to install it ?
	
	Assign scripts with mousewheel.
	
	To make zoom in midi editor :
	- Open the action window
	- Go to midi editor section
	- Create a new custom action
	- First put a few "Modify MIDI CC/mousewheel 0.5x" or "Modify MIDI CC/mousewheel -10%"
	- Then put a couple of "Zoom horizontally/vertically (MIDI relative/mousewheel)"
	- Finally put "sleep.lua" between each zoom action
	- Example for horizontal zoom : 2*"Modify MIDI CC/mousewheel 0.5x", 8*"Zoom horizontally (MIDI relative/mousewheel)",7*"sleep.lua"
	- Example for vertical zoom : 2*"Modify MIDI CC/mousewheel 0.5x", 4*"Zoom horizontally (MIDI relative/mousewheel)",3*"sleep.lua"
	- Same trick can be applied to scrolling on midi if scrolling scripts perform badly
	
	Note :
	- Midi editor zooming doesn't work when playing :(
	- To improve midi editor scroll/zoom, updating the view configuration (CFGEDITVIEW) via the state chunk of the item/track has already been tried, without success. It seems that CFGEDITVIEW / CFGEDIT both have read-only values.
--]]