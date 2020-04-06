-- @noindex
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local vsti = reaper.GetSelectedTrack( 0, 0 )
local tracks = {}

for i=0,reaper.GetTrackNumSends( vsti, 0 ) - 1 do
	table.insert(tracks,reaper.BR_GetMediaTrackSendInfo_Track( vsti, 0, i, 1 ))
end

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track

for key,track in pairs(tracks) do
	reaper.SetTrackSelected( track, true )
end

reaper.Main_OnCommand( reaper.NamedCommandLookup( "_S&M_TOGLFXCHAIN" ), 0 ) -- Toggle show fx chain window for selected tracks

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
reaper.SetTrackSelected( vsti, true )

reaper.Undo_EndBlock("Show FX of sends", 1)
reaper.PreventUIRefresh(-1)
