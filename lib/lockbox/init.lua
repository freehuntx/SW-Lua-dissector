local Lockbox = {};

--[[
package.path =  "./?.lua;"
				.. "./cipher/?.lua;"
				.. "./digest/?.lua;"
				.. "./kdf/?.lua;"
				.. "./mac/?.lua;"
				.. "./padding/?.lua;"
				.. "./test/?.lua;"
				.. "./util/?.lua;"
				.. package.path;
]]--
Lockbox.ALLOW_INSECURE = false;

Lockbox.insecure = function()
	return true
end

return Lockbox;
