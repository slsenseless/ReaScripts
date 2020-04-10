-- @noindex
local aratt = {}

aratt.templatePath = reaper.GetResourcePath() .. "/TrackTemplates/"

-- Track types properties
-- /!\ Layout names vsti.panelLayout, audio.panelLayout, midi.panelLayout, folder.panelLayout and defaultPanelLayout MUST be different !
-- /!\ Templates MUST have only one track

aratt.vsti = {
	id = "vsti", -- Don't change this
	name = "VSTi: ",
	panelLayout = "VSTi",
	mixerLayout = "VSTi", -- Put "" for default layout
	icon = "synth.png", -- Put "" for none
	fx = {},
	template = "",
	height = 60 -- 0 for default
}

aratt.audio = {
	id = "audio", -- Don't change this
	name = "Out",
	panelLayout = "Audio",
	mixerLayout = "Audio", -- Put "" for default layout
	icon = "amp_combo.png", -- Put "" for none
	fx = {"ReaEQ (Cockos)","ReaComp (Cockos)"},
	template = "",
	height = 60 -- 0 for default
}

aratt.fx = {
	id = "fx", -- Don't change this
	name = "Fx",
	panelLayout = "Fx",
	mixerLayout = "Fx", -- Put "" for default layout
	icon = "fx.png", -- Put "" for none
	fx = {},
	template = "",
	height = 60 -- 0 for default
}

aratt.folder = {
	id = "folder", -- Don't change this
	name = "",
	panelLayout = "Folder",
	mixerLayout = "Folder", -- Put "" for default layout
	icon = "folder.png", -- Put "" for none
	fx = {}, -- leave it empty
	template = "", -- leave it empty
	height = 60 -- 0 for default
}

aratt.midi = {
	id = "midi", -- Don't change this
	name = "Midi",
	panelLayout = "Midi",
	mixerLayout = "Midi", -- Put "" for default layout
	icon = "midi.png", -- Put "" for none
	fx = {},
	template = "",
	height = 120 -- 0 for default
}

aratt.defaultPanelLayout = "Global layout default"
aratt.defaultMixerLayout = "Global layout default"

-- Suffix
aratt.suffixOnMidi = true -- Put Channel / Bus at the end of midi name
aratt.suffixOnAudio = true -- Put Channel at the end of audio name

-- Show/Hide types in mixer/panel
aratt.showMidiMixer = false
aratt.showAudioPanel = true -- Also for fx tracks

-- Midi configuration
aratt.useBus = false -- True: all 16 buses will be used, False: default bus (0) will be used
aratt.maxNumberBus = 16 -- Number of buses used (if useBus true), maximum is 16
aratt.midiSendChan = 0 -- Midi channel send from Midi track to Vsti (0: All, 1-16: Channel 1-16)
aratt.midiSendBus = 0 -- Midi bus send from Midi track to Vsti (0: All, 1-16: Bus 1-16)

aratt.midiInput = true -- If false, default taken, otherwise midiInputChannel and midiInputDevice taken as record input
if aratt.midiInput then
	aratt.midiInputChannel = 0 -- 0: All, 1-16: Channel 1-16 etc...
	aratt.midiInputDevice = 63 -- 63 : All, 62: VirtualKeyboard, 0-61: MIDI device ID
end

-- Audio configuration
aratt.maxAudioChan = 64
aratt.audioReceive = 0 -- Audio channel on audio track (0: Stereo 1/2, 2: Stereo 3/4...) Do NOT put it above maxAudioChan-2
aratt.audioSend = 0 -- Default audio send for fx tracks

-- Vsti configuration
aratt.vstiSendParent = 0 -- 0 don't send to parent, 1 send

-------------------------------------
-- Get point of tracks insertions
-- @return number Position of last selected track
-------------------------------------
function aratt.GetInsertionPoint()
	local selectionSize = reaper.CountSelectedTracks(0)
	if selectionSize == 0 then
		return reaper.GetNumTracks()
	end

	return reaper.GetMediaTrackInfo_Value(reaper.GetSelectedTrack(0, selectionSize - 1), "IP_TRACKNUMBER")
end

-------------------------------------
-- Create a track
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @param string (optional) name Name of the track
-- @return MediaTrack Created track
-------------------------------------
function aratt.CreateTrack(pos, depth, name)
	if pos == nil then
		pos = aratt.GetInsertionPoint()
	end
	if depth == nil then
		depth = 0
	end
	if name == nil then
		name = ""
	end
	reaper.InsertTrackAtIndex(pos, true)
	local track = reaper.GetTrack(0, pos)
	reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", depth)
	reaper.GetSetMediaTrackInfo_String( track, "P_NAME", name, true )
	return track
end

-------------------------------------
-- Create a track based on a template
-- @param string template Template name
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @param string (optional) name Name of the track
-- @return MediaTrack Created track
-------------------------------------
function aratt.CreateTrackTemplate(template, pos, depth, name)
	if pos == nil then
		pos = aratt.GetInsertionPoint()
	end
	if depth == nil then
		depth = 0
	end
	if name == nil then
		name = ""
	end
	if reaper.CountSelectedTracks(0) == 0 then -- Small bug ?
		pos = pos + 1
	end
	
	reaper.Main_openProject( aratt.templatePath .. template ) -- Automatically select the track
	local track = reaper.GetSelectedTrack( 0, 0 )
	reaper.ReorderSelectedTracks( pos, 0 )
	
	reaper.SetMediaTrackInfo_Value(track, "I_FOLDERDEPTH", depth)
	reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true)
	return track
end

-------------------------------------
-- Tells whether or not an icon should be applied
-- @param MediaTrack track Track to apply icon on
-- @param string iconName Icon name to apply
-- @return boolean True if icon should be changed, false otherwise
-------------------------------------
function aratt.changeIcon(track, iconName)
	local retval, currentIcon = reaper.GetSetMediaTrackInfo_String( track, "P_ICON", "", false )
	currentIcon = string.gsub(currentIcon, ".*/","") -- If type is from template, icon will be full path
	currentIcon = string.gsub(currentIcon, ".*\\","")
	if currentIcon == nil or currentIcon == "" or
		(currentIcon == aratt.midi.icon and aratt.isMidiTrack(track)) or
		(currentIcon == aratt.audio.icon and aratt.isAudioTrack(track)) or
		(currentIcon == aratt.folder.icon and aratt.isFolderTrack(track)) or
		(currentIcon == aratt.fx.icon and aratt.isFxTrack(track)) or
		(currentIcon == aratt.vsti.icon and aratt.isVstiTrack(track))
	then
		return true
	end
	return false
end

-------------------------------------
-- Transform a track to audioTrack
-- @param MediaTrack track to transform
-- @return MediaTrack track transformed
-------------------------------------
function aratt.TransformToAudio(track)
	local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if retName == nil or retName == "" then
		reaper.GetSetMediaTrackInfo_String(track, "P_NAME", aratt.audio.name, true)
	end
	
	if aratt.changeIcon(track,aratt.audio.icon) then
		reaper.GetSetMediaTrackInfo_String( track, "P_ICON", aratt.audio.icon, true )
	end
	
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", aratt.stateAudioShow())
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
	reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.audio.panelLayout, true ) -- Apply audio out layout on panel
	reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.audio.mixerLayout, true ) -- Apply audio out layout on mixer
	local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL")
	if vol == 0 then
		reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1)
	end
	if aratt.audio.height ~= 0 then
		reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", aratt.audio.height)
	end
	reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
	reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", 1)
	return track
end

-------------------------------------
-- Transform a track to fx track
-- @param MediaTrack track to transform
-- @return MediaTrack track transformed
-------------------------------------
function aratt.TransformToFx(track)
	local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if retName == nil or retName == "" then
		reaper.GetSetMediaTrackInfo_String(track, "P_NAME", aratt.fx.name, true)
	end
	
	if aratt.changeIcon(track,aratt.fx.icon) then
		reaper.GetSetMediaTrackInfo_String( track, "P_ICON", aratt.fx.icon, true )
	end
	
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", aratt.stateAudioShow())
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
	reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.fx.panelLayout, true ) -- Apply fx out layout on panel
	reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.fx.mixerLayout, true ) -- Apply fx out layout on mixer
	local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL")
	if vol == 0 then
		reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1)
	end
	if aratt.fx.height ~= 0 then
		reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", aratt.fx.height)
	end
	reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
	reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", 1)
	return track
end

-------------------------------------
-- Create an Audio track
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @param string (optional) name Name of the track
-- @return MediaTrack Created audio track
-------------------------------------
function aratt.CreateAudioTrack(pos, depth, name)
	return aratt.TrackFactory(aratt.audio,pos,depth,name)
end

-------------------------------------
-- Create an Fx track
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @param string (optional) name Name of the track
-- @return MediaTrack Created fx track
-------------------------------------
function aratt.CreateFxTrack(pos, depth, name)
	return aratt.TrackFactory(aratt.fx,pos,depth,name)
end

-------------------------------------
-- Transform a track to Folder
-- @param MediaTrack track to transform
-- @return MediaTrack track transformed
-------------------------------------
function aratt.TransformToFolder(track)
	local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	
	if retName == nil or retName == "" then
		reaper.GetSetMediaTrackInfo_String(track, "P_NAME", aratt.folder.name, true)
	end
	
	if aratt.changeIcon(track,aratt.folder.icon) then
		reaper.GetSetMediaTrackInfo_String( track, "P_ICON", aratt.folder.icon, true )
	end
	
	reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.folder.panelLayout, true ) -- Apply folder layout on panel
	reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.folder.mixerLayout, true ) -- Apply folder layout on mixer
	local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL")
	if vol == 0 then
		reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1)
	end
	if aratt.folder.height ~= 0 then
		reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", aratt.folder.height)
	end
	reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
	reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", 1)
	return track
end

-------------------------------------
-- Create a Folder track
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @param string (optional) name Name of the track
-- @return MediaTrack Created folder track
-------------------------------------
function aratt.CreateFolderTrack(pos, depth, name)
	return aratt.TrackFactory(aratt.folder,pos,depth,name)
end

-------------------------------------
-- Transform a track to Vsti
-- @param MediaTrack track to transform
-- @return MediaTrack track transformed
-------------------------------------
function aratt.TransformToVsti(track)
	local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if retName == nil or retName == "" then
		reaper.GetSetMediaTrackInfo_String(track, "P_NAME", aratt.vsti.name, true)
	end
	
	if aratt.changeIcon(track,aratt.vsti.icon) then
		reaper.GetSetMediaTrackInfo_String( track, "P_ICON", aratt.vsti.icon, true )
	end
	
	reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.vsti.panelLayout, true ) -- Apply vsti layout on panel
	reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.vsti.mixerLayout, true ) -- Apply vsti layout on mixer
	local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL")
	if vol == 0 then
		reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1)
	end
	reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", aratt.vstiSendParent)
	if aratt.vsti.height ~= 0 then
		reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", aratt.vsti.height)
	end
	reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
	return track
end

-------------------------------------
-- Create a Vsti track
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @param string (optional) name Name of the track
-- @return MediaTrack Created Vsti track
-------------------------------------
function aratt.CreateVstiTrack(pos, depth, name)
	return aratt.TrackFactory(aratt.vsti,pos,depth,name)
end

-------------------------------------
-- @param MediaTrack track Vsti Track
-- @return string Name of the vsti
-------------------------------------
function aratt.GetVstiName(track)
	local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	local len_full_name = string.len(retName)
	local len_default_name = string.len(aratt.vsti.name)
	if aratt.isVstiTrack(track) and len_full_name > len_default_name then
		return string.sub(retName,len_default_name+1,len_full_name)
	else
		return ""
	end
end

-------------------------------------
-- Transform a track to midi
-- @param MediaTrack track to transform
-- @return MediaTrack track transformed
-------------------------------------
function aratt.TransformToMidi(track)
	local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if retName == nil or retName == "" then
		reaper.GetSetMediaTrackInfo_String(track, "P_NAME", aratt.midi.name, true)
	end

	if aratt.changeIcon(track,aratt.midi.icon) then
		reaper.GetSetMediaTrackInfo_String( track, "P_ICON", aratt.midi.icon, true )
	end
	
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", aratt.stateMidiShow())
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 1)
	reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.midi.panelLayout, true ) -- Apply midi layout on panel
	reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.midi.mixerLayout, true ) -- Apply midi layout on mixer

	if aratt.midiInput then
		reaper.SetMediaTrackInfo_Value( track, "I_RECINPUT", 4096 + aratt.midiInputDevice*32 + aratt.midiInputChannel )
	end
	if aratt.midi.height ~= 0 then
		reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", aratt.midi.height)
	end
	reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", 0)
	reaper.SetMediaTrackInfo_Value(track, "D_VOL", 0)
	return track
end

-------------------------------------
-- Create a midi track
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @param string (optional) name Name of the track
-- @return MediaTrack Created midi track
-------------------------------------
function aratt.CreateMidiTrack(pos, depth, name)
	return aratt.TrackFactory(aratt.midi,pos,depth,name)
end

-------------------------------------
-- Transform a track to default
-- @param MediaTrack track to transform
-- @return MediaTrack transformed track
-------------------------------------
function aratt.TransformToDefault(track)
	reaper.GetSetMediaTrackInfo_String( track, "P_ICON", "", true )
	reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.defaultPanelLayout, true ) -- Apply default layout on panel
	reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.defaultMixerLayout, true ) -- Apply default layout on mixer
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINPANEL", 1)
	local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL")
	if vol == 0 then
		reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1)
	end
	return track
end

-------------------------------------
-- Create a track based on its type
-- @param {aratt.vsti|aratt.audio|aratt.fx|aratt.midi|aratt.folder} trackType Type of track
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @param string (optional) name Name of the track
-- @return MediaTrack Created track
-------------------------------------
function aratt.TrackFactory(trackType, pos, depth, name)
	if pos == nil then
		pos = aratt.GetInsertionPoint()
	end
	if depth == nil then
		depth = 0
	end
	if name == nil then
		name = trackType.name
	end
	local track = nil
	
	if trackType.template == "" then
		track = aratt.CreateTrack(pos,depth,name)
	else
		track = aratt.CreateTrackTemplate(trackType.template,pos,depth,name)
	end
	
	track = aratt.addFx(track,trackType.fx)
	if trackType.id == aratt.midi.id then track = aratt.TransformToMidi(track)
	elseif trackType.id == aratt.vsti.id then track = aratt.TransformToVsti(track)
	elseif trackType.id == aratt.audio.id then track = aratt.TransformToAudio(track)
	elseif trackType.id == aratt.fx.id then track = aratt.TransformToFx(track)
	elseif trackType.id == aratt.folder.id then track = aratt.TransformToFolder(track)
	end
	
	return track
end

-------------------------------------
-- Add list of Fx to a track
-- @param MediaTrack track Track to add fx
-- @param table{String} fx List of fx to add
-- @return MediaTrack input track
-------------------------------------
function aratt.addFx(track, fx)
	local i=0
	local fxName=""
	for i, fxName in pairs(fx) do
		reaper.TrackFX_AddByName( track, fxName, false, 1 )
	end
	return track
end

-------------------------------------
-- @param MediaTrack track Track to check
-- @return boolean true if track is a midi, false otherwise
-------------------------------------
function aratt.isMidiTrack(track)
	local retval, retLayout = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false)
	return retLayout == aratt.midi.panelLayout
end

-------------------------------------
-- @param MediaTrack track Track to check
-- @return boolean true if track is an audio, false otherwise
-------------------------------------
function aratt.isAudioTrack(track)
	local retval, retLayout = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false)
	return retLayout == aratt.audio.panelLayout
end

-------------------------------------
-- @param MediaTrack track Track to check
-- @return boolean true if track is a fx, false otherwise
-------------------------------------
function aratt.isFxTrack(track)
	local retval, retLayout = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false)
	return retLayout == aratt.fx.panelLayout
end

-------------------------------------
-- @param MediaTrack track Track to check
-- @return boolean true if track is a vsti, false otherwise
-------------------------------------
function aratt.isVstiTrack(track)
	local retval, retLayout = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false)
	return retLayout == aratt.vsti.panelLayout
end

-------------------------------------
-- @param MediaTrack track Track to check
-- @return boolean true if track is a folder, false otherwise
-------------------------------------
function aratt.isFolderTrack(track)
	local retval, retLayout = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false)
	return retLayout == aratt.folder.panelLayout
end

-------------------------------------
-- If an audio track exists, return its show panel, otherwise take default
-- @return number State of audio hide
-------------------------------------
function aratt.stateAudioShow()
	local numTracks = reaper.CountTracks(0)
	local i = 0

	for i=0,numTracks - 1 do
		local track = reaper.GetTrack( 0, i )
		if aratt.isAudioTrack(track) or aratt.isFxTrack(track) then
			return reaper.GetMediaTrackInfo_Value( track, "B_SHOWINTCP" )
		end
	end
	
	if aratt.showAudioPanel then
		return 1
	else
		return 0
	end
end

-------------------------------------
-- If a midi track exists, return its show mixer, otherwise take default
-- @return number State of midi hide
-------------------------------------
function aratt.stateMidiShow()
	local numTracks = reaper.CountTracks(0)
	local i = 0

	for i=0,numTracks - 1 do
		local track = reaper.GetTrack( 0, i )
		if aratt.isMidiTrack(track) then
			return reaper.GetMediaTrackInfo_Value( track, "B_SHOWINMIXER" )
		end
	end
	if aratt.showMidiMixer then
		return 1
	else
		return 0
	end
end

-------------------------------------
-- Get the first free midi channel of track
-- Important note : if a send use all channel, it will be ignored
-- @param MediaTrack track
-- @return number, number Bus number (0 = all) and channel number (0 = all)
-------------------------------------
function aratt.GetUnusedMidi(track)
	local numReceive = reaper.GetTrackNumSends(track, -1)
	local listMidi = {}
	
	-- Store all used midi in list
	local i=0
	local numMidiChan = 16
	for i = 0,numReceive - 1 do
		local bus = 0
		local chan = reaper.BR_GetSetTrackSendInfo(track, -1, i, "I_MIDI_DSTCHAN", false, 0)
		if aratt.useBus then
			bus = reaper.BR_GetSetTrackSendInfo(track, -1, i, "I_MIDI_DSTBUS", false, 0)
			if (chan ~= -1 and bus ~= -1) and (chan ~= 0 or bus ~= 0) then
				if chan == 0 then
					for i=0,numMidiChan - 1 do listMidi[(bus - 1)*numMidiChan+i] = true end
				elseif bus == 0 then
					for i=0,aratt.maxNumberBus - 1 do listMidi[bus*i+(chan - 1)] = true end
				else
					listMidi[(bus - 1)*numMidiChan+(chan - 1)] = true
				end
			end
		elseif chan > 0 then
			listMidi[chan] = true
		end
	end
	
	-- Looking for the first midi channel available
	local maxChan = numMidiChan
	if aratt.useBus then
		maxChan = maxChan * aratt.maxNumberBus
	end
	for i=1,maxChan do
		if listMidi[i] == nil then
			if aratt.useBus then
				return math.floor(i/numMidiChan) + 1, (i%numMidiChan) + 1
			else
				return 0, i
			end
		end
	end
	
	return -1,-1
	
end

-------------------------------------
-- Get corresponding audio channel of a midi
-- @return number Audio channel
-------------------------------------
function aratt.MidiToAudioChannel(bus, chan)
	if bus == -1 and chan == -1 then
		return -1
	end
	if bus == 1 then bus = 0 end
	return (bus * 16) + (chan - 1) * 2
end

-------------------------------------
-- Get the first free stereo audio channel of track
-- @param MediaTrack track
-- @return number Channel number (-1 if all taken)
-------------------------------------
function aratt.GetUnusedAudio(track)
	local numSend = reaper.GetTrackNumSends(track, 0)
	local listAudio = {}
	
	-- Store all used audio in list
	local i=0
	for i=0,numSend - 1 do
		local chan = reaper.BR_GetSetTrackSendInfo(track, 0, i, "I_SRCCHAN", false, 0)
		if chan ~= -1 then
			listAudio[chan] = true
		end
	end
	
	-- Looking for the audio channel available
	for i=0,aratt.maxAudioChan - 2,2 do
		if listAudio[i] == nil then
			return i
		end
	end
	
	return -1
end

-------------------------------------
-- Put string at end of track name
-- @param MediaTrack track Tracks to name
-- @param string suffix Suffix to put
-------------------------------------
function aratt.TrackSuffix(track, suffix)
	local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if suffix == " (0)" then
		suffix = " (All)"
	end
	reaper.GetSetMediaTrackInfo_String(track, "P_NAME", retName..suffix, true)
end

-------------------------------------
-- Add channels to track to receive audio from audioChan
-- @param MediaTrack track
-- @param number audioChan Audio channel to add
-- @return boolean false if no channel available anymore, true otherwise
-------------------------------------
function aratt.AddNeededChan(track, audioChan)
	local currentMaxChannel = reaper.GetMediaTrackInfo_Value( track, "I_NCHAN" )
	while audioChan + 2 > currentMaxChannel and currentMaxChannel < aratt.maxAudioChan - 2 do
		 reaper.SetMediaTrackInfo_Value( track, "I_NCHAN", currentMaxChannel + 2 )
		 currentMaxChannel = reaper.GetMediaTrackInfo_Value( track, "I_NCHAN" )
	end
	if currentMaxChannel == aratt.maxAudioChan then
		return false
	else
		return true
	end
end

-------------------------------------
-- Create midi send between 2 tracks
-- @param MediaTrack trackSrc source
-- @param MediaTrack trackDst destination
-- @param number (optional) dstBus, number (optional) dstChan Destination bus/channel
-- @return number,number,number : bus used, channel used, trackSend
-------------------------------------
function aratt.CreateMidiSend(trackSrc, trackDst, dstBus, dstChan)
	local trackSend = reaper.CreateTrackSend( trackSrc, trackDst )
	if dstBus == nil or dstChan == nil then
		dstBus,dstChan = aratt.GetUnusedMidi(trackDst)
	end
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_SRCCHAN", true, -1)
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_DSTCHAN", true, -1)
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_MIDI_SRCCHAN", true, aratt.midiSendChan )		
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_MIDI_SRCBUS", true, aratt.midiSendBus)
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_MIDI_DSTCHAN", true, dstChan )
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_MIDI_DSTBUS", true, dstBus)
	
	if aratt.suffixOnMidi then
		if dstBus == 0 then
			aratt.TrackSuffix(trackSrc, string.format(" (%d)", dstChan))
		else
			aratt.TrackSuffix(trackSrc, string.format(" (%d/%d)", dstBus, dstChan))
		end
	end
	
	return dstBus, dstChan, trackSend
end

-------------------------------------
-- Create audio send between 2 tracks
-- @param MediaTrack trackSrc source
-- @param MediaTrack trackDst destination
-- @param number (optional) audioChan Audio channel used (0 for 1/2), if nil, next parameter taken
-- @param number (optional) midiBus, number (optional) midiChan Replace audioChan, audio channel will correspond to midi bus/channel
-- Note : if none are provided, next available audio will be taken
-- @return number,number : channel used, trackSend
-------------------------------------
function aratt.CreateAudioSend(trackSrc, trackDst, audioChan, midiBus, midiChan)
	if audioChan == nil then
		if midiBus == nil or midiChan == nil then
			audioChan = aratt.GetUnusedAudio(trackSrc)
		else
			audioChan = aratt.MidiToAudioChannel(midiBus, midiChan)
		end
	end
	aratt.AddNeededChan(trackDst, aratt.audioReceive)
	if not aratt.AddNeededChan(trackSrc, audioChan) then
		audioChan = -1
	end
	local trackSend = reaper.CreateTrackSend( trackSrc, trackDst )
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_SRCCHAN", true, audioChan)
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_DSTCHAN", true, aratt.audioReceive)
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_MIDI_SRCCHAN", true, -1)
	reaper.BR_GetSetTrackSendInfo( trackSrc, 0, trackSend, "I_MIDI_SRCBUS", true, -1)
	
	if aratt.suffixOnAudio then
		aratt.TrackSuffix(trackDst, string.format(" (%d/%d)", audioChan+1, audioChan+2))
	end
	
	return audioChan, trackSend

end

-------------------------------------
-- Return all tracks in their respective table
-- @param table{MediaTrack} tracks Tracks to separate
-- @return table{MediaTrack} vsti tracks, table{MediaTrack} other tracks, table{MediaTrack} audio tracks, table{MediaTrack} fx tracks, table{MediaTrack} midi tracks, table{MediaTrack} folder tracks
-------------------------------------
function aratt.SplitTracksType(tracks)
	local vstiTracks = {}
	local otherTracks = {}
	local audioTracks = {}
	local fxTracks = {}
	local midiTracks = {}
	local folderTracks = {}
	
	for i = 1,#tracks do
		local track = tracks[i]
		if(aratt.isVstiTrack(track)) then table.insert(vstiTracks,track)
		elseif(aratt.isAudioTrack(track)) then table.insert(audioTracks,track)
		elseif(aratt.isFxTrack(track)) then table.insert(fxTracks,track)
		elseif(aratt.isMidiTrack(track)) then table.insert(midiTracks,track)
		elseif(aratt.isFolderTrack(track)) then table.insert(folderTracks,track)
		else table.insert(otherTracks,track)
		end
	end
	
	return vstiTracks,otherTracks,audioTracks,fxTracks,midiTracks,folderTracks
end

-------------------------------------
-- Return merged table
-- @param table{table{}} tables Tables to merge
-- @return table{} Merged table
-------------------------------------
function aratt.MergeTables(tables)
	local mergedTable = {}
	local j = 0
	for i = 1,#tables do
		local currentTable = tables[i]
		for k,v in pairs(currentTable) do j=j+1; mergedTable[j] = v end
	end
	return mergedTable
end

-------------------------------------
-- Return the "main track" (vsti or default) and error code
-- @param table{MediaTrack} vstiTracks Vsti track
-- @param table{MediaTrack} otherTracks Other track
-- @return MediaTrack (optional) Main track, number (0 : succeed, 1 : two main tracks selected, 2 : no main track selected)
-------------------------------------
function aratt.GetMainTrack(vstiTracks, otherTracks)
	local mainTrack = nil
	if #vstiTracks + #otherTracks == 0 then
		reaper.ShowMessageBox( "No main track selected (vsti or default)", "Cant route", 0 )
		return nil,2
	elseif #vstiTracks + #otherTracks > 1 then
		reaper.ShowMessageBox( "Please select only one main track (vsti or default)", "Cant route", 0 )
		return nil,1
	elseif #vstiTracks == 1 then
		mainTrack = vstiTracks[1]
	else
		mainTrack = otherTracks[1]
	end
	return mainTrack, 0
end

-------------------------------------
-- Return indexes of send which goes to audio types
-- @param MediaTrack track Track to get indexes
-- @return table{number} Indexes
-------------------------------------
function aratt.GetAudioIndexes(track)
	local removed = false
	local retValues = {}
	for j=0,reaper.GetTrackNumSends( track, 0 ) - 1 do
		if aratt.isAudioTrack(reaper.BR_GetMediaTrackSendInfo_Track(track,0,j,1)) then
			table.insert(retValues, reaper.GetTrackSendInfo_Value( track, 0, j, "I_SRCCHAN" ))
		end
	end
	return retValues
end

-------------------------------------
-- Remove duplicate send of a track. Is considered "duplicate" sends that have the same channel (src/dst) and track destination
-- @param MediaTrack track Track to proceed
-- @return number Number of removed sends
-------------------------------------
function aratt.RemoveDuplicateSend(track)
	local toBeRemoved = {}
	local numSend = reaper.GetTrackNumSends( track, 0 )
	local i = 0
	while i < numSend do
		local dstChan = reaper.GetTrackSendInfo_Value( track, 0, i, "I_DSTCHAN" )
		local srcChan = reaper.GetTrackSendInfo_Value( track, 0, i, "I_SRCCHAN" )
		local dstTrack = reaper.BR_GetMediaTrackSendInfo_Track(track,0,i,1)
		local trackIdx = reaper.GetMediaTrackInfo_Value( dstTrack, "IP_TRACKNUMBER" )
		local j = i + 1
		while j < numSend do
			local dstChan2 = reaper.GetTrackSendInfo_Value( track, 0, j, "I_DSTCHAN" )
			local srcChan2 = reaper.GetTrackSendInfo_Value( track, 0, j, "I_SRCCHAN" )
			local dstTrack2 = reaper.BR_GetMediaTrackSendInfo_Track(track,0,j,1)
			local trackIdx2 = reaper.GetMediaTrackInfo_Value( dstTrack2, "IP_TRACKNUMBER" )
			if dstChan == dstChan2 and srcChan == srcChan2 and trackIdx == trackIdx2 then
				reaper.RemoveTrackSend( track, 0, j )
				numSend = numSend - 1
			end
			j = j + 1
		end
		i = i + 1
	end
end

-------------------------------------
-- Automatically routes tracks
-- @param table{MediaTrack} tracks Tracks to route
-- @return number 0 : succeed, 1 : two main tracks selected, 2 : no main track selected, 3 : nothing to route
-------------------------------------
function aratt.AutomaticRouting(tracks)
	
	local vstiTracks = {}
	local otherTracks = {}
	local audioTracks = {}
	local fxTracks = {}
	local midiTracks = {}
	local folderTracks = {}
	
	vstiTracks,otherTracks,audioTracks,fxTracks,midiTracks,folderTracks = aratt.SplitTracksType(tracks)
	
	-- Fx track routing
	if #fxTracks > 0 then
		aratt.suffixOnAudio = false
		for fxKey,fxTrack in pairs(fxTracks) do
			for key,track in pairs(aratt.MergeTables({vstiTracks,otherTracks})) do
				local audioIndexes = aratt.GetAudioIndexes(track)
				if #audioIndexes == 0 then
					aratt.CreateAudioSend(track, fxTrack, aratt.audioSend)
				else
					for k,idx in pairs(audioIndexes) do
						aratt.CreateAudioSend(track, fxTrack, idx)
					end
				end
				aratt.RemoveDuplicateSend(track)
			end
			for key,track in pairs(audioTracks) do
				aratt.CreateAudioSend(track, fxTrack, aratt.audioSend)
				aratt.RemoveDuplicateSend(track)
			end
		end
		return 0
	end
	
	-- Get main track (vsti or default)
	local mainTrack,retVal = aratt.GetMainTrack(vstiTracks, otherTracks)
	
	if retVal > 0 then
		return retVal
	end
	
	-- Do automatic routing on vsti or default track
	local i = 0
	if #midiTracks == #audioTracks then
		for i=1,#midiTracks do
			local dstBus, dstChan, trackSend = aratt.CreateMidiSend(midiTracks[i], mainTrack)
			aratt.CreateAudioSend(mainTrack, audioTracks[i], nil, dstBus, dstChan)
		end
		
	elseif #midiTracks > 0 and #audioTracks == 0 then
		for i=1,#midiTracks do
			aratt.CreateMidiSend(midiTracks[i], mainTrack )
		end
		
	elseif #audioTracks > 0 and #midiTracks == 0 then
		for i=1,#audioTracks do
			aratt.CreateAudioSend(mainTrack, audioTracks[i] )
		end
		
	else
		reaper.ShowMessageBox( "Nothing to route / Dont know how to route", "Cant route", 0 )
		return 3
	end
	
	return 0

end

-------------------------------------
-- Launch the assisted routing procedure (note : it's better to not preventUIRefresh when calling it )
-- @param table{MediaTrack} tracks Tracks to route
-- @param boolean (optional) midiPriority True if next track should be selected if it's a midi track, false otherwise (default true)
-- @return number 0 : succeed, -1 : procedure stopped, 1 : two main tracks selected, 2 : no main track selected
-------------------------------------
function aratt.AssistedRouting(tracks, midiPriority)
	if midiPriority == nil then
		midiPriority = true
	end

	local vstiTracks = {}
	local otherTracks = {}
	local audioTracks = {}
	local fxTracks = {}
	local midiTracks = {}
	local folderTracks = {}
	
	vstiTracks,otherTracks,audioTracks,fxTracks,midiTracks,folderTracks = aratt.SplitTracksType(tracks)
	
	-- Fx track routing
	if #fxTracks > 0 then
		aratt.suffixOnAudio = false
		for fxKey,fxTrack in pairs(fxTracks) do
			reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
			reaper.SetTrackSelected( fxTrack, true )
			for key,track in pairs(aratt.MergeTables({vstiTracks,otherTracks})) do
				reaper.SetTrackSelected( track, true )
				local audioIndexes = aratt.GetAudioIndexes(track,false)
				if #audioIndexes == 0 then
					table.insert(audioIndexes,0)
				end
				for k,retValue in pairs(audioIndexes) do
					-- Getting input for vsti or other
					local sendName = tostring(math.floor(retValue)+1).."/"..tostring(math.floor(retValue)+2)
					local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
					retval, retvals_csv = reaper.GetUserInputs( "Track "..retName, 1, "Send "..sendName.." to audio (start chan.)", 1 )
					if not retval then
						return -1
					else
						input = tonumber(retvals_csv)
					end
					aratt.audioReceive = input - 1
					--
					if input > 0 then
						aratt.CreateAudioSend(track, fxTrack, retValue)
					end
				end
				reaper.SetTrackSelected( track, false )
			end
			
			for key,track in pairs(audioTracks) do
				reaper.SetTrackSelected( track, true )
				-- Getting input for audio
				local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
				retval, retvals_csv = reaper.GetUserInputs( "Track "..retName, 1, "Send to audio (start chan.) ", 1 )
				if not retval then
					return -1
				else
					input = retvals_csv
				end
				aratt.audioReceive = input - 1
				--
				aratt.CreateAudioSend(track, fxTrack, aratt.audioSend)
				reaper.SetTrackSelected( track, false )
			end
		end
		return 0
	end
	
	-- Get main track (vsti or default)
	local mainTrack,retVal = aratt.GetMainTrack(vstiTracks, otherTracks)
	
	if retVal > 0 then
		return retVal
	end

	local track = nil
	local suggestedInput = 1
	local inputLabel = ""
	local inputTitle = ""
	local previousIsAudioTrack = true
	local input = nil
	local previousMidi = 0
	local previousAudio = -1
	local tracksToRoute = aratt.MergeTables({midiTracks,audioTracks})

	while #tracksToRoute ~= 0 do

		reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
		reaper.SetTrackSelected( mainTrack, true )
		
		-- Priority to midi track
		if midiPriority and previousIsAudioTrack and #tracksToRoute > 1 and aratt.isAudioTrack(tracksToRoute[1]) and aratt.isMidiTrack(tracksToRoute[2]) then
			track = table.remove(tracksToRoute, 2)
		else
			track = table.remove(tracksToRoute, 1)
		end
		
		reaper.SetTrackSelected( track, true )
		
		inputTitle = "MIDI : "
		inputLabel = "Midi channel :"
		isAudioTrack = false
		if aratt.isAudioTrack(track) then
			inputTitle = "Audio : "
			inputLabel = "Stereo channel start :"
			isAudioTrack = true
		end
		
		-- Setting suggested input
		if previousIsAudioTrack ~= nil then
			if isAudioTrack and previousIsAudioTrack then
				suggestedInput = previousAudio + 2
			elseif isAudioTrack and not previousIsAudioTrack then
				suggestedInput = math.max(1,previousMidi)*2-1
			else
				suggestedInput = previousMidi + 1
			end
		end
		
		-- Getting input
		local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
		retval, retvals_csv = reaper.GetUserInputs( inputTitle..retName, 1, inputLabel, suggestedInput )
		if not retval then
			return -1
		else
			input = retvals_csv
		end
		
		-- Route track to main track
		if isAudioTrack then
			previousAudio = math.floor(input)
			aratt.CreateAudioSend(mainTrack, track, input - 1 )
		else
			previousMidi = math.floor(input)
			aratt.CreateMidiSend(track, mainTrack, 0,input ) -- TODO bus
		end
		
		previousIsAudioTrack = isAudioTrack
	end

	reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
	reaper.SetTrackSelected( mainTrack, true )
	
	return 0

end

return aratt
