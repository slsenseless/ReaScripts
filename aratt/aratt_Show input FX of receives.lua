-- @noindex
reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local vsti = reaper.GetSelectedTrack( 0, 0 )
local tracks = {}

for i=0,reaper.GetTrackNumSends( vsti, -1 ) - 1 do
	table.insert(tracks,reaper.BR_GetMediaTrackSendInfo_Track( vsti, -1, i, 0 ))
end

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track

for key,track in pairs(tracks) do
	reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
	reaper.SetTrackSelected( track, true )
	reaper.Main_OnCommand( 40914, 0 ) -- Set first selected track to last touch track
	reaper.Main_OnCommand( 40844, 0 ) -- View input fx chain on last touch track
end

reaper.Main_OnCommand( 40297, 0 ) -- Unselect all track
reaper.SetTrackSelected( vsti, true )

reaper.Undo_EndBlock("Show input FX of receives", 1)
reaper.PreventUIRefresh(-1)
