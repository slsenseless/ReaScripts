-- @noindex
local vsti_name = true -- false : Default name (aratt.midiName) ; true : Vsti name

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

local track_name = nil
if vsti_name then
	track_name = aratt.GetVstiName(vstiTrack)
end

local midiTrack = aratt.CreateMidiTrack(nil,nil,track_name)

if aratt.AutomaticRouting({midiTrack,vstiTrack}) < 0 then
	reaper.DeleteTrack( midiTrack )
	reaper.ShowMessageBox( "Routing failed", "Routing error", 0 )
	return -1
end

reaper.Undo_EndBlock("Midi Track created and routed to Vsti", 1)
reaper.PreventUIRefresh(-1)