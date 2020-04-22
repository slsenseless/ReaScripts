-- @noindex

-- Optional if ccec_core is in reaper lua folder
local script_path = debug.getinfo(1,'S').source:sub(2,-5) -- remove "@" and "file extension" from file name
if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
  package.path = package.path .. ";" .. script_path:match("(.*".."\\"..")") .. "?.lua"
else
  package.path = package.path .. ";" .. script_path:match("(.*".."/"..")") .. "?.lua"
end
--

local ccec = require("ccec_core")

local retVal, _, fxData, paramNumber = reaper.GetLastTouchedFX()

if not retVal then
    reaper.ShowMessageBox("Please, select an fx parameter", "No fx parameter", 0)
    return 1
end

local mediaItem = reaper.GetSelectedMediaItem(0, 0)
local track = reaper.GetMediaItem_Track(mediaItem)
if mediaItem == nil then
    reaper.ShowMessageBox("Please, select a MIDI item", "No MIDI item", 0)
    return 1
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()

local mediaItemTake = reaper.GetActiveTake(mediaItem)

-- Get selected CC number
local _, _, ccCount, _ = reaper.MIDI_CountEvts(mediaItemTake)
local i = 0
local ccNum = nil
local lookNextByte = false
local ccNumFB = nil -- CC number of first byte discovered
local ppqposFB = nil -- ppqpos of first byte discovered
for i = 0,ccCount - 1 do
	_, selected, _, ppqpos, _, _, ccNum, _ = reaper.MIDI_GetCC( mediaItemTake, i )
	if not lookNextByte and selected then
		ccNumFB = ccNum
		ppqposFB = ppqpos
		lookNextByte = true
	elseif lookNextByte and ppqpos == ppqposFB then -- Looking for second byte
		if ccNum == ccNumFB + 32 then
			ccNum = ccNumFB + 128 -- First byte was MSB, second LSB
			break
		elseif ccNum == ccNumFB - 32 then
			ccNum = ccNum + 128 -- First byte was LSB, second MSB
			break
		end
	elseif lookNextByte then -- No second byte found
		ccNum = ccNumFB
		break
	end
end

if not ccec.AddLearnParam(track, fxData, paramNumber, ccNum) then
    reaper.ShowMessageBox("Chunk error", "Chunk error", 0)
end

reaper.Undo_EndBlock("Link last touched FX with selected CC points", 0)
reaper.PreventUIRefresh(-1)
