-- Variable
local amount = 160 -- Amount of zooming (/!\ Integer, must be greater than smoothness)
local zoomTime = 0.2 -- Total time of zoom in seconds (Theoretical, mesure and set approxZoomTime so it will be more accruate)
local smoothness = 10 -- Higher is more smooth, 1 = no transition
local direction = 1 -- 1: scroll up = go left / scroll down = go right, -1 reversed
--
local approxZoomTime = 0.008 -- Time that "adjustZoom" take, you can mesure yours by puting smoothness to 1 and uncommenting the two line in the for loop
--

local scrollbar = "HORZ"
-- local window = reaper.GetMainHwnd()
-- local window = reaper.JS_Window_GetFocus()
local window = reaper.BR_Win32_GetFocus()

reaper.Undo_BeginBlock()

local clock = os.clock
function sleep(n)  -- seconds
	local t0 = clock()
	while clock() - t0 <= n do end
end

_,_,_,_,_,_,val = reaper.get_action_context()
if val >= 0 then
	direction = -direction
end

local retval, position, pageSize, minval, maxval, trackPos = reaper.JS_Window_GetScrollInfo(window, scrollbar)
 
local i=0
local amountStep = math.floor(amount / smoothness)*direction
local zoomTimeStep = (zoomTime / smoothness) - approxZoomTime

for i=1,smoothness do
	-- local ts = clock()
	position = position - amountStep
	reaper.JS_Window_SetScrollPos( window, scrollbar, position )
	-- reaper.ShowConsoleMsg(tostring(clock() - ts).."\r\n")
	sleep(zoomTimeStep)
end

reaper.Undo_EndBlock("Smooth horizontal scroll", 1)
