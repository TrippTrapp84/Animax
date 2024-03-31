---!strict
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local EasingFunctions = require(script.Parent.Util.EasingFunctions)

local UIDGenerator = require(script.Parent.Util.UIDGenerator)
local Event = require(script.Parent.Util.Event)

local Handler = {}
Handler.__index = Handler

--// TYPES
type UIDGenerator = UIDGenerator.UIDGenerator

type ANMXScriptSignal = Event.ANMXScriptSignal

export type AnimationStateChangedCallback = (...any) -> ()

export type RigTimelinePose = {Pose : Pose, Time : number}

export type RigTimelineData = {
	Bone : Bone,
	Poses : {RigTimelinePose},
	CurrentPose : number,
	RotationTimeline : {Vector3}
}

export type ANMXAnimationTrack = typeof(setmetatable({},Handler)) & typeof(Handler) & {
	AnimationId : string,
	Root : BasePart,
	Keyframes : {Keyframe},
	RigTimeline : {[Bone] : RigTimelineData},
	TimePosition : number,
	Length : number,
	Looped : boolean,
	UseRotationTimeline : boolean,
	RotationTimelineIncrement : number,
	IsPlaying : boolean,
	Weight : number,
	Priority : number,
	Speed : number,
	CallbackIdGenerator : UIDGenerator,
	OnPlay : ANMXScriptSignal,
	OnStop : ANMXScriptSignal,
	OnLooped : ANMXScriptSignal,
	OnSpeedChanged : ANMXScriptSignal,
	OnWeightChanged : ANMXScriptSignal,
	OnLoopedChanged : ANMXScriptSignal,
	OnTimePositionChanged : ANMXScriptSignal,
}
--// END TYPES

function Handler.new(Root : BasePart,AnimationId : string)
	local self : ANMXAnimationTrack = setmetatable({},Handler) :: ANMXAnimationTrack
	
	self.AnimationId = AnimationId
	self.Root = Root
	self.Keyframes = (KeyframeSequenceProvider:GetKeyframeSequenceAsync(self.AnimationId) :: KeyframeSequence):GetKeyframes() :: {Keyframe}
	
	table.sort(self.Keyframes,function(KF1,KF2)
		return KF1.Time < KF2.Time
	end)

	self.RigTimeline = {}
	self.TimePosition = 0
	self.Length = self.Keyframes[#self.Keyframes].Time
	self.Looped = false
	self.UseRotationTimeline = false
	self.RotationTimelineIncrement = 0.1
	self.IsPlaying = false
	self.Weight = 1
	self.Speed = 1
	
	self.CallbackIdGenerator = UIDGenerator.new() :: UIDGenerator
	
	self.OnPlay = Event.new()
	self.OnStop = Event.new()
	self.OnLooped = Event.new()
	self.OnSpeedChanged = Event.new()
	self.OnWeightChanged = Event.new()
	self.OnLoopedChanged = Event.new()
	self.OnTimePositionChanged = Event.new()
	
	self:_BuildRigTimeline(self.Keyframes)
	if self.UseRotationTimeline then
		self:_BuildRigRotationTimeline()
	end
	
	return self
end

do --// RIG TIMELINE
	do --// BUILD TIMELINE (INTERNAL)

		function Handler._BuildRotationTimelineForBone(self : ANMXAnimationTrack, Bone : Bone,BonePoseData : RigTimelineData)
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

				local StartPose : RigTimelinePose = BonePoseData.Poses[CurrentPose]
				local EndPose : RigTimelinePose = BonePoseData.Poses[CurrentPose + 1]
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

		function Handler._BuildRigRotationTimeline(self : ANMXAnimationTrack)
			for Bone : Bone, BonePoseData : RigTimelineData in pairs(self.RigTimeline) do
				self:_BuildRotationTimelineForBone(Bone,BonePoseData)
			end
		end

		function Handler._AddBoneToRigTimeline(self : ANMXAnimationTrack,Bone : Bone, Pose : Pose,Time : number)
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

			for _,SubPose : Pose in pairs(Pose:GetSubPoses() :: {Pose}) do
				self:_AddBoneToRigTimeline(Bone:FindFirstChild(SubPose.Name) :: Bone,SubPose,Time)
			end
		end

		function Handler._AddKeyframeToRigTimeline(self : ANMXAnimationTrack,Keyframe : Keyframe)
			for _,Pose : Pose in pairs((Keyframe:GetPoses()[1] :: Pose):GetSubPoses() :: {Pose}) do
				self:_AddBoneToRigTimeline(self.Root:FindFirstChild(Pose.Name) :: Bone,Pose,Keyframe.Time)
			end
		end

		function Handler._BuildRigTimeline(self : ANMXAnimationTrack,Keyframes : {Keyframe})
			for _,Keyframe : Keyframe in pairs(Keyframes) do
				self:_AddKeyframeToRigTimeline(Keyframe)

			end
		end
	end
	
	do --// RETRIEVE TIMELINE DATA (EXTERNAL)
		function Handler.GetRigTimeline(self : ANMXAnimationTrack)
			return self.RigTimeline
		end
	end
end

do --// EDIT ANIMATION STATE
	function Handler._RecalculateCurrentPoseIndex(self : ANMXAnimationTrack)
		for Bone : Bone,BoneTimelineData : RigTimelineData in pairs(self.RigTimeline) do
			for PoseNumber : number, PoseData : RigTimelinePose in pairs(BoneTimelineData.Poses) do
				if self.TimePosition >= PoseData.Time then
					BoneTimelineData.CurrentPose = PoseNumber
				else
					BoneTimelineData.CurrentPose = PoseNumber-1
					break
				end
			end
		end
	end

	function Handler.Play(self : ANMXAnimationTrack,Time : number?)
		if self.IsPlaying then return end
		self.IsPlaying = true
		self.TimePosition = Time or 0
		self:_RecalculateCurrentPoseIndex()
		self.OnPlay:Fire()
		--self:_CallCallbacks(self.OnPlay,Time)
	end
	
	function Handler.Stop(self : ANMXAnimationTrack)
		if not self.IsPlaying then return end
		self.IsPlaying = false
		self.TimePosition = 0
		self:_RecalculateCurrentPoseIndex()
		self.OnStop:Fire()
		--self:_CallCallbacks(self.OnStop)
	end
	
	function Handler.AdjustSpeed(self : ANMXAnimationTrack,Speed : number)
		self.Speed = Speed
		self.OnSpeedChanged:Fire(self.Speed)
		--self:_CallCallbacks(self.OnSpeedChanged)
	end
	
	function Handler.AdjustWeight(self : ANMXAnimationTrack,Weight : number)
		self.Weight = Weight
		self.OnWeightChanged:Fire(self.Weight)
		--self:_CallCallbacks(self.OnWeightChanged)
	end
	
	function Handler.SetTimePosition(self : ANMXAnimationTrack,Time : number)
		assert(Time <= self.Length and Time >= 0,"Argument Time cannot be less than zero or greater than the duration of the animation.")

		local Looped = false
		if Time == self.Length then Looped = true Time = 0 end
		self.TimePosition = Time
		self:_RecalculateCurrentPoseIndex()
		self.OnTimePositionChanged:Fire(self.TimePosition)
		if Looped then self.OnLooped:Fire() end
		--self:_CallCallbacks(self.OnTimePositionChanged)
	end

	function Handler.SetLooped(self : ANMXAnimationTrack,Looped : boolean)
		self.Looped = Looped
		self.OnLoopedChanged:Fire()
	end
end

do --// READ ANIMATION STATE (EXTERNAL)
	function Handler.GetWeight(self : ANMXAnimationTrack)
		return self.Weight
	end

	function Handler.GetBoneWeight(self : ANMXAnimationTrack, Bone : Bone)
		local BoneData = self.RigTimeline[Bone]
		if not BoneData then return 0 end
		local CurrentPose = BoneData.Poses[BoneData.CurrentPose]
		if not CurrentPose then return 0 end
		return CurrentPose.Pose.Weight
	end
	
	function Handler.GetSpeed(self : ANMXAnimationTrack)
		return self.Speed
	end
	
	function Handler.GetIsPlaying(self : ANMXAnimationTrack)
		return self.IsPlaying
	end
	
	function Handler.GetTimePosition(self : ANMXAnimationTrack)
		return self.TimePosition
	end
end

do --// RENDER ANIMATION

	function Handler.ReadRotationTimelineAtTime(self : ANMXAnimationTrack,Time : number) : {[Bone] : Vector3}
		local RotationOffsets : {[Bone] : Vector3} = {}
		
		local RotationTimelineIndex = Time / self.RotationTimelineIncrement
		local RotationInterpolationAlpha = RotationTimelineIndex % 1
		RotationTimelineIndex = math.round(RotationTimelineIndex - RotationInterpolationAlpha)

		for Bone : Bone, BoneTimelineData : RigTimelineData in pairs(self.RigTimeline) do
			local RotationPoint1 = BoneTimelineData.RotationTimeline[RotationTimelineIndex]
			if not RotationPoint1 then RotationOffsets[Bone] = BoneTimelineData.RotationTimeline[#BoneTimelineData.RotationTimeline] continue end

			local RotationPoint2 = BoneTimelineData.RotationTimeline[RotationTimelineIndex + 1]
			if not RotationPoint2 then RotationOffsets[Bone] = RotationPoint1 continue end

			RotationOffsets[Bone] = RotationPoint1 * (1 - RotationInterpolationAlpha) + RotationPoint2 * (RotationInterpolationAlpha)
		end

		return RotationOffsets
	end

	function Handler.ReadRotationTimeline(self : ANMXAnimationTrack) : {[Bone] : Vector3}
		return self:ReadRotationTimelineAtTime(self.TimePosition)
	end

	function Handler.GetAnimationPosesAtTime(self : ANMXAnimationTrack,Time : number)
		local RigPoseNumbers : {[Bone] : number} = {}
		for Bone : Bone,PoseData : RigTimelineData in pairs(self.RigTimeline) do
			RigPoseNumbers[Bone] = 0
			for PoseNumber : number, PoseInfo : RigTimelinePose in pairs(PoseData.Poses) do
				if PoseInfo.Time < Time then break end
				RigPoseNumbers[Bone] = PoseNumber
			end
		end
		
		local PoseCFrames : {[Bone] : CFrame} = {}
		for Bone : Bone,CurrentPose : number in pairs(RigPoseNumbers) do
			if CurrentPose < 1 then continue end
			if not self.RigTimeline[Bone].Poses[CurrentPose + 1] then PoseCFrames[Bone] = self.RigTimeline[Bone].Poses[CurrentPose].Pose.CFrame continue end
			local StartPose : RigTimelinePose = self.RigTimeline[Bone].Poses[CurrentPose]
			local EndPose : RigTimelinePose = self.RigTimeline[Bone].Poses[CurrentPose + 1]
			PoseCFrames[Bone] = EasingFunctions[StartPose.Pose.EasingDirection][StartPose.Pose.EasingStyle](
				StartPose.Pose.CFrame,
				EndPose.Pose.CFrame,
				Time - StartPose.Time,
				EndPose.Time - StartPose.Time
			)
		end
		
		return PoseCFrames
	end
	
	function Handler.GetAnimationPoses(self : ANMXAnimationTrack) : {[Bone] : CFrame}

		local PoseCFrames : {[Bone] : CFrame} = {}
		for Bone : Bone,PoseData in pairs(self.RigTimeline) do

			local StartPose : RigTimelinePose = self.RigTimeline[Bone].Poses[PoseData.CurrentPose]
			local EndPose : RigTimelinePose = self.RigTimeline[Bone].Poses[PoseData.CurrentPose + 1]
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

	function Handler.StepAnimation(self : ANMXAnimationTrack,DeltaTime : number)
		self.TimePosition += DeltaTime * self.Speed
		for Bone : Bone,BoneTimelineData : RigTimelineData in pairs(self.RigTimeline) do
			if not BoneTimelineData.Poses[BoneTimelineData.CurrentPose + 1] then continue end
			if BoneTimelineData.Poses[BoneTimelineData.CurrentPose + 1].Time <= self.TimePosition then BoneTimelineData.CurrentPose += 1 end
		end

		if self.TimePosition < self.Length then return end
		if self.Looped then
			self.TimePosition -= self.Length
			self:_RecalculateCurrentPoseIndex()
			self.OnLooped:Fire()
			return
		end
		self:Stop()
	end
end

return Handler