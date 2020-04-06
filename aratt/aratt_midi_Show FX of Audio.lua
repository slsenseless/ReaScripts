-- @noindex
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
reaper.Main_OnCommand( reaper.NamedCommandLookup( "_SWS_SELTRKWITEM" ), 0 ) -- Select only track with selected items

parents = {}
local track = nil
for i=0,reaper.CountSelectedTracks( 0 ) - 1 do
	track = reaper.GetSelectedTrack( 0, i )
	table.insert(parents,reaper.GetParentTrack( track ))
end

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track

for key,track in pairs(parents) do
	reaper.SetTrackSelected( track, true )
end

reaper.Main_OnCommand( reaper.NamedCommandLookup( "_S&M_TOGLFXCHAIN" ), 0 ) -- Toggle show fx chain window for selected tracks

reaper.Undo_EndBlock("Show FX of Audio", 1)
reaper.PreventUIRefresh(-1)
