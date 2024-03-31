--!strict
local Handler = {}
Handler.__index = Handler

--// TYPES
type OrientationTrackingType = "ShortestDirection" | "RememberFirstDirection"

export type StaticBlendParams = typeof(setmetatable({},Handler)) & {
	OrientationTrackingType : OrientationTrackingType
}

--//END TYPES	

function Handler.new() : StaticBlendParams
	local self : StaticBlendParams = setmetatable({},Handler) :: StaticBlendParams
	
	self.OrientationTrackingType = "ShortestDirection"
	
	return self
end

function Handler.SetOrientationTrackingType(self : StaticBlendParams, TrackingType : OrientationTrackingType) : ()
	self.OrientationTrackingType = TrackingType
end

return Handler