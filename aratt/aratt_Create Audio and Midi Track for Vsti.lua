-- @noindex
local midiInAudioTrack = true
local random_color = true
local vsti_name = true -- false : Default name (aratt.audioName) ; true : Vsti name
local input_name = true -- Show dialogue box to enter names (if vsti_name true, default name will be vsti name)

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

if reaper.CountSelectedTracks(0) ~= 1 then
	reaper.ShowMessageBox( "Please select one vsti track", "Selection error", 0 )
	return -1
end

local vstiTrack =  reaper.GetSelectedTrack( 0, 0 )
if not aratt.isVstiTrack(vstiTrack) then
	reaper.ShowMessageBox( "Please select one vsti track", "Selection error", 0 )
	return -1
end

local pos = aratt.GetInsertionPoint()
local audioDepth = 1
local midiDepth = -1
if not midiInAudioTrack then
	audioDepth = 0
	midiDepth = 0
end

local track_name = nil
if vsti_name then
	track_name = aratt.GetVstiName(vstiTrack)
end

if input_name then
	retval, retvals_csv = reaper.GetUserInputs( "Name of the instrument", 1, "Name :;extrawidth=50", track_name )
	if not retval then
		return -1
	else
		track_name = retvals_csv
	end
	 
end

local audioTrack = aratt.CreateAudioTrack(pos, audioDepth,track_name)
local midiTrack = aratt.CreateMidiTrack(pos + 1, midiDepth,track_name)

if aratt.AutomaticRouting({audioTrack,midiTrack,vstiTrack}) < 0 then
	reaper.DeleteTrack( audioTrack )
	reaper.DeleteTrack( midiTrack )
	reaper.ShowMessageBox( "Routing failed", "Routing error", 0 )
	return -1
end

local vstiTrack =  reaper.GetSelectedTrack(0, 0)
reaper.SetTrackSelected( audioTrack, true )
reaper.SetTrackSelected( midiTrack, true )

if random_color then
	reaper.SetTrackSelected( vstiTrack, false )
	reaper.Main_OnCommand( 40360, 0 ) -- Put one random color
	reaper.SetTrackSelected( vstiTrack, true )
end

reaper.SetTrackSelected( audioTrack, false )
reaper.SetTrackSelected( midiTrack, false )


reaper.Undo_EndBlock("Audio and Midi Tracks created and routed to Vsti", 1)
reaper.PreventUIRefresh(-1)