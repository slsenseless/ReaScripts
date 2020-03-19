-- @noindex
local aratt = {}

-- Layout/Icons names
-- /!\ Layout names vstiPanelLayout, audioPanelLayout, midiPanelLayout and folderPanelLayout should be different !

aratt.vstiPanelLayout = "VSTi"
aratt.vstiMixerLayout = "VSTi" -- Put "" for default layout
aratt.vstiName = "VSTi: "
aratt.vstiIcon = "synth.png" -- Put "" for none
aratt.audioPanelLayout = "Audio"
aratt.audioMixerLayout = "Audio" -- Put "" for default layout
aratt.audioName = "Out"
aratt.audioIcon = "amp_combo.png" -- Put "" for none
aratt.folderPanelLayout = "Folder"
aratt.folderMixerLayout = "Folder" -- Put "" for default layout
aratt.folderName = ""
aratt.folderIcon = "folder.png" -- Put "" for none
aratt.midiPanelLayout = "Midi"
aratt.midiMixerLayout = "Midi" -- Put "" for default layout
aratt.midiName = "Midi"
aratt.midiIcon = "midi.png" -- Put "" for none
aratt.defaultPanelLayout = "Global layout default"
aratt.defaultMixerLayout = "Global layout default"

-- Suffix
aratt.suffixOnMidi = true -- Put Channel / Bus at the end of midi name
aratt.suffixOnAudio = true -- Put Channel at the end of audio name

-- Show/Hide types in mixer/panel
aratt.showMidiMixer = false
aratt.showAudioPanel = false

-- Midi configuration
aratt.useBus = false -- True: all 16 buses will be used, False: default bus (0) will be used
aratt.maxNumberBus = 16 -- Number of buses used (if useBus true), maximum is 16
aratt.midiSendChan = 0 -- Midi channel send from Midi track to Vsti (0: All, 1: Channel 1 etc...)
aratt.midiSendBus = 0 -- Midi bus send from Midi track to Vsti (0: All, 1: Bus 1 etc...)
aratt.midiReceiveChan = 0 -- Midi channel used if static parameter is true on CreateMidiSend
aratt.midiReceiveBus = 0 -- Midi bus used if static parameter is true on CreateMidiSend

-- Audio configuration
aratt.maxAudioChan = 64
aratt.audioReceive = 0 -- Audio channel on audio track (0: Stereo 1/2, 2: Stereo 3/4...) Do NOT put it above maxAudioChan-2
aratt.audioSend = 0 -- Audio channel used if static parameter is true on CreateAudioSend

-- Vsti configuration
aratt.vstiSendParent = 0 -- 0 don't send to parent, 1 send

-- Other track configuration
aratt.staticSendOnOther = false -- If true, audioSend and midiSendBus/Chan will be taken, otherwise first available channel will be taken

-------------------------------------
-- Get point of tracks insertions
-- @return number Position of last selected track
-------------------------------------
function aratt.GetInsertionPoint()
	local selectionSize = reaper.CountSelectedTracks(0)
	if selectionSize == 0 then
		return reaper.GetNumTracks()
	end

	track = reaper.GetSelectedTrack(0, selectionSize - 1)
	return reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
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
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", name, true )
	return track
end

-------------------------------------
-- Tells whether or not an icon should be applied
-- @param MediaTrack track Track to apply icon
-- @param string iconName Icon name to apply
-- @return boolean True if icon should be changed, false otherwise
-------------------------------------
function aratt.changeIcon(track, iconName)
	local retval, currentIcon = reaper.GetSetMediaTrackInfo_String( track, "P_ICON", "", false )
	if currentIcon == nil or currentIcon == "" or
		(currentIcon == aratt.midiIcon and aratt.isMidiTrack(track)) or
		(currentIcon == aratt.audioIcon and aratt.isAudioTrack(track)) or
		(currentIcon == aratt.folderIcon and aratt.isFolderTrack(track)) or
		(currentIcon == aratt.vstiIcon and aratt.isVstiTrack(track))
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
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if stringNeedBig == nil or stringNeedBig == "" then
		reaper.GetSetMediaTrackInfo_String(track, "P_NAME", aratt.audioName, true)
	end
	
	if aratt.changeIcon(track,aratt.audioIcon) then
		retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_ICON", aratt.audioIcon, true )
	end
	
	if aratt.stateAudioShow() == 0 then
		reaper.SetMediaTrackInfo_Value(track, "B_SHOWINTCP", 0)
	end
	retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.audioPanelLayout, true ) -- Apply audio out layout on panel
	retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.audioMixerLayout, true ) -- Apply audio out layout on mixer
	local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL")
	if vol == 0 then
		reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1)
	end
	reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 60)
	reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
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
	return aratt.TransformToAudio(aratt.CreateTrack(pos,depth,name))
end

-------------------------------------
-- Transform a track to Folder
-- @param MediaTrack track to transform
-- @return MediaTrack track transformed
-------------------------------------
function aratt.TransformToFolder(track)
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if stringNeedBig == nil or stringNeedBig == "" then
		reaper.GetSetMediaTrackInfo_String(track, "P_NAME", aratt.folderName, true)
	end
	
	if aratt.changeIcon(track,aratt.folderIcon) then
		retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_ICON", aratt.folderIcon, true )
	end
	
	retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.folderPanelLayout, true ) -- Apply audio out layout on panel
	retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.folderMixerLayout, true ) -- Apply audio out layout on mixer
	local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL")
	if vol == 0 then
		reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1)
	end
	reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 60)
	reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
	return track
end

-------------------------------------
-- Create a Folder track
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @return MediaTrack Created folder track
-------------------------------------
function aratt.CreateFolderTrack(pos, depth)
	return aratt.TransformToFolder(aratt.CreateTrack(pos,depth))
end

-------------------------------------
-- Transform a track to Vsti
-- @param MediaTrack track to transform
-- @return MediaTrack track transformed
-------------------------------------
function aratt.TransformToVsti(track)
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if stringNeedBig == nil or stringNeedBig == "" then
		reaper.GetSetMediaTrackInfo_String(track, "P_NAME", aratt.vstiName, true)
	end
	
	if aratt.changeIcon(track,aratt.vstiIcon) then
		retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_ICON", aratt.vstiIcon, true )
	end
	
	retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.vstiPanelLayout, true ) -- Apply audio out layout on panel
	retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.vstiMixerLayout, true ) -- Apply audio out layout on mixer
	reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", aratt.vstiSendParent)
	reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 60)
	reaper.SetMediaTrackInfo_Value(track, "I_RECARM", 0)
	return track
end

-------------------------------------
-- Create a Vsti track
-- @param number (optional) pos Position of the track
-- @param number (optional) depth Depth of the track
-- @return MediaTrack Created Vsti track
-------------------------------------
function aratt.CreateVstiTrack(pos, depth)
	return aratt.TransformToVsti(aratt.CreateTrack(pos,depth))
end

-------------------------------------
-- @param MediaTrack track Vsti Track
-- @return string Name of the vsti
-------------------------------------
function aratt.GetVstiName(track)
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	local len_full_name = string.len(stringNeedBig)
	local len_default_name = string.len(aratt.vstiName)
	if aratt.isVstiTrack(track) and len_full_name > len_default_name then
		return string.sub(stringNeedBig,len_default_name+1,len_full_name)
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
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if stringNeedBig == nil or stringNeedBig == "" then
		reaper.GetSetMediaTrackInfo_String(track, "P_NAME", aratt.midiName, true)
	end
	
	if aratt.changeIcon(track,aratt.midiIcon) then
		retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_ICON", aratt.midiIcon, true )
	end
	
	if aratt.stateMidiShow() == 0 then
		reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 0)
	end
	retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.midiPanelLayout, true ) -- Apply midi layout on panel
	retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.midiMixerLayout, true ) -- Apply midi layout on mixer

	reaper.SetMediaTrackInfo_Value(track, "I_HEIGHTOVERRIDE", 120)
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
	return aratt.TransformToMidi(aratt.CreateTrack(pos,depth,name))
end

-------------------------------------
-- Transform a track to default
-- @param MediaTrack track to transform
-- @return MediaTrack transformed track
-------------------------------------
function aratt.TransformToDefault(track)
	reaper.GetSetMediaTrackInfo_String( track, "P_ICON", "", true )
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", aratt.defaultPanelLayout, true ) -- Apply default layout on panel
	retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_MCP_LAYOUT", aratt.defaultMixerLayout, true ) -- Apply default layout on mixer
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINMIXER", 1)
	reaper.SetMediaTrackInfo_Value(track, "B_SHOWINPANEL", 1)
	reaper.SetMediaTrackInfo_Value(track, "B_MAINSEND", 1)
	local vol = reaper.GetMediaTrackInfo_Value( track, "D_VOL")
	if vol == 0 then
		reaper.SetMediaTrackInfo_Value(track, "D_VOL", 1)
	end
	return track
end

-------------------------------------
-- @param MediaTrack track Track to check
-- @return boolean true if track is a midi, false otherwise
-------------------------------------
function aratt.isMidiTrack(track)
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false)
	return stringNeedBig == aratt.midiPanelLayout
end

-------------------------------------
-- @param MediaTrack track Track to check
-- @return boolean true if track is an audio, false otherwise
-------------------------------------
function aratt.isAudioTrack(track)
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false)
	return stringNeedBig == aratt.audioPanelLayout
end

-------------------------------------
-- @param MediaTrack track Track to check
-- @return boolean true if track is a vsti, false otherwise
-------------------------------------
function aratt.isVstiTrack(track)
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false)
	return stringNeedBig == aratt.vstiPanelLayout
end

-------------------------------------
-- @param MediaTrack track Track to check
-- @return boolean true if track is a folder, false otherwise
-------------------------------------
function aratt.isFolderTrack(track)
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_TCP_LAYOUT", "", false)
	return stringNeedBig == aratt.folderPanelLayout
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
		if aratt.isAudioTrack(track) then
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
	local retval, stringNeedBig = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	if suffix == " (0)" then
		suffix = " (All)"
	end
	reaper.GetSetMediaTrackInfo_String(track, "P_NAME", stringNeedBig..suffix, true)
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
-- @param boolean (optional) staticSend if true, midiReceiveChan/Bus will be used (false by default)
-- @return number,number,number : bus used, channel used, trackSend
-------------------------------------
function aratt.CreateMidiSend(trackSrc, trackDst, staticSend)
	local trackSend = reaper.CreateTrackSend( trackSrc, trackDst )
	local dstBus, dstChan = aratt.midiReceiveBus, aratt.midiReceiveChan
	if staticSend == nil or not staticSend then
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
-- @param boolean (optional) staticSend if true, audioSend will be used (false by default)
-- @param number midiBus, number midiChan (optional) if set, audio channel will correspond to midi bus/channel
-- @return number,number : channel used, trackSend
-------------------------------------
function aratt.CreateAudioSend(trackSrc, trackDst, staticSend, midiBus, midiChan)
	local audioChan = aratt.audioSend
	if staticSend == nil or not staticSend then
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
-- Automatically routes tracks
-- @param table{MediaTrack} tracks Tracks to route
-- @return number 0 : succeed, 1 : vsti and default selected, 2 : two tracks of the same type selected, 3 : nothing to route
-------------------------------------
function aratt.AutomaticRouting(tracks)
	
	local midiTracks = {}
	local audioTracks = {}
	local vstiTrack = nil
	local otherTrack = nil
	
	-- Looking for what tracks types are selected
	local i = 1
	for i = 1,#tracks do
		local track = tracks[i]
		if aratt.isMidiTrack(track) then
			table.insert(midiTracks, track)
		elseif aratt.isAudioTrack(track) then
			table.insert(audioTracks, track)
		elseif aratt.isVstiTrack(track) then
			if vstiTrack == nil then
				vstiTrack = track
			else
				reaper.ShowMessageBox( "Please select only one vsti track", "Cant route", 0 )
				return 2
			end
		else
			if otherTrack == nil then
				otherTrack = track
			else
				reaper.ShowMessageBox( "Please select only one default track", "Cant route", 0 )
				return 2
			end
		end
	end
	
	if vstiTrack ~=nil and otherTrack ~= nil then
		reaper.ShowMessageBox( "Please select one default OR one vsti track", "Cant route", 0 )
		return 1
	end

	-- Do automatic routing
	if #midiTracks == #audioTracks and vstiTrack ~= nil then
		local i = 0
		for i=1,#midiTracks do
			local dstBus, dstChan, trackSend = aratt.CreateMidiSend(midiTracks[i], vstiTrack)
			aratt.CreateAudioSend(vstiTrack, audioTracks[i], false, dstBus, dstChan)
		end
	elseif vstiTrack ~= nil and #midiTracks > 0 and #audioTracks == 0 then
		for i=1,#midiTracks do
			aratt.CreateMidiSend(midiTracks[i], vstiTrack )
		end
		
	elseif vstiTrack ~= nil and #audioTracks > 0 and #midiTracks == 0 then
		for i=1,#audioTracks do
			aratt.CreateAudioSend(vstiTrack, audioTracks[i])
		end
	
	elseif otherTrack ~= nil and #midiTracks > 0 and #audioTracks == 0 then
		for i=1,#midiTracks do
			aratt.CreateMidiSend(midiTracks[i], otherTrack, aratt.staticSendOnOther)
		end
	
	elseif otherTrack ~= nil and #audioTracks > 0 and #midiTracks == 0 then
		for i=1,#audioTracks do
			aratt.CreateAudioSend(otherTrack, audioTracks[i], aratt.staticSendOnOther)
		end
	else
		reaper.ShowMessageBox( "Nothing to route / Dont know how to route", "Cant route", 0 )
		return 3
	end
	
	return 0

end

return aratt
