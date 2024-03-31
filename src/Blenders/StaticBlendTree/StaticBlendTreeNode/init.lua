--!strict
local StaticBlendParams = require(script.Parent.StaticBlendParams)

local Handler = {}
Handler.__index = Handler

--// TYPES
type StaticBlendParams = StaticBlendParams.StaticBlendParams
export type StaticBlendTreeNode = typeof(setmetatable({},Handler)) & typeof(Handler) & {
	BlendParams : StaticBlendParams,
	BlendWeight : number
}
--// END TYPES

function Handler.new(NodeBlendParams : StaticBlendParams)
	local self : StaticBlendTreeNode = setmetatable({},Handler) :: StaticBlendTreeNode
	
	self.BlendParams = NodeBlendParams
	self.BlendWeight = 0

	return self
end

function Handler.GetBlendedPose(self : StaticBlendTreeNode,BlendingPoses : {Poses : {Pose}, PoseWeights : {number}})
	
end

function Handler.SetBlendWeight(self : StaticBlendTreeNode,Weight : number)
	self.BlendWeight = Weight
end

return Handler