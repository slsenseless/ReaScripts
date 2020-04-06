-- @noindex
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
reaper.Main_OnCommand( reaper.NamedCommandLookup( "_SWS_SELTRKWITEM" ), 0 ) -- Select only track with selected items
reaper.Main_OnCommand( reaper.NamedCommandLookup( "_S&M_TOGLFXCHAIN" ), 0 ) -- Toggle show fx chain window for selected tracks

reaper.Undo_EndBlock("Show FX of Midi", 1)
reaper.PreventUIRefresh(-1)
