local Types = script.Parent.Parent.Parent.Parent.Types

local KinematicsTypes = require(Types.Kinematics)

type KinematicBoneData = KinematicsTypes.KinematicBoneData

local Handler = {}
Handler.__index = Handler

function Handler.new(Parent: Bone | BasePart, Bone: Bone, Children: {Bone})
    local self = setmetatable({}, Handler)

    return self
end

function Handler:SolveForward(Bone0: KinematicBoneData, Bone1: KinematicBoneData)
end

function Handler:SolveBackward(Bone0: KinematicBoneData, Targets: {KinematicBoneData})
    
end

function Handler:GetBoneWorldCFrame(Bone: Bone | BasePart): CFrame
   return Bone:IsA("Bone") and Bone.WorldCFrame or Bone.CFrame 
end

function Handler:GetControlType()
    return "None"
end

return Handler