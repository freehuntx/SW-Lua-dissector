-- This lua scripts initializes all wished dissectors
CURRENT_DiR = "E:/Bibliotheken/Desktop/sw_packetstuff/wireshark" -- The path, where the current lua file lays
package.prepend_path(CURRENT_DiR..'/lib') -- This will make add lib folder to require logic

function load_dissector(file)
	do
		PWD = file:match('^(.+)[/\\][^/\\]+$') -- This way the dissector can get its own working dir
		return dofile(file)
	end
end

load_dissector(CURRENT_DiR.."/sw_dissector.lua")
load_dissector(CURRENT_DiR.."/sw_c2_dissector.lua")
load_dissector(CURRENT_DiR.."/sw_chat_dissector.lua")