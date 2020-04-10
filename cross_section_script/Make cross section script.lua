--@noindex
local pathToSave = "" -- Path to save relative to this script's path. /!\ put '/' at the end !

local script_path = debug.getinfo(1,'S').source:sub(2,-5) -- remove "@" and "file extension" from file name
if reaper.GetOS() == "Win64" or reaper.GetOS() == "Win32" then
  package.path = package.path .. ";" .. script_path:match("(.*".."\\"..")") .. "?.lua"
else
  package.path = package.path .. ";" .. script_path:match("(.*".."/"..")") .. "?.lua"
end
script_path = string.gsub(script_path, "\\", "/") -- replace '\' by '/'
script_path = string.gsub(script_path, "/[^/]*$", "") -- remove last '/' and after
script_path = script_path .. "/" .. pathToSave

-- Taken from lua-users.org
function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end
--

retval, retvals_csv = reaper.GetUserInputs( "Generate new cross-section script", 3, "Main/Media/Midi edit/evt/inline,Name :,Command ID :;extrawidth=400", "11111" )
if not retval then
	return -1
end

inputs = split(retvals_csv,',')

-- sectionID: Main=0, Main (alt recording)=100, Media Explorer=32063, MIDI Editor=32060, MIDI Event List Editor=32061, MIDI Inline Editor=32062
local addToTable = {0,32063,32060,32061,32062} -- 0 also put on alt. recording
local addToInput = table.remove(inputs,1)
local numRemoved = 0
for i=1,string.len(addToInput) do
	isAdded = string.sub(addToInput, i, i)
	if isAdded == "0" then
		table.remove(addToTable,i - numRemoved)
		numRemoved = numRemoved + 1
	end
end

local commandName = table.remove(inputs,1)
local mainCommand = true
local fileText = ""
local endl = "\r\n"
local input = ""
for key,input in pairs(inputs) do
	input = string.gsub(input, " ", "")
	local inputStart = string.lower(string.sub(input, 1, 1))
	if inputStart == "e" or string.lower(input) == "midi" then
		mainCommand = false
	elseif inputStart == "m" then
		mainCommand = true
	else
		local nextCommand = ""
		if inputStart == "_" then
			nextCommand = "commandId = reaper.NamedCommandLookup( \""..input.."\" )"..endl
		else
			nextCommand = "commandId = "..input..endl
		end
		if mainCommand then
			nextCommand = nextCommand.."reaper.Main_OnCommand( commandId, 0 )"..endl
		else
			nextCommand = nextCommand.."commandRet = reaper.MIDIEditor_LastFocused_OnCommand( commandId, false )"..endl
			nextCommand = nextCommand.."if commandRet == false then reaper.ShowMessageBox( \"Cant execute command\", \"No MIDI editor open\", 0 ) return 1 end"..endl
		end
		fileText = fileText..nextCommand
	end
end

fullScriptPath = script_path..commandName..".lua"
file = io.open(fullScriptPath, "w")
io.output(file)
io.write(fileText)
io.close(file)

for key,addTo in pairs(addToTable) do
	reaper.AddRemoveReaScript( true, addTo, fullScriptPath, true )
end
