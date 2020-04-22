-- Variable
local amount = 5 -- Amount of zooming (/!\ Integer)
local zoomTime = 0.15 -- Total time of zoom in seconds (Theoretical, mesure and set approxZoomTime so it will be more accruate)
local direction = 1 -- 1: scroll up = zoom in / scroll down = zoom out, -1 reversed
--
local approxZoomTime = 0.01 -- Time that "CSurf_OnZoom" take, you can mesure yours by puting fluidity to 1 and uncommenting the two line in the for loop
--

reaper.Undo_BeginBlock()

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

local i=0
local zoomTimeStep = (zoomTime / amount) - approxZoomTime

local _,_,_,_,_,_,val = reaper.get_action_context()

if val < 0 then
	direction = -direction
end

for i=1,amount do
	-- local ts = clock()
	reaper.CSurf_OnZoom( 0, direction )
	-- reaper.ShowConsoleMsg(tostring(clock() - ts).."\r\n")
	sleep(zoomTimeStep)
end

reaper.Undo_EndBlock("Smooth vertical zoom", 1)

