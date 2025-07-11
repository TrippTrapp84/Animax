local Handler = {}
Handler.__index = Handler

function Handler.new()
    local self = setmetatable({},Handler)

    self.Animations = {}

    return self
end

function Handler:AddAnimation(Animation,BlendOrientationType)
    local AnimStopCon = Animation.OnStop:Connect(function()
        self.Animations[Animation].AnimationStoppedConnection:Disconnect()
    end)

    local PreviousRotationCFrame = {}
    local PreviousRotationOffset = {}
    for Bone : Bone,BoneTimelineData in pairs(Animation:GetRigTimeline()) do
        PreviousRotationCFrame[Bone] = BoneTimelineData.Poses[1].Pose.CFrame
        PreviousRotationOffset[Bone] = Vector3.new(0,0,0)
    end
    
    self.Animations[Animation] = {
        Animation = Animation,
        BlendOrientationType = (BlendOrientationType or "ShortestDirection"),
        PreviousRotationCFrame = PreviousRotationCFrame,
        PreviousRotationOffset = PreviousRotationOffset,
        AnimationStoppedConnection = AnimStopCon
    }
    
end

function Handler:RemoveAnimation(Animation)
    self.Animations[Animation] = nil
end

function Handler:_GetTotalWeights()
    local Total = 0
    for Animation in pairs(self.Animations) do
        Total += Animation:GetWeight()
    end

    return Total
end

function Handler:_GetTotalWeightsForBone(Bone : Bone)
    local Total = 0
    for Animation in pairs(self.Animations) do
        Total += Animation:GetBoneWeight(Bone) * Animation:GetWeight()
    end

    return Total
end

function Handler:_StepAnimations(DeltaTime : number)
    for _,BlendData in pairs(self.Animations) do
        BlendData.Animation:StepAnimation(DeltaTime)
    end
end

function Handler:RenderAnimations(DeltaTime : number)
    self:_StepAnimations(DeltaTime)
    if self:_GetTotalWeights() == 0 then return {} end

    type PoseDataTemp = {Rotation : {Vector3},Position :{Vector3},Weights : {number},PoseNumber : number}

    local PoseData : {[Bone] : PoseDataTemp} = {}

    local IndexId = 1
    for Animation ,AnimData in pairs(self.Animations) do
        for Bone : Bone, BoneCFrame : CFrame in pairs(Animation:GetAnimationPoses()) do
            PoseData[Bone] = PoseData[Bone] or {
                Rotation = {},
                Position = {},
                Weights = {},
                PoseNumber = 0
            } :: PoseDataTemp

            local NewRotOffset

            if AnimData.BlendOrientationType == "RememberOrientation" then
                local PrevRotX,PrevRotY,PrevRotZ = AnimData.PreviousRotationCFrame[Bone]:ToOrientation()
                local RotX,RotY,RotZ = BoneCFrame:ToOrientation()
                local RotDiffX, RotDiffY,RotDiffZ = RotX - PrevRotX,RotY - PrevRotY,RotZ - PrevRotZ
                
                local PrevRotOffset = AnimData.PreviousRotationOffset[Bone]
                
                NewRotOffset = Vector3.new(
                    PrevRotOffset.X + RotDiffX
                    ,PrevRotOffset.Y + RotDiffY
                    ,PrevRotOffset.Z + RotDiffZ
                )
            elseif AnimData.BlendOrientationType == "ShortestDirection" then
                NewRotOffset = Vector3.new(BoneCFrame:ToOrientation())
            end
            
            PoseData[Bone].Rotation[IndexId] = NewRotOffset
            PoseData[Bone].Position[IndexId] = BoneCFrame.Position
            PoseData[Bone].Weights[IndexId] = Animation:GetBoneWeight(Bone) * Animation:GetWeight()
            
            local PoseNum = PoseData[Bone].PoseNumber
            PoseData[Bone].PoseNumber = PoseNum and PoseNum+1 or 1
            
            AnimData.PreviousRotationCFrame[Bone] = BoneCFrame
            AnimData.PreviousRotationOffset[Bone] = NewRotOffset
        end

        IndexId += 1
    end
    
    local OutputPoses : {[Bone] : CFrame} = {}

    for Bone : Bone, BonePoseData : PoseDataTemp in pairs(PoseData) do
        local FinalRotation = Vector3.new()
        local FinalPosition = Vector3.new()

        for PoseDataIndex : number in pairs(BonePoseData.Position) do
            FinalRotation += BonePoseData.Rotation[PoseDataIndex] * BonePoseData.Weights[PoseDataIndex]
            FinalPosition += BonePoseData.Position[PoseDataIndex] * BonePoseData.Weights[PoseDataIndex]
        end
        
        local TotalAnimationWeights = self:_GetTotalWeightsForBone(Bone)
        if TotalAnimationWeights == 0 then continue end
        FinalRotation /= TotalAnimationWeights
        FinalPosition /= TotalAnimationWeights

        local BoneFinalPose = CFrame.fromOrientation(
            FinalRotation.X,
            FinalRotation.Y,
            FinalRotation.Z
        ) + FinalPosition
        OutputPoses[Bone] = BoneFinalPose
    end

    return OutputPoses

end

return Handler