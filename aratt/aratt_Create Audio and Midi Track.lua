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
local midiTrackDepth = 0
local audioTrackDepth = 0
if midiInAudioTrack then
	midiTrackDepth = -1
	audioTrackDepth = 1
end

local midiTrack = aratt.CreateMidiTrack(pos)
local audioTrack = aratt.CreateAudioTrack(pos)

reaper.SetMediaTrackInfo_Value(audioTrack, "I_FOLDERDEPTH", audioTrackDepth)
reaper.SetMediaTrackInfo_Value(midiTrack, "I_FOLDERDEPTH", midiTrackDepth)

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track

reaper.SetTrackSelected( midiTrack, true )
reaper.SetTrackSelected( audioTrack, true )

if random_color then
	reaper.Main_OnCommand( 40360, 0 ) -- Put one random color
end

if aratt.midi.template ~= "" then -- Bug about midi template... Bug will occurs if we execute this script twice in a row without unselect tracks
	reaper.SetTrackSelected( midiTrack, false )
	reaper.SetTrackSelected( audioTrack, false )
end

reaper.Undo_EndBlock("Audio and Midi Tracks created", 1)
reaper.PreventUIRefresh(-1)
