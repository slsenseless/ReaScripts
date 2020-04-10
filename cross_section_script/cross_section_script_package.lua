--[[
@description
	Make cross section script
@author
	slsenseless
@license
	GNU GPLv3
@version
	1.0
@links
	GitHub (Source code) https://github.com/slsenseless/ReaScripts
@metapackage
@provides
	[main=main] Make*.lua
@changelog
	# Version 1.0
		- Make cross section script
@about
	This script generate custom action that can be run in any section. Your custom action can contains commands from main and midi section.
	First input tells you in which section your script will be visible ( default is "11111" : visible in every section. 1 is for visible, 0 is for non visible. The order is : Main,Media explorer,Midi editor, Midi event list, Midi inline. Example : "10100" makes your script visible only in main and midi editor sections)
	Second input is the name of the script (without ".lua" at the end)
	Third input is commands ID that will be run by order of appearance. Add a comma "," between two commands.
	For commands in the main section, add "main," before commands ID. ("main," is optional at the begining)
	For commands in the midi editor section, add "midi," before commands ID. (NOT optional)
	Example of valid inputs:
		- [COMMAND_ID_MAIN_1],[COMMAND_ID_MAIN_2],[COMMAND_ID_MAIN_3]
		- midi,[COMMAND_ID_MIDI_1]
		- midi,[COMMAND_ID_MIDI_1],[COMMAND_ID_MIDI_2],main,[COMMAND_ID_MAIN_1],[COMMAND_ID_MAIN_2],midi,[COMMAND_ID_MIDI_3]
	Note : When a midi editor command is put, a midi editor should be open when running your generated script.
--]]