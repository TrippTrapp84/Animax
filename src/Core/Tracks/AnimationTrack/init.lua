--!nocheck
--!nolint
local Util = script.Parent.Parent.Parent.Util

local EasingFunctions = require(Util.EasingFunctions)
local BaseTrack = require(script.Parent.Base)

local Handler = setmetatable({}, BaseTrack)
Handler.__index = Handler

function Handler.new(Root : BasePart,AnimationId : string)
	local self = setmetatable(BaseTrack.new(Root, AnimationId),Handler)

	self.RigTimeline = {}
	self.UseRotationTimeline = false
	self.RotationTimelineIncrement = 0.1
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
		for Bone : Bone,BoneTimelineData in pairs(self.RigTimeline) do
			if not BoneTimelineData.Poses[BoneTimelineData.CurrentPose + 1] then continue end
			if BoneTimelineData.Poses[BoneTimelineData.CurrentPose + 1].Time <= self.TimePosition then BoneTimelineData.CurrentPose += 1 end
		end
	end)
	
	self:_BuildRigTimeline(self.Keyframes)
	if self.UseRotationTimeline then
		self:_BuildRigRotationTimeline()
	end
	
	return self
end


function Handler:_BuildRotationTimelineForBone(Bone : Bone,BonePoseData)
	local X,Y,Z = 0,0,0
	local SimTime = 0
	local CurrentPose = 1
	local FullTime = BonePoseData.Poses[#BonePoseData.Poses].Time
	local Xc,Yc,Zc = BonePoseData.Poses[1].Pose.CFrame:ToOrientation()
	local RotationTimelineIndex = 1
	while SimTime < FullTime do
		SimTime += self.RotationTimelineIncrement
		if BonePoseData.Poses[CurrentPose].Time < SimTime then
			CurrentPose += 1
			if CurrentPose == #BonePoseData.Poses then break end
		end

		local StartPose = BonePoseData.Poses[CurrentPose]
		local EndPose = BonePoseData.Poses[CurrentPose + 1]
		local SimTimeCF = EasingFunctions[StartPose.Pose.EasingDirection][StartPose.Pose.EasingStyle](
			StartPose.Pose.CFrame,
			EndPose.Pose.CFrame,
			SimTime - StartPose.Time,
			EndPose.Time - StartPose.Time
		)
		local STCFx,STCFy,STCFz = SimTimeCF:ToOrientation()
		local Xtemp,Ytemp,Ztemp = STCFx - Xc,STCFy - Yc,STCFz - Zc
		Xc = Xtemp
		Yc = Ytemp
		Zc = Ztemp
		
		X += Xtemp
		Y += Ytemp
		Z += Ztemp

		BonePoseData.RotationTimeline[RotationTimelineIndex] = Vector3.new(X,Y,Z)
		RotationTimelineIndex += 1
	end
end

function Handler:_BuildRigRotationTimeline()
	for Bone : Bone, BonePoseData in pairs(self.RigTimeline) do
		self:_BuildRotationTimelineForBone(Bone,BonePoseData)
	end
end

function Handler:_AddBoneToRigTimeline(Bone : Bone, Pose : Pose,Time : number)
	if not self.RigTimeline[Bone] then
		self.RigTimeline[Bone] = {
			Bone = Bone,
			Poses = {
				{
					Pose = Pose,
					Time = Time
				}
			},
			CurrentPose = 0,
			RotationTimeline = {}
		}
	else
		table.insert(self.RigTimeline[Bone].Poses, {
			Pose = Pose,
			Time = Time
		})
	end

	for _,SubPose : Pose in pairs((Pose:GetSubPoses() :: never) :: {Pose}) do
		self:_AddBoneToRigTimeline(Bone:FindFirstChild(SubPose.Name),SubPose,Time)
	end
end

function Handler:_AddKeyframeToRigTimeline(Keyframe : Keyframe)
	for _,Pose : Pose in pairs(((Keyframe:GetPoses()[1] :: Pose):GetSubPoses() :: never) :: {Pose}) do
		self:_AddBoneToRigTimeline(self.Root:FindFirstChild(Pose.Name) :: Bone,Pose,Keyframe.Time)
	end
end

function Handler:_BuildRigTimeline(Keyframes : {Keyframe})
	for _,Keyframe : Keyframe in pairs(Keyframes) do
		self:_AddKeyframeToRigTimeline(Keyframe)

	end
end

function Handler:GetRigTimeline()
	return self.RigTimeline
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

function Handler:GetBoneWeight(Bone : Bone)
	local BoneData = self.RigTimeline[Bone]
	if not BoneData then return 0 end
	local CurrentPose = BoneData.Poses[BoneData.CurrentPose]
	if not CurrentPose then return 0 end
	return CurrentPose.Pose.Weight
end

function Handler:ReadRotationTimelineAtTime(Time : number) : {[Bone] : Vector3}
	local RotationOffsets : {[Bone] : Vector3} = {}
	
	local RotationTimelineIndex = Time / self.RotationTimelineIncrement
	local RotationInterpolationAlpha = RotationTimelineIndex % 1
	RotationTimelineIndex = math.round(RotationTimelineIndex - RotationInterpolationAlpha)

	for Bone : Bone, BoneTimelineData in pairs(self.RigTimeline) do
		local RotationPoint1 = BoneTimelineData.RotationTimeline[RotationTimelineIndex]
		if not RotationPoint1 then RotationOffsets[Bone] = BoneTimelineData.RotationTimeline[#BoneTimelineData.RotationTimeline] continue end

		local RotationPoint2 = BoneTimelineData.RotationTimeline[RotationTimelineIndex + 1]
		if not RotationPoint2 then RotationOffsets[Bone] = RotationPoint1 continue end

		RotationOffsets[Bone] = RotationPoint1 * (1 - RotationInterpolationAlpha) + RotationPoint2 * (RotationInterpolationAlpha)
	end

	return RotationOffsets
end

function Handler:ReadRotationTimeline() : {[Bone] : Vector3}
	return self:ReadRotationTimelineAtTime(self.TimePosition)
end

function Handler:GetAnimationPosesAtTime(Time : number)
	local RigPoseNumbers : {[Bone] : number} = {}
	for Bone : Bone,PoseData in pairs(self.RigTimeline) do
		RigPoseNumbers[Bone] = 0
		for PoseNumber : number, PoseInfo in pairs(PoseData.Poses) do
			if PoseInfo.Time < Time then break end
			RigPoseNumbers[Bone] = PoseNumber
		end
	end
	
	local PoseCFrames : {[Bone] : CFrame} = {}
	for Bone : Bone,CurrentPose : number in pairs(RigPoseNumbers) do
		if CurrentPose < 1 then continue end
		if not self.RigTimeline[Bone].Poses[CurrentPose + 1] then PoseCFrames[Bone] = self.RigTimeline[Bone].Poses[CurrentPose].Pose.CFrame continue end
		local StartPose = self.RigTimeline[Bone].Poses[CurrentPose]
		local EndPose = self.RigTimeline[Bone].Poses[CurrentPose + 1]
		PoseCFrames[Bone] = EasingFunctions[StartPose.Pose.EasingDirection][StartPose.Pose.EasingStyle](
			StartPose.Pose.CFrame,
			EndPose.Pose.CFrame,
			Time - StartPose.Time,
			EndPose.Time - StartPose.Time
		)
	end
	
	return PoseCFrames
end

function Handler:GetAnimationPoses() : {[Bone] : CFrame}
	local PoseCFrames : {[Bone] : CFrame} = {}
	for Bone : Bone,PoseData in pairs(self.RigTimeline) do

		local StartPose = self.RigTimeline[Bone].Poses[PoseData.CurrentPose]
		local EndPose = self.RigTimeline[Bone].Poses[PoseData.CurrentPose + 1]
		if not EndPose then PoseCFrames[Bone] = StartPose.Pose.CFrame continue end
		
		PoseCFrames[Bone] = EasingFunctions[StartPose.Pose.EasingDirection][StartPose.Pose.EasingStyle](
			StartPose.Pose.CFrame,
			EndPose.Pose.CFrame,
			self.TimePosition - StartPose.Time,
			EndPose.Time - StartPose.Time
		)
	end

	return PoseCFrames
end

return Handler