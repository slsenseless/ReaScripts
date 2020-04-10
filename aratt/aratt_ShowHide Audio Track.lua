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

local numTracks = reaper.CountTracks( 0 )
local i = 0
local show = nil

for i=0,numTracks - 1 do
	local track = reaper.GetTrack( 0, i )
	if aratt.isAudioTrack(track) or aratt.isFxTrack(track) then
		if show == nil then
			if reaper.GetMediaTrackInfo_Value( track, "B_SHOWINTCP" ) == 0 then
				show = true
			else
				show = false
			end
		end
		if show then
			reaper.SetMediaTrackInfo_Value( track, "B_SHOWINTCP", 1 )
		else
			reaper.SetMediaTrackInfo_Value( track, "B_SHOWINTCP", 0 )
		end
	end
end

-- Force refresh UI (If anyone got a better solution...)
reaper.InsertTrackAtIndex(0, true)
reaper.DeleteTrack( reaper.GetTrack( 0, 0 ) )


reaper.Undo_EndBlock("Show or Hide Audio tracks in panel", 1)
reaper.PreventUIRefresh(-1)