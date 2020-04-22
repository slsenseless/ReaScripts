-- @noindex

-- Optional if ccec_core is in reaper lua folder
local script_path = debug.getinfo(1,'S').source:sub(2,-5) -- remove "@" and "file extension" from file name
if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
  package.path = package.path .. ";" .. script_path:match("(.*".."\\"..")") .. "?.lua"
else
  package.path = package.path .. ";" .. script_path:match("(.*".."/"..")") .. "?.lua"
end
--

local ccec = require("ccec_core")

if ccec == nil then
	reaper.ShowConsoleMsg("Ccec core not loaded")
	return -1
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
reaper.Main_OnCommand( reaper.NamedCommandLookup( "_SWS_SELTRKWITEM" ), 0 ) -- Select only track with selected items

local toggleValue = nil

local i = 0
for i=0,reaper.CountSelectedTracks( 0 ) - 1 do

	local envelopes = ccec.GetAllEnvelopes(reaper.GetSelectedTrack( 0, i ))
	
	for key,evenlope in pairs(envelopes) do
	
		local _, envelopeStateChunk = reaper.GetEnvelopeStateChunk( evenlope, "", true )
		
		if string.find(envelopeStateChunk, "ACT 1") ~= nil then
			if toggleValue == nil then
				toggleValue = "ACT 0"
			end
			envelopeStateChunk = string.gsub(envelopeStateChunk, "ACT 1", toggleValue )
		else
			if toggleValue == nil then
				toggleValue = "ACT 1"
			end
			envelopeStateChunk = string.gsub(envelopeStateChunk, "ACT 0", toggleValue )
		end
		
		reaper.SetEnvelopeStateChunk( evenlope, envelopeStateChunk, true )
	end
end

reaper.Undo_EndBlock("Enable/Disable CC envelopes", 1)
reaper.PreventUIRefresh(-1)
