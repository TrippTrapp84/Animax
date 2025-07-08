--!nonstrict
--!nolint
local RunService = game:GetService("RunService")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local Util = script.Parent.Parent.Parent.Util
local Types = script.Parent.Parent.Parent.Types
local Kinematics = script.Parent
local Constraints = script.Parent.Parent.Kinematics.Constraints

local UIDGenerator = require(Util.UIDGenerator)
local Event = require(Util.Event)
local Gizmo = require(Util.Gizmo)
local LengthConstraint = require(Constraints.LengthConstraint)
local EndEffectorConstraint = require(Constraints.EndEffectorConstraint)
local KinematicsTypes = require(Types.Kinematics)
local BaseTrack = require(script.Parent.Base)

type KinematicBoneData = KinematicsTypes.KinematicBoneData

--// IMPORTANT: This map MUST stay in the order it appears in. The index of each constraint maps to the constraint data for a kinemati track
--// If you need to add a new constraint, add it to the end of the list
local ConstraintIDMap = {
	require(Constraints.LengthConstraint),
	require(Constraints.EndEffectorConstraint)
}

-- type AnimTrack = {
--     GetBoneWeight: (self: ANMXAnimationTrack, Bone: Bone) -> number,

--     GetRigTimeline: (self: ANMXAnimationTrack) -> {},
--     GetAnimationPoses: (self: ANMXAnimationTrack) -> {[Bone]: CFrame}
-- }

local Handler = setmetatable({}, BaseTrack)
Handler.__index = Handler

function Handler.new(Root: BasePart, AnimationId: string)
    local self = setmetatable(BaseTrack.new(Root, AnimationId), Handler)

	self.RigTimeline = {}
	self.Constraints = {}
	self.SolveResolution = 6
	self.CurrentPose = 0

	self.OnPlay:Connect(function()
		self:_RecalculateCurrentPoseIndex()
	end)

	self.OnStop:Connect(function()
		self:_RecalculateCurrentPoseIndex()
	end)

	self.OnTimePositionChanged:Connect(function()
		self:_RecalculateCurrentPoseIndex()
	end)

	self.OnLooped:Connect(function()
		self:_RecalculateCurrentPoseIndex()
	end)

	self.OnStep:Connect(function()
		self:Solve()
	end)

	self:_LoadKinematicsData()

    return self
end

function Handler:Solve()
	self._SolveData = {
		[self.Root] = {
			Transform = CFrame.new(),
			Bone = self.Root,
			WorldCFrame = self.Root.CFrame
		}
	}

	for i,v: Bone in pairs(self.Root:GetDescendants()) do
		if not v:IsA("Bone") then continue end
		self._SolveData[v] = {
			Transform = v.Transform,
			Bone = v,
			WorldCFrame = v.WorldCFrame
		}
	end

	for i = 1,self.SolveResolution do
		self:_SolveBackward()
		self:_SolveForward()

		for _,v in pairs(self._SolveData) do
			if v.Bone == self.Root then continue end
			
			v.WorldCFrame = self:_CalculateSolveDataWorldCFrame(v.Bone) * v.Transform:Inverse()
		end
	end
end

function Handler:_SolveForward()
	for i,v in pairs(self.Root:GetChildren()) do
		if not v:IsA("Bone") then continue end

		self:_SolveForwardRecurse(self.Root,v)
	end
end

function Handler:_SolveForwardRecurse(Bone0: BasePart | Bone, Bone1: Bone)
	local Bone0Data = self._SolveData[Bone0]
	local Bone1Data = self._SolveData[Bone1]

	for i,v in pairs(self.Constraints[Bone1]) do
		local Result = v:SolveForward(Bone0Data, Bone1Data)
		if not Result then continue end

		local ControlType = v:GetControlType()
		if ControlType == "Position" then
			Bone1Data.Transform = Bone1Data.Transform.Rotation + Result.Position
		elseif ControlType == "Rotation" then
			Bone1Data.Transform = Result.Rotation + Bone1Data.Transform.Position
		elseif ControlType == "Transform" then
			Bone1Data.Transform = Result
		end
	end

	for i,v in pairs(Bone1:GetChildren()) do
		if not v:IsA("Bone") then continue end

		self:_SolveForwardRecurse(Bone1, v)
	end
end

function Handler:_SolveBackward()
	for i,v in pairs(self.Root:GetChildren()) do
		if not v:IsA("Bone") then continue end

		self:_SolveBackwardRecurse(v)
	end

	-- Gizmo.setColor(Color3.new(1,0,0))
	-- for i,v in pairs(self._SolveData) do
	-- 	if i == self.Root then continue end
	-- 	Gizmo.drawSphere(v.Bone.WorldCFrame * v.Transform,1)
	-- end

	-- Gizmo.setColor(Color3.new(1,1,1))
end

function Handler:_SolveBackwardRecurse(Bone0: BasePart | Bone)
	local Targets = {}
	for i,v in pairs(Bone0:GetChildren()) do
		if not v:IsA("Bone") then continue end

		self:_SolveBackwardRecurse(v)
		table.insert(Targets,self._SolveData[v])
	end
	
	local Bone0Data = self._SolveData[Bone0]

	for i,v in pairs(self.Constraints[Bone0]) do
		local Result = v:SolveBackward(Bone0Data, Targets)
		if not Result then continue end
		
		local PreviousTransformCF = Bone0Data.Bone.CFrame:ToWorldSpace(Bone0Data.Transform)

		local ControlType = v:GetControlType()
		if ControlType == "Position" then
			Bone0Data.Transform = Bone0Data.Transform.Rotation + Result.Position
		elseif ControlType == "Rotation" then
			Bone0Data.Transform = Result.Rotation + Bone0Data.Transform.Position
		elseif ControlType == "Transform" then
			Bone0Data.Transform = Result
		end

		local CurrentTransformCF = Bone0Data.Bone.CFrame:ToWorldSpace(Bone0Data.Transform)
		for _,BoneData in pairs(Targets) do
			local TargetTransformCF = BoneData.Bone.CFrame:ToWorldSpace(BoneData.Transform)	

			local CurrentRelativeCF = CurrentTransformCF:ToWorldSpace(BoneData.Bone.CFrame)
			local PreviousRelativeTransformCF = PreviousTransformCF:ToWorldSpace(TargetTransformCF)

			BoneData.Transform = CurrentRelativeCF:ToObjectSpace(PreviousRelativeTransformCF)
		end
	end
end

function Handler:_LoadKinematicsData()
    -- for i,v in pairs(self.Root:GetDescendants()) do
	-- 	if not v:IsA("Bone") then continue end

	-- 	local Children = v:GetChildren()
	-- 	for ind = #Children,1,-1 do
	-- 		if not Children[ind]:IsA("Bone") then table.remove(Children,ind) end
	-- 	end
		
	-- 	self.Constraints[v] = {			
	-- 		LengthConstraint.new(v.Parent, v, Children)
	-- 	}

	-- 	if #Children == 0 then
	-- 		table.insert(self.Constraints[v], 1, EndEffectorConstraint.new(v.Parent,v,Children))
	-- 	end
    -- end

	for i,v: Keyframe in pairs(self.Keyframes) do
		if v.Time >= 0 then
			self:_LoadRigTimelineKeyframe(v)
		else
			self:_LoadConstraintKeyframe(v)
		end
	end
end

function Handler:_LoadRigTimelineKeyframe(Keyframe: Keyframe)
	for i,v: Pose in pairs((Keyframe:GetPoses() :: never) :: {Pose}) do
		local Bone = self.Root:FindFirstChild(v.Name)
		if not Bone then continue end
		if not Bone:IsA("Bone") then continue end

		self:_LoadRigTimelinePose(Bone,v, Keyframe.Time)
	end
end

function Handler:_LoadRigTimelinePose(Bone: Bone, Pose: Pose, Time: number)
	if not self.RigTimeline[Bone] then
		self.RigTimeline[Bone] = {
			Bone = Bone,
			Poses = {
				{
					Pose = Pose,
					Time = Time
				}
			},
			CurrentPose = 0
		}
	else
		table.insert(self.RigTimeline[Bone].Poses, {
			Pose = Pose,
			Time = Time
		})
	end

	for _,SubPose : Pose in pairs((Pose:GetSubPoses() :: never) :: {Pose}) do
		local SubBone = Bone:FindFirstChild(SubPose.Name)
		if not SubBone then continue end
		if not SubBone:IsA("Bone") then continue end

		self:_LoadRigTimelinePose(SubBone, SubPose, Time)
	end
end

function Handler:_LoadConstraintKeyframe(Keyframe: Keyframe)
	for i,v: Pose in pairs((Keyframe:GetPoses() :: never) :: {Pose}) do
		self:_LoadConstraintPose(self.Root,v)
	end
end

function Handler:_LoadConstraintPose(Parent: Bone | BasePart,Pose: Pose)
	local Bone = Parent:FindFirstChild(Pose.Name)
	if not Bone then return end

	if Pose.Weight == 1 then
		self:_LoadConstraint(Bone,Pose)
	end
	
	for i,v in pairs((Pose:GetSubPoses() :: never) :: {Pose}) do
		self:_LoadConstraintPose(Bone,v)
	end
end

function Handler:_LoadConstraint(Bone: Bone, Pose: Pose)
	local ID = math.round(Pose.CFrame.Position.X)

	local Constraint = ConstraintIDMap[ID]
	if not Constraint then return end

	local Children = Bone:GetChildren()
	for i = #Children,1,-1 do
		if not Children[i]:IsA("Bone") then table.remove(Children,i) end
	end

	local Constraints = self.Constraints[Bone] or {}
	table.insert(Constraints, Constraint.new(Bone.Parent, Bone, Children))
	self.Constraints[Bone] = Constraints
end

function Handler:_CalculateSolveDataWorldCFrame(Bone: Bone): CFrame
	local BoneData = self._SolveData[Bone]
	if not BoneData then return Bone.TransformedWorldCFrame end

	local Parent = Bone.Parent
	if Parent:IsA("Bone") then
		local ParentCF = self:_CalculateSolveDataWorldCFrame(Parent)
		return ParentCF * Bone.CFrame * BoneData.Transform
	else
		return Parent.CFrame * Bone.CFrame * BoneData.Transform
	end
end

function Handler:_RecalculateCurrentPoseIndex()
	for Bone : Bone,BoneTimelineData in pairs(self.RigTimeline) do
		for PoseNumber : number, PoseData in pairs(BoneTimelineData.Poses) do
			if self.TimePosition >= PoseData.Time then
				BoneTimelineData.CurrentPose = PoseNumber
			else
				BoneTimelineData.CurrentPose = PoseNumber-1
				break
			end
		end
	end
end

function Handler:GetRigTimeline()
	return self.RigTimeline
end

function Handler:GetBoneWeight(Bone : Bone)
	local BoneData = self.RigTimeline[Bone]
	if not BoneData then return 0 end
	local CurrentPose = BoneData.Poses[BoneData.CurrentPose]
	if not CurrentPose then return 0 end
	return CurrentPose.Pose.Weight
end

function Handler:GetAnimationPoses() : {[Bone] : CFrame}
	local PoseCFrames : {[Bone] : CFrame} = {}
	for Bone: Bone, BoneData: KinematicBoneData in pairs(self._SolveData) do
		PoseCFrames[Bone] = BoneData.Transform
	end

	return PoseCFrames
end

return Handler