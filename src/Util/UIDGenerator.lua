---!strict
local Players = game:GetService("Players")
local Handler = {}
Handler.__index = Handler
Handler.NextId = 0

--// TYPES
export type UIDGenerator = typeof(setmetatable({},Handler)) & typeof(Handler) & {
	NextId : number
}
--// END TYPES

function Handler.new()
	local self : UIDGenerator = setmetatable({},Handler) :: UIDGenerator
	
	self.NextId = 1
	
	return self
end

function Handler.GetNextId(self : UIDGenerator)
	self.NextId += 1
	return self.NextId - 1
end

return Handler