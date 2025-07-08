--!nocheck
--!nolint
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local Util = script.Parent.Parent.Parent.Util
local EasingFunctions = require(Util.EasingFunctions)

local Event = require(Util.Event)

local Handler = {}
Handler.__index = Handler

function Handler.new(Root : BasePart,AnimationId : string)
	local self = setmetatable({},Handler)
	
	self.AnimationId = AnimationId
	self.Root = Root
	self.Keyframes = ((KeyframeSequenceProvider:GetKeyframeSequenceAsync(self.AnimationId) :: KeyframeSequence):GetKeyframes() :: never) :: {Keyframe}
	
	table.sort(self.Keyframes,function(KF1,KF2)
		return KF1.Time < KF2.Time
	end)

	self.TimePosition = 0
	self.Length = self.Keyframes[#self.Keyframes].Time
	self.Looped = false
	self.IsPlaying = false
	self.Weight = 1
	self.Speed = 1
	
	self.OnPlay = Event.new()
	self.OnStop = Event.new()
    self.OnStep = Event.new()
	self.OnLooped = Event.new()
	self.OnSpeedChanged = Event.new()
	self.OnWeightChanged = Event.new()
	self.OnLoopedChanged = Event.new()
	self.OnTimePositionChanged = Event.new()
	
	return self
end

function Handler:Play(Time : number?)
	if self.IsPlaying then return end
	self.IsPlaying = true
	self.TimePosition = Time or 0
	self.OnPlay:Fire()
end

function Handler:Stop()
	if not self.IsPlaying then return end
	self.IsPlaying = false
	self.TimePosition = 0
	self.OnStop:Fire()
end

function Handler:AdjustSpeed(Speed : number)
	self.Speed = Speed
	self.OnSpeedChanged:Fire(self.Speed)
end

function Handler:AdjustWeight(Weight : number)
	self.Weight = Weight
	self.OnWeightChanged:Fire(self.Weight)
end

function Handler:SetTimePosition(Time : number)
	assert(Time <= self.Length and Time >= 0,"Argument Time cannot be less than zero or greater than the duration of the animation.")

	local Looped = false
	if Time == self.Length then Looped = true Time = 0 end
	self.TimePosition = Time
	self.OnTimePositionChanged:Fire(self.TimePosition)
	if Looped then self.OnLooped:Fire() end
end

function Handler:SetLooped(Looped : boolean)
	self.Looped = Looped
	self.OnLoopedChanged:Fire()
end

function Handler:GetWeight()
	return self.Weight
end

function Handler:GetSpeed()
	return self.Speed
end

function Handler:GetIsPlaying()
	return self.IsPlaying
end

function Handler:GetTimePosition()
	return self.TimePosition
end

function Handler:StepAnimation(DeltaTime : number)
	self.TimePosition += DeltaTime * self.Speed
	self.OnStep:Fire(DeltaTime)

	if self.TimePosition < self.Length then return end
	if self.Looped then
		self.TimePosition -= self.Length
		self.OnLooped:Fire()
		return
	end
	self:Stop()
end

return Handler