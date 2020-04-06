-- @noindex
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
reaper.Main_OnCommand( reaper.NamedCommandLookup( "_SWS_SELTRKWITEM" ), 0 ) -- Select only track with selected items

tracks = {}
for i=0,reaper.CountSelectedTracks( 0 ) - 1 do
	table.insert(tracks,reaper.GetSelectedTrack( 0, i ))
end

for key,track in pairs(tracks) do
	reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
	reaper.SetTrackSelected( track, true )
	reaper.Main_OnCommand( 40914, 0 ) -- Set first selected track to last touch track
	reaper.Main_OnCommand( 40844, 0 ) -- View input fx chain on last touch track
end

reaper.Undo_EndBlock("Show input FX of Midi", 1)
reaper.PreventUIRefresh(-1)
