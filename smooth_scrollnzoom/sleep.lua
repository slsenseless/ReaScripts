-- Variables
local sleepTime = 0.01
--

if reaper.GetPlayState() == 1 and reaper.MIDIEditor_GetActive() ~= nil then -- Play cursor doesnt refresh in midi editor :(
	return 0
end

local clock = os.clock
function sleep(n)  -- seconds
  local t0 = clock()
  while clock() - t0 <= n do end
end

sleep(sleepTime)

if reaper.MIDIEditor_GetActive() ~= nil then
	reaper.JS_Window_Update(reaper.MIDIEditor_GetActive())
end
