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

local i = 0
for i=0,reaper.CountSelectedTracks( 0 ) - 1 do
	ccec.UpdateEnvelope(reaper.GetSelectedTrack( 0, i ))
end

reaper.Undo_EndBlock("Update envelopes CC", 1)
reaper.PreventUIRefresh(-1)
