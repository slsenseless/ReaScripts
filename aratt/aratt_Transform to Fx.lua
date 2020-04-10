-- @noindex
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

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local i = 0
for i=0,reaper.CountSelectedTracks(0) - 1 do
	aratt.TransformToFx(reaper.GetSelectedTrack( 0, i ))
end

reaper.Undo_EndBlock("Transformation to Folder done", 1)
reaper.PreventUIRefresh(-1)