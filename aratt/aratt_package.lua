--[[
@description
	ARATT (Automatic Routing And Track Types)
@author
	slsenseless
@license
	GNU GPLv3
@version
	1.4
@links
	GitHub (Source code) https://github.com/slsenseless/ReaScripts
@metapackage
@provides
	[nomain] rtconfig.txt
	[nomain] aratt_toolbar_1.ReaperMenu
	[nomain] aratt_toolbar_2.ReaperMenu
	[nomain] aratt_package.lua
	[nomain] aratt_core.lua
	[nomain] aratt_template.lua
	[main=main] aratt_Automatic*.lua
	[main=main] aratt_Create*.lua
	[main=main] aratt_Transform*.lua
	[main=main,midi_editor,midi_inlineeditor] aratt_Show*.lua
	[main=main] aratt_Remove*.lua
	[main=main] aratt_Assisted*.lua
	[main=midi_editor,midi_inlineeditor] aratt_midi_*.lua
@changelog
	# Version 1.4
		- Add Fx type ("aratt_Create Fx Track.lua" / "aratt_Transform to Fx.lua")
		- Change envelope knob (longer one)
		- Fix midi show Fx (midi/audio/vsti)
		- Remove static routing
		- Refractoring of routing process
	# Version 1.3
		- Add "aratt_midi_Show FX of Midi" midi script
		- Add "aratt_midi_Show input FX of Midi" midi script
		- Add "aratt_midi_Show FX of Audio" midi script
		- Add "aratt_midi_Show FX of Vsti" midi script
		- Add "aratt_Show FX of receives" script
		- Add "aratt_Show FX of sends" script
		- Add "aratt_Show input FX of sends" script
		- Add aratt_toolbar reaper menu
	# Version 1.2
		- Add fx parameter (types can now be loaded with FXs)
		- Add template parameter (types can now be a track template)
		- Add midi input parameter
		- Add height parameter
		- Add "Remove Suffix" script
		- Add "Assisted routing" script
		- Improve folder tcp layout
		- Fix show/hide track state when creating/transforming tracks (audio and midi)
		- Various small fix
		- Code refactoring
	# Version 1.1
		- Implement icons
		- New auto routing script aratt_Automatic Routing static.lua with static routing enable
		- Increase height of tracks (midi,audio,vsti and folder) in TCP
		- Add return code to AutomaticRouting function
	# Version 1.0
		- Add track types
			- Audio Out
			- VSTi
			- Folder
			- MIDI
		- Add automatic routing
		- Add scripts to create, transform and route tracks
		- Add script to show/hide audio in TCP
		- Add script to show/hide midi in MCP
@about
	# ARATT 
	## What is it ?
	Aratt (Automatic Routing And Track Types) is a package for Reaper which adds track types via template and facilitated routing between tracks.
	## How to install it ?
	You can download scripts via reapack.
	To complete the installation, you will need to customize the default theme :
	- Go to your reaper ressource path (Options -> Show REAPER resource path in explorer/finder) in the ColorThemes folder.
	- Make a copy of Default_6.0.ReaperThemeZip
	- Rename the copy Default_6.0_ARATT.ReaperThemeZip
	- Open it with a file archiver
	- Go to Default_6.0_unpacked
	- Paste the rtconfig.txt (from aratt installation folder) in it
	- Change your theme to Default_6.0_ARATT
--]]