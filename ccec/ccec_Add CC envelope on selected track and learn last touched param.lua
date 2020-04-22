-- @noindex

-- Valid input :
-- 0-119 : CC 0-119 (7 bits)
-- 128-159 : CC 0+32-31+63 (14 bits)
-- 0d-31d : CC 0+32-31+63 (14 bits)
-- 'Volume', 'bal', 'PAN' ... etc : Every ccec.CC_NAMES (case insensitive, can be uncomplete, 14 bits)

-- Optional if ccec_core is in reaper lua folder
local script_path = debug.getinfo(1,'S').source:sub(2,-5) -- remove "@" and "file extension" from file name
if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
  package.path = package.path .. ";" .. script_path:match("(.*".."\\"..")") .. "?.lua"
else
  package.path = package.path .. ";" .. script_path:match("(.*".."/"..")") .. "?.lua"
end
--

local ccec = require("ccec_core")

local track = reaper.GetSelectedTrack(0, 0)
local retval, trackFxIdx, fxData, paramNumber = reaper.GetLastTouchedFX() -- trackFxIdx is 1-based !

if not track or not retval then
    reaper.ShowMessageBox("No track selected or last touched FX", "Error", 0)
	return 1
end

local _, trackName = reaper.GetTrackName(track)
local _, paramName = reaper.TrackFX_GetParamName( track, fxData & 0x00FFFFFF, paramNumber, "" )

retval, retvals_csv = reaper.GetUserInputs( "Add envelope on "..trackName.." linked to param "..paramName, 1, "CC number :", "0" )
if not retval then
    return 1
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

ccNum = nil
for key,value in pairs(ccec.CC_NAMES) do
	if string.find(string.lower(key),"^"..string.lower(retvals_csv)..".*") ~= nil then
		ccNum = value
		break
	end
end

if ccNum == nil then
	if string.sub(retvals_csv, -1) == 'd' then
		ccNum = tonumber(string.sub(retvals_csv,1,string.len(retvals_csv)-1))
		if ccNum ~= nil then -- Conversion succeeded
			ccNum = ccNum + 128
		end
	else
		ccNum = tonumber(retvals_csv)
	end
end

if ccNum == nil then
	reaper.ShowMessageBox("Invalid input", "Error", 0)

elseif ccec.AddLearnParam(reaper.GetTrack( 0, trackFxIdx - 1 ), fxData, paramNumber, ccNum) then
	ccec.GetEnvelope(track, ccNum)

else
	reaper.ShowMessageBox("Chunk error", "Chunk error", 0)
	
end

reaper.Undo_EndBlock("Add envelope on selected track and link last touched param with it", 0)
reaper.PreventUIRefresh(-1)
