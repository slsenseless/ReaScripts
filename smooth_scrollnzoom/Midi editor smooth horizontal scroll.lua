-- Variable
local amount = 300 -- Amount of zooming (/!\ Integer, must be greater than smoothness)
local zoomTime = 0.1 -- Total time of zoom in seconds (Theoretical)
local smoothness = 10 -- Higher is more smooth, 1 = no transition
local direction = 1 -- 1: scroll up = go left / scroll down = go right, -1 reversed
--

local scrollbar = "HORZ"
local window = reaper.BR_Win32_GetFocus()

_,_,_,_,_,_,val = reaper.get_action_context()
if val < 0 then
	direction = -direction
end

local amountStep = math.floor(amount / smoothness)*direction
local zoomTimeStep = (zoomTime / smoothness)

local _, position, _, _, _, _ = reaper.JS_Window_GetScrollInfo(window, scrollbar)

timeStart = reaper.time_precise()

local function Main()

    local elapsed = reaper.time_precise() - timeStart

    if elapsed >= zoomTimeStep then
		timeStart = reaper.time_precise()
		position = position + amountStep
        reaper.JS_Window_SetScrollPos( window, scrollbar, position )
		smoothness = smoothness - 1
		if smoothness > 0 then
			Main()
		end
		return
    else
        reaper.defer(Main)
    end
    
end

Main()
