--!strict
local StaticBlendParams = require(script.StaticBlendParams)
local StaticBlendTreeNode = require(script.StaticBlendTreeNode)

local Handler = {}
Handler.__index = Handler

--// TYPES
type StaticBlendParams = StaticBlendParams.StaticBlendParams
type StaticBlendTreeNode = StaticBlendTreeNode.StaticBlendTreeNode
type StaticBlendTree = typeof(setmetatable({},Handler)) & typeof(Handler) & {
	BlendParams : StaticBlendParams,
	BlendLayers : {StaticBlendTreeNode},
	BlendAnimations : {Animation} --// TODO: Come back and replace with custom animation track
}
--// END TYPES

function Handler.new(TreeBlendParams : StaticBlendParams)
	local self : StaticBlendTree = setmetatable({},Handler) :: StaticBlendTree
	
	self.BlendParams = TreeBlendParams
	self.BlendLayers = {}
	
	return self
end

function Handler:GetBlendedPose()
	
end