-- @noindex
local midiInAudioTrack = true
local random_color = true

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

local pos = aratt.GetInsertionPoint()
local audioDepth = 1
local midiDepth = -1
if not midiInAudioTrack then
	audioDepth = 0
	midiDepth = 0
end

local audioTrack = aratt.CreateAudioTrack(pos, audioDepth)
local midiTrack = aratt.CreateMidiTrack(pos + 1, midiDepth)

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
reaper.SetTrackSelected( audioTrack, true )
reaper.SetTrackSelected( midiTrack, true )

if random_color then
	reaper.Main_OnCommand( 40360, 0 ) -- Put one random color
end

reaper.Undo_EndBlock("Audio and Midi Tracks created", 1)
reaper.PreventUIRefresh(-1)
