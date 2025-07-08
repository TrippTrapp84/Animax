local LegacyBlender = require(script.LegacyBlender)

local Handler = {}

function Handler.MakeLegacyBlender()
	return LegacyBlender.new()
end

return Handler