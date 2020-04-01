-- @noindex
midiPriority = true -- route midi if it's the next track

-- Optional if aratt_core is in reaper lua folder
local script_path = debug.getinfo(1,'S').source:sub(2,-5) -- remove "@" and "file extension" from file name
if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
  package.path = package.path .. ";" .. script_path:match("(.*".."\\"..")") .. "?.lua"
else
  package.path = package.path .. ";" .. script_path:match("(.*".."/"..")") .. "?.lua"
end
--

local aratt = require("aratt_core")

if aratt == nil then
	reaper.ShowConsoleMsg("Aratt core not loaded")
	return -1
end

--reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local numTracks = reaper.CountSelectedTracks(0)
local i = 0
local tracks = {}
for i=0,numTracks - 1 do
	table.insert(tracks, reaper.GetSelectedTrack( 0, i ))
end

aratt.AssistedRouting(tracks, midiPriority)

reaper.Undo_EndBlock("Assisted routing done", 1)
--reaper.PreventUIRefresh(-1)
