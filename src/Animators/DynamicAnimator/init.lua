---!strict
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local UIDGenerator = require(script.Parent.Parent.Util.UIDGenerator)
local ANMXAnimationTrack = require(script.Parent.Parent.AnimationTrack)
local ANMXLegacyAnimationBlender = require(script.Parent.Parent.Blenders.LegacyBlender)
local ANMXBlendEnums = require(script.Parent.Parent.Blenders.BlendEnums)

local Handler = {}
Handler.__index = Handler

--// TYPES
type UIDGenerator = UIDGenerator.UIDGenerator

type ANMXAnimationTrack = ANMXAnimationTrack.ANMXAnimationTrack
type ANMXLegacyAnimationBlender = ANMXLegacyAnimationBlender.ANMXLegacyAnimationBlender
type ANMXBlendType = ANMXBlendEnums.BlendType
type ANMXBlendOrientationType = ANMXBlendEnums.BlendOrientationType

export type AnimationStateData = {
	[string] : {
		StateName : string,
		StateAnimations : {[number] : ANMXAnimationTrack}

	}
}

export type ANMXAnimator = typeof(setmetatable({},Handler)) & typeof(Handler) & {
	Animations : {ANMXAnimationTrack},
	PlayingAnimations : {ANMXAnimationTrack},
	AnimationIdGenerator : UIDGenerator,
	Root : BasePart,
	OrientationBlendType : ANMXBlendOrientationType,
	Connections : {RBXScriptConnection},
	AnimationBlender : ANMXLegacyAnimationBlender --//TODO: Make base class type for all animation blenders
}
--// END TYPES

function Handler.new(RigRoot : BasePart,OrientationBlendType : ANMXBlendOrientationType?) : ANMXAnimator
	local self : ANMXAnimator = setmetatable({},Handler) :: ANMXAnimator

	self.Animations = {}
	self.PlayingAnimations = {}
	self.OrientationBlendType = OrientationBlendType or "ShortestDirection"
	self.AnimationIdGenerator = UIDGenerator.new()
	self.AnimationBlender = ANMXLegacyAnimationBlender.new()
	self.Root = RigRoot

	self.Connections = {} :: {RBXScriptConnection}

	if RunService:IsServer() then
		self.Connections[1] = RunService.Stepped:Connect(function(time, deltaTime)
			self:Update(deltaTime)
		end)
	else
		self.Connections[1] = RunService.RenderStepped:Connect(function(deltaTime)
			self:Update(deltaTime)
		end)
	end

	return self
end

function Handler.LoadAnimation(self : ANMXAnimator,AnimationId : string) : ANMXAnimationTrack
	local AnimTrack : ANMXAnimationTrack = ANMXAnimationTrack.new(self.Root,AnimationId)
	-- for i,v in pairs(AnimTrack:GetRigTimeline()) do
	-- 	i.CFrame = v.Poses[1].Pose.CFrame
	-- end
	AnimTrack.OnPlay:Connect(function()
		self.AnimationBlender:AddAnimation(AnimTrack,self.OrientationBlendType)
	end)
	
	self.Animations[self.AnimationIdGenerator:GetNextId()] = AnimTrack

	return AnimTrack
end

function Handler._RenderRigPoses(self : ANMXAnimator,Poses : {[Bone] : CFrame})
	for Bone : Bone,BoneCFrame : CFrame in pairs(Poses) do
		Bone.Transform = BoneCFrame
	end
end

function Handler.Update(self : ANMXAnimator,DeltaTime : number)
	local Poses = self.AnimationBlender:RenderAnimations(DeltaTime)
	self:_RenderRigPoses(Poses)
end

return Handler :: ANMXAnimator