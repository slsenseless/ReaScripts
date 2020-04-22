--[[
@description
	CC/Envelope Connector
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
	[nomain] ccec_core.lua
	[nomain] ccec.rpl
	[main=main] ccec_Update*.lua
	[main=main] ccec_Add*.lua
	[main=main] ccec_EnableDisable*.lua
	[main=midi_editor] ccec_midi*.lua
@changelog
	# Version 1.0
		- Can update Midi CC from envelope
		- Can update/create envelope from Midi CC
		- Can Enable/Disable envelopes related to CC
		- Can link last touched param with selected CC points
		- Can add CC envelope on selected track and learn same CC on last touched param
@about
	CC/Envelope Connector (CCEC) allows to easily synchronize midi CC with envelope by re-creating points along with their shapes. It can also be used to connect last touched param with midi CC or with a different track (tracks must be midi connected). To do all that, it automatically create ReaControlMIDI instances with specific presets (cf. installation process).
	Installation :
		- Create a track
		- Add ReaControlMIDI fx
		- Click "+", "Import preset library"
		- Import file "ccec.rpl"
--]]