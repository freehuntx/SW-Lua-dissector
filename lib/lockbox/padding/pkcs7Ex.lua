local Array = require("lockbox.util.array");

local M = {}

function M.parse(buffer)
	if buffer == nil then return nil end
	
	local last_val = nil
	local last_val_count = 0
	for i = #buffer, 1, -1 do
		local element = buffer[i]
		
		if last_val == nil then
			last_val = element
			last_val_count = 1
		else
			if element == last_val then
				last_val_count = last_val_count + 1
			end
			
			if last_val == last_val_count then
				buffer = Array.truncate(buffer, #buffer-last_val)
				break
			end
		end
	end

	return buffer
end

return M
