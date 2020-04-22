-- Variable
local amount = 1.7 -- Amount of zooming (1.7 ~default)
local zoomTime = 0.15 -- Total time of zoom in seconds (Theoretical, mesure and set approxZoomTime so it will be more accruate)
local smoothness = 10 -- Higher is more smooth, 1 = no transition
local direction = 1 -- 1: scroll up = zoom in / scroll down = zoom out, -1 reversed
--
local approxZoomTime = 0.008 -- Time that "adjustZoom" take, you can mesure yours by puting smoothness to 1 and uncommenting the two line in the for loop
--

reaper.Undo_BeginBlock()

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

local _,_,_,_,_,_,val = reaper.get_action_context()
if val < 0 then
	direction = -direction
end

local i=0
local amountStep = direction*(amount / smoothness)
local zoomTimeStep = (zoomTime / smoothness) - approxZoomTime

for i=1,smoothness do
	-- local ts = clock()
	reaper.adjustZoom(amountStep, 0, true, -1)
	-- reaper.ShowConsoleMsg(tostring(clock() - ts).."\r\n")
	sleep(zoomTimeStep)
end

reaper.Undo_EndBlock("Smooth horizontal zoom", 1)
