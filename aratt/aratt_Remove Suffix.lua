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

for i=0,reaper.CountSelectedTracks(0)-1 do
	local track = reaper.GetSelectedTrack(0, i)
	local retval, retName = reaper.GetSetMediaTrackInfo_String( track, "P_NAME", "", false )
	reaper.GetSetMediaTrackInfo_String(track, "P_NAME", string.gsub(retName, " ?%(A?l?l?[0-9]*/?[0-9]*%)", ""), true)
end

reaper.Undo_EndBlock("Remove suffix done", 1)
reaper.PreventUIRefresh(-1)
