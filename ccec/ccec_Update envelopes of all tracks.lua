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

local i = 0
for i = 0, reaper.CountTracks( 0 ) - 1 do
	local track = reaper.GetTrack( 0, i )
	ccec.UpdateEnvelope(track)
end

reaper.Undo_EndBlock("Update envelopes of all tracks", 1)
reaper.PreventUIRefresh(-1)
