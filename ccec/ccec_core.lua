-- @noindex
local ccec = {}

ccec.SEVEN_BITS = 127 -- 2^7 - 1
ccec.FOURTEEN_BITS = 16383 -- 2^14 - 1
ccec.CC_NAMES = {
["Bank Select"] = 128,
["Mod Wheel"] = 129,
["Breath"] = 130,
--
["Foot Pedal"] = 132,
["Portamento"] = 133,
["Data Entry"] = 134,
["Volume"] = 135,
["Balance"] = 136,
--
["Pan"] = 138,
["Expression"] = 139,
["Control 1"] = 140,
["Control 2"] = 141,
--
--
["GP Slider 1"] = 144,
["GP Slider 2"] = 145,
["GP Slider 3"] = 146,
["GP Slider 4"] = 147,
}

-- Functions Get/SetTrackChunk by EUGEN27771 (in ChunkEditor), allow chunk > 4MB
function ccec.GetTrackChunk(track)
	if not track then return end
	-- Try standart function -----
	local ret, track_chunk = reaper.GetTrackStateChunk(track, "", false) -- isundo = false
	if ret and track_chunk and #track_chunk < 4194303 then return track_chunk end
	-- If chunk_size >= max_size, use wdl fast string --
	local fast_str = reaper.SNM_CreateFastString("")
	if reaper.SNM_GetSetObjectState(track, fast_str, false, false) then
		track_chunk = reaper.SNM_GetFastString(fast_str)
	end
	reaper.SNM_DeleteFastString(fast_str)
	return track_chunk
end
function ccec.SetTrackChunk(track, track_chunk)
	if not (track and track_chunk) then return end
	if #track_chunk < 4194303 then return reaper.SetTrackStateChunk(track, track_chunk, false) end  -- isundo = false
	-- If chunk_size >= max_size, use wdl fast string --
	local fast_str, ret 
	fast_str = reaper.SNM_CreateFastString("")
	if reaper.SNM_SetFastString(fast_str, track_chunk) then
		ret = reaper.SNM_GetSetObjectState(track, fast_str, true, false)
	end
	reaper.SNM_DeleteFastString(fast_str)
	return ret
end

-------------------------------------
-- Update envelopes
-- @param MediaTrack track Track to update envelope from midi cc
-------------------------------------
function ccec.UpdateEnvelope(track)

	ccec.ClearEnvelopes(track)
	
	local i = 0
	for i = 0, reaper.GetTrackNumMediaItems( track ) - 1 do
		local midiItem = reaper.GetTrackMediaItem( track, i )
		local midiItemTake = reaper.GetActiveTake( midiItem )
		local isTakeMidi, _ = reaper.BR_IsTakeMidi( midiItemTake )
		if isTakeMidi == true then
			-- Update envelopes
			local j = 0
			local alreadyDone = {} -- Data are already done if they were part of a CC 14 bits point
			while true do
			
				-- Get CC data
				local retValShape, shape, beztension = reaper.MIDI_GetCCShape( midiItemTake, j )
				if shape == 0 then shape = 1 elseif shape == 1 then shape = 0 end -- Linear / Squared are reversed
				local retValCC, _, _, ppqpos, _, _, ccNum, ccValue = reaper.MIDI_GetCC( midiItemTake, j )
				if not retValShape or not retValCC then
					break -- No more CC data
				end
			
				if alreadyDone[j] == nil then
					
					-- Update CC number/value if CC is 14bits, put other byte in already done list
					local k = j + 1
					local divideValue = ccec.SEVEN_BITS -- By default, only 7 bits
					local retValCC, _, _, ppqposNext, _, _, ccNumNext, ccValueNext = reaper.MIDI_GetCC( midiItemTake, k )
					while ppqposNext == ppqpos do
						if not retValCC then break
						elseif ccNumNext == ccNum + 32 then -- Current is MSB, next is LSB
							ccNum = ccNum + 128
							ccValue = (ccValue << 7) + ccValueNext
							divideValue = ccec.FOURTEEN_BITS
							alreadyDone[k] = true
							break
						elseif ccNumNext == ccNum - 32 then -- Current is LSB, next is MSB
							ccNum = ccNumNext + 128
							ccValue = (ccValueNext << 7) + ccValue
							divideValue = ccec.FOURTEEN_BITS
							alreadyDone[k] = true
							break
						end
						k = k + 1
						retValCC, _, _, ppqposNext, _, _, ccNumNext, ccValueNext = reaper.MIDI_GetCC( midiItemTake, k )
					end
					
					-- Insert CC data in envelope
					local ccPos = reaper.MIDI_GetProjTimeFromPPQPos( midiItemTake, ppqpos )
					local envelope = ccec.GetEnvelope(track, ccNum)
					reaper.InsertEnvelopePoint( envelope, ccPos, ccValue/divideValue, shape, beztension, false )
					
				end
				
				j = j + 1
			end
			
			-- Create automation items if needed
			local envelopes = ccec.GetAllEnvelopes(track)
			local key, envelope = 0, nil
			_, midiItemStateChunk = reaper.GetItemStateChunk( midiItem, "", true )
			
			if string.find(midiItemStateChunk, "LOOP 1") ~= nil then
				local midiItemStartPos = reaper.GetMediaItemInfo_Value( midiItem, "D_POSITION" )
				local midiItemLength = reaper.GetMediaItemInfo_Value( midiItem, "D_LENGTH" )
				local midiItemOffset =  reaper.GetMediaItemTakeInfo_Value( midiItemTake, "D_STARTOFFS" )
				local midiSource = reaper.GetMediaItemTake_Source( midiItemTake )
				local _, _, midiItemLoopLength, _ = reaper.PCM_Source_GetSectionInfo( midiSource )
				for key, envelope in pairs(envelopes) do
					local idx = reaper.InsertAutomationItem( envelope, -1, midiItemStartPos - midiItemOffset, midiItemLoopLength )
					reaper.GetSetAutomationItemInfo( envelope, idx, "D_LENGTH", midiItemLength, true )
					reaper.GetSetAutomationItemInfo( envelope, idx, "D_STARTOFFS", midiItemOffset, true )
					reaper.GetSetAutomationItemInfo( envelope, idx, "D_POSITION", midiItemStartPos, true )
				end
			end
			
		end
	end
end

-------------------------------------
-- Clear all envelopes (related to midi CC) of a track
-- @param MediaTrack track Track to clear envelopes
-------------------------------------
function ccec.ClearEnvelopes(track)
	local envelopes = ccec.GetAllEnvelopes(track)
	local key, envelope = 0, nil
	for key, envelope in pairs(envelopes) do
		reaper.DeleteEnvelopePointRange( envelope, 0, reaper.GetProjectLength( 0 ) + 1 )
		local i = 0
		for i = 0,reaper.CountAutomationItems( envelope ) - 1 do
			reaper.GetSetAutomationItemInfo( envelope, i, "D_UISEL", 1, true )
		end
		reaper.Main_OnCommand( 42086, 0 ) -- Delete selected automation item
	end
end

-------------------------------------
-- Get envelope corresponding to the CC channel, create ReaControlMIDI if none exists
-- @param MediaTrack track Track to get envelope from
-- @param number ccNum CC number
-- @return TrackEnvelope
-------------------------------------
function ccec.GetEnvelope(track, ccNum)

	local isFourteenBits = false
	if ccNum > ccec.SEVEN_BITS then
		isFourteenBits = true
		ccNum = ccNum - 128
	end
	
	local i = 0
	local ccNumMin = math.floor(ccNum / 5) * 5
	local chanPresetName = "CC_" .. tostring(ccNumMin)
	if not isFourteenBits then
		chanPresetName = chanPresetName.."_raw"
	end
	
	for i = 0,reaper.TrackFX_GetCount( track ) - 1 do
		local exist, _ = reaper.TrackFX_GetFXName( track, i, "" )
		if exist == false then
			break
		end
		local _, presetName = reaper.TrackFX_GetPreset( track, i, "" )
		if string.match(presetName, chanPresetName) then
			return reaper.GetFXEnvelope( track, i, 3 + math.fmod(ccNum, 5), true )
		end
	end
	
	fxIdx = reaper.TrackFX_AddByName( track, "ReaControlMIDI (Cockos)", false, -1 )
	reaper.TrackFX_SetPreset( track, fxIdx, chanPresetName )
	
	return reaper.GetFXEnvelope( track, fxIdx, 3 + math.fmod(ccNum, 5), true )
end

-------------------------------------
-- Get all envelopes that correspond to a CC
-- @param MediaTrack track Track to get envelopes from
-- @return table{TrackEnvelope}
-------------------------------------
function ccec.GetAllEnvelopes(track)
	local envelopes = {}
	local i = 0
	for i = 0, reaper.CountTrackEnvelopes( track ) - 1 do
		local envelope = reaper.GetTrackEnvelope( track, i )
		if ccec.isCCEnvelope(envelope) then
			table.insert(envelopes,envelope)
		end
	end
	return envelopes
end

-------------------------------------
-- Tells if an envelope is a CC envelope (based on its name)
-- @param TrackEnvelope envelope Envelope to check
-- @return boolean, true if envelope is CC
-------------------------------------
function ccec.isCCEnvelope(envelope)
	local retval, name = reaper.GetEnvelopeName( envelope )
	if retval == false then
		return false
	end
	
	if string.match(name, "ReaControlMIDI$") then
		return true
	end
	return false
end

-------------------------------------
-- Update midi CC
-- @param MediaTrack track Track to update midi cc from envelopes
-------------------------------------
function ccec.UpdateMidi(track)
	
	ccec.ClearMidiCC(track)
	
	local i = 0
	for i = 0, reaper.CountTrackMediaItems( track ) - 1 do
		local midiItem = reaper.GetTrackMediaItem( track, i )
		local midiItemTake = reaper.GetActiveTake( midiItem )
		local isTakeMidi, _ = reaper.BR_IsTakeMidi( midiItemTake )
		if isTakeMidi == true then
			local midiItemStartPos = reaper.GetMediaItemInfo_Value( midiItem, "D_POSITION" )
			local midiSource = reaper.GetMediaItemTake_Source( midiItemTake )
			local _, _, midiSourceLength, _ = reaper.PCM_Source_GetSectionInfo( midiSource )
			local midiItemOffset =  reaper.GetMediaItemTakeInfo_Value( midiItemTake, "D_STARTOFFS" )
			local envelopes = ccec.GetAllEnvelopes(track)
			local envelopesPoints = {}
			local k = 1
			
			-- Gathering envelopes points in midiItem scope
			for key,envelope in pairs(envelopes) do
				local j = 0
				local ccNum = ccec.GetEnvelopeCC(envelope)
				
				-- GetEnvelopePoint doesn't take automation item
				-- have to delete them with preseved points, then put them back at the end
				for j = 0,reaper.CountAutomationItems( envelope ) - 1 do
					reaper.GetSetAutomationItemInfo( envelope, j, "D_UISEL", 1, true )
				end
				reaper.Main_OnCommand( 42088, 0 ) -- Delete selected automation item, preserved points
				--
				
				ccec.AddEnvelopeEdges(envelope,midiItem)
				for j = 0, reaper.CountEnvelopePoints( envelope ) - 1 do
					local _, pos, value, shape, beztension, _ = reaper.GetEnvelopePoint( envelope, j )
					if pos >= midiItemStartPos - midiItemOffset and pos <= midiItemStartPos - midiItemOffset + midiSourceLength then
						envelopesPoints[k] = {ccNum,pos,value,shape,beztension}
						k = k + 1
					end
				end
			end
			
			-- Sorting points on pos
			table.sort(envelopesPoints, function (a,b) return a[2] < b[2] end)
			
			-- Inserting points in midi item take
			k = 0
			for key,point in pairs(envelopesPoints) do
				local ccNum, pos, value, shape, beztension = point[1],point[2],point[3],point[4],point[5]
				if shape == 0 then shape = 1 elseif shape == 1 then shape = 0 end -- Linear / Squared are reversed
				local ppqPos = reaper.MIDI_GetPPQPosFromProjTime( midiItemTake, pos )
				-- 16383
				if ccNum > ccec.SEVEN_BITS then -- 14 bits
					value = math.floor(value*ccec.FOURTEEN_BITS)
					-- Insert MSB
					-- reaper.MIDI_InsertCC( midiItemTake, true, false, ppqPos, 176, 0, ccNum - 128, math.floor(value*127) )
					reaper.MIDI_InsertCC( midiItemTake, true, false, ppqPos, 176, 0, ccNum - 128, math.floor(value >> 7) )
					reaper.MIDI_SetCCShape( midiItemTake, k, shape, beztension, false )
					k = k + 1
					
					-- Insert LSB
					reaper.MIDI_InsertCC( midiItemTake, true, false, ppqPos, 176, 0, ccNum - 96, math.floor(value & 0xFFFFFFF) )
					reaper.MIDI_SetCCShape( midiItemTake, k, shape, beztension, false )
					k = k + 1
				else
					reaper.MIDI_InsertCC( midiItemTake, true, false, ppqPos, 176, 0, ccNum, math.floor(value*127) )
					reaper.MIDI_SetCCShape( midiItemTake, k, shape, beztension, false )
					k = k + 1
				end
			end
			
		end
	end
	
	ccec.UpdateEnvelope(track) -- Put back automation item, refresh envelopes
	
end

-------------------------------------
-- Clear all midi CC of all MediaItem of a track
-- @param MediaTrack track Track to clear midi CC
-------------------------------------
function ccec.ClearMidiCC(track)
	local i = 0
	for i = 0, reaper.CountTrackMediaItems( track ) - 1 do
		local midiItem = reaper.GetTrackMediaItem( track, i )
		local midiItemTake = reaper.GetActiveTake( midiItem )
		local isTakeMidi, _ = reaper.BR_IsTakeMidi( midiItemTake )
		if isTakeMidi == true then
			while true do
				if not reaper.MIDI_DeleteCC( midiItemTake, 0 ) then
					break
				end
			end
		end
	end
end

-------------------------------------
-- Get corresponding CC of an envelope
-- @param TrackEnvelope envelope Envelope to get CC from
-- @return number Corresponding CC channel, -1 if not found
-------------------------------------
function ccec.GetEnvelopeCC(envelope)
	if not ccec.isCCEnvelope(envelope) then return -1 end
	
	local _, envelopeName = reaper.GetEnvelopeName( envelope )
	
	envelopeNameTable = {}
	for s in envelopeName:gmatch("[^%s]+") do
		table.insert(envelopeNameTable, s)
	end
	
	for key,value in pairs(ccec.CC_NAMES) do
		if string.find(envelopeName,"^"..key) ~= nil then
			return value
		end
	end
		
	if envelopeNameTable[1] == "CC" then
		if string.find(envelopeNameTable[2], "+") ~= nil then -- 14 bits
			return tonumber(string.sub(envelopeNameTable[2],1,string.find(envelopeNameTable[2], "+") - 1)) + 128
		else
			return tonumber(envelopeNameTable[2])
		end
	else
		return -1
	end
end

-------------------------------------
-- Add points to the envelope at the edge of the active MediaItem_Take if there is none
-- @param Track_Envelope envelope
-- @param MediaItem midiItem
-------------------------------------
function ccec.AddEnvelopeEdges(envelope, midiItem)
	local midiItemStartPos = reaper.GetMediaItemInfo_Value( midiItem, "D_POSITION" )
	local midiItemTake = reaper.GetActiveTake( midiItem )
	local midiSource = reaper.GetMediaItemTake_Source( midiItemTake )
	local _, _, midiSourceLength, _ = reaper.PCM_Source_GetSectionInfo( midiSource )
	local midiItemOffset =  reaper.GetMediaItemTakeInfo_Value( midiItemTake, "D_STARTOFFS" )

	ccec.AddEnvelopePoint(envelope, midiItemStartPos - midiItemOffset)
	ccec.AddEnvelopePoint(envelope, midiItemStartPos - midiItemOffset + midiSourceLength)
end

-------------------------------------
-- Add points to the envelope at the pointPos if none exists. Take the previous point as reference for shape/bez
-- @param Track_Envelope envelope
-- @param number pointPos Position of the point
-- @return boolean True if point has been added, false otherwise
-------------------------------------
function ccec.AddEnvelopePoint(envelope, pointPos)
	if hasPoint(envelope,pointPos) then return false end
	
	local pointIdx = reaper.GetEnvelopePointByTime( envelope, pointPos )
	local retval, pos, _, shape, beztension, _ = reaper.GetEnvelopePoint( envelope, pointIdx )
	local _, value, _, _, _ = reaper.Envelope_Evaluate( envelope, pointPos, 0, 0 )
	if retval then
		if pos < pointPos then
			reaper.InsertEnvelopePoint( envelope, pointPos, value, shape, beztension, false )
			return true
		elseif pos ~= pointPos then
			reaper.InsertEnvelopePoint( envelope, pointPos, value, 0, 0, false )
			return true
		else
			return false
		end
	else
		return false
	end
end

-------------------------------------
-- Tells if an envelope has already a point at a position
-- @param Track_Envelope envelope
-- @param number pointPos Position to test
-- @return boolean True if a point is there, false otherwise
-------------------------------------
function hasPoint(envelope, pointPos)
	local pointIdx = reaper.GetEnvelopePointByTime( envelope, pointPos )
	local i
	for i = pointIdx, reaper.CountEnvelopePoints( envelope ) - 1 do
		local _, pos, _, _, _, _ = reaper.GetEnvelopePoint( envelope, i )
		if pos == pointPos then
			return true
		elseif pos > pointPos then
			return false
		end
	end
	return false
end

-------------------------------------
-- Get the fx number and type for the fxnumber GetLastTouchedFX function
-- @param MediaTrack track
-- @param number fxData (fxnumber of GetLastTouchedFX)
-- @param number paramNumber (paramnumber of GetLastTouchedFX)
-- @param number ccNum 0-127: 7 bits CC, 128-159: 14 bits CC (128 is 0+32 etc..)
-- @return boolean True if success
-------------------------------------
function ccec.AddLearnParam(track, fxData, paramNumber, ccNum)
	local fxNumber = fxData & 0x00FFFFFF
	local fxType = "<FXCHAIN"
	if (fxData >> 24) > 0 then
		fxType = "<FXCHAIN_REC"
	end

	-- Prepare paramChunk
	_, paramName = reaper.TrackFX_GetParamName( track, fxNumber, paramNumber, "" )
	if paramName ~= nil or paramName ~= "" then
		paramName = ":"..paramName
	end

	-- MIDIPLINK [?] [?] [MIDI msg3] [MIDI msg2 : CC number, add 128 to MSB to get 14 bits CC]
	local paramChunk = {
	"<PROGRAMENV "..tostring(paramNumber)..paramName.." 0",
	"PARAMBASE 0",
	"LFO 0",
	"LFOWT 1 1",
	"AUDIOCTL 0",
	"AUDIOCTLWT 1 1",
	"PLINK 1 -100 -1 0",
	"MIDIPLINK 0 0 176 "..tostring(ccNum),
	">",
	""
	}

	-- Get/Explore track chunk
	local str = ccec.GetTrackChunk(track)

	lines = {}
	for s in str:gmatch("[^\r\n]+") do
		table.insert(lines, s.."\r\n")
	end
	
	local findFx = true
	local findVst = false
	local findWak = false
	local vstCount = 0
	for key,line in pairs(lines) do
		if findFx and string.find(line, "^"..fxType) ~= nil then
			findFx = false
			findVst = true

		elseif findVst and string.find(line, "^<VST") ~= nil then
			if vstCount == fxNumber then
				findVst = false
				findWak = true
			end
			vstCount = vstCount + 1

		elseif findWak and string.find(line, "^WAK") ~= nil then
			table.insert(lines, key, table.concat(paramChunk, "\r\n"))
			break
		end
	end

	return ccec.SetTrackChunk(track, table.concat(lines))
	
end

return ccec
