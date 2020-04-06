-- @noindex
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
reaper.Main_OnCommand( reaper.NamedCommandLookup( "_SWS_SELTRKWITEM" ), 0 ) -- Select only track with selected items

local vsti = {}
local track = nil

for i=0,reaper.CountSelectedTracks( 0 ) - 1 do
	track = reaper.GetSelectedTrack( 0, i )
	for j=0,reaper.GetTrackNumSends( track, 0 ) - 1 do
		table.insert(vsti,reaper.BR_GetMediaTrackSendInfo_Track( track, 0, j, 1 ))
	end
end

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track

for key,track in pairs(vsti) do
	reaper.SetTrackSelected( track, true )
end

reaper.Main_OnCommand( reaper.NamedCommandLookup( "_S&M_TOGLFXCHAIN" ), 0 ) -- Toggle show fx chain window for selected tracks

reaper.Undo_EndBlock("Show FX of Vsti", 1)
reaper.PreventUIRefresh(-1)
