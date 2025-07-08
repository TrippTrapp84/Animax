local RunService = game:GetService("RunService")

local Core = script.Parent.Parent
local Util = Core.Parent.Util
local UIDGenerator = require(Util.UIDGenerator)
local ANMXAnimationTrack = require(Core.Tracks.AnimationTrack)
local ANMXKinematicTrack = require(Core.Tracks.KinematicTrack)
local ANMXLegacyAnimationBlender = require(Core.Blenders.LegacyBlender)

local Handler = {}
Handler.__index = Handler

function Handler.new(RigRoot : BasePart,OrientationBlendType)
	local self = setmetatable({},Handler)

	self.Animations = {}
	self.PlayingAnimations = {}
	self.OrientationBlendType = OrientationBlendType or "ShortestDirection"
	self.AnimationIdGenerator = UIDGenerator.new()
	self.AnimationBlender = ANMXLegacyAnimationBlender.new()
	self.Root = RigRoot

	self.Connections = {}

	if RunService:IsServer() then
		table.insert(self.Connections, RunService.Stepped:Connect(function(time, deltaTime)
			self:_Update(deltaTime)
		end))
	else
		table.insert(self.Connections, RunService.RenderStepped:Connect(function(deltaTime)
			self:_Update(deltaTime)
		end))
	end

	return self
end

function Handler:LoadAnimation(AnimationId : string)
	local Track = ANMXAnimationTrack.new(self.Root, AnimationId)
	self:_LoadAnimationTrack(Track)

	return Track
end

function Handler:LoadKinematicAnimation(AnimationId : string)
	local Track = ANMXKinematicTrack.new(self.Root, AnimationId)
	self:_LoadAnimationTrack(Track)

	return Track
end

function Handler:_LoadAnimationTrack(Track)
	Track.OnPlay:Connect(function()
		self.AnimationBlender:AddAnimation(Track, self.OrientationBlendType)
	end)
	
	table.insert(self.Animations,self.AnimationIdGenerator:GetNextId(), Track)
end

function Handler:_RenderRigPoses(Poses : {[Bone] : CFrame})
	for Bone : Bone,BoneCFrame : CFrame in pairs(Poses) do
		Bone.Transform = BoneCFrame
	end
end

function Handler:_Update(DeltaTime : number)
	local Poses = self.AnimationBlender:RenderAnimations(DeltaTime)
	self:_RenderRigPoses(Poses)
end

return Handler