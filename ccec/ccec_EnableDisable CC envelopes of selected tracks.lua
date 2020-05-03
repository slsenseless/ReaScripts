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

local toggleValue = nil
local _,_,sectionID,cmdID,_,_,_ = reaper.get_action_context()
local commandName = "_RS7d3c_e6b9aed3771b2fed87caa2b1e3f9280f83d24dfe"


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
			reaper.SetToggleCommandState( sectionID, cmdID, 0 )
			reaper.SetToggleCommandState( 32060,  reaper.NamedCommandLookup( commandName ), 0 )
		else
			if toggleValue == nil then
				toggleValue = "ACT 1"
			end
			envelopeStateChunk = string.gsub(envelopeStateChunk, "ACT 0", toggleValue )
			reaper.SetToggleCommandState( sectionID, cmdID, 1 )
			reaper.SetToggleCommandState( 32060,  reaper.NamedCommandLookup( commandName ), 1 )
		end
		
		reaper.SetEnvelopeStateChunk( evenlope, envelopeStateChunk, true )
	end
end


reaper.Undo_EndBlock("Enable/Disable CC envelopes", 1)
reaper.PreventUIRefresh(-1)
