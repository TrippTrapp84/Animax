local Types = script.Parent.Parent.Parent.Parent.Types
local Util = script.Parent.Parent.Parent.Parent.Util

local Base = require(script.Parent.Base)
local KinematicsTypes = require(Types.Kinematics)
local Gizmo = require(Util.Gizmo)

type KinematicBoneData = KinematicsTypes.KinematicBoneData

local Handler = setmetatable({}, Base)
Handler.__index = Handler

function Handler.new(Parent, Bone, Children)
    local self = setmetatable({}, Handler)

    self.Weight = 1
    self.Target = {CFrame = Bone.TransformedWorldCFrame}

    do --// End effector debug
        self.Target = Instance.new("Part")
        self.Target.CFrame = Bone.TransformedWorldCFrame
        self.Target.Anchored = true
        self.Target.Size = Vector3.new(20,20,20)
        self.Target.Color = Color3.new(1,0,0)
        self.Target.Parent = workspace
    end

    return self
end

function Handler:SolveForward(Bone0: KinematicBoneData, Bone1: KinematicBoneData)
    return
end

function Handler:SolveBackward(Bone0: KinematicBoneData, Targets: {KinematicBoneData})
    local Bone0WorldCF = Bone0.WorldCFrame

    return Bone0WorldCF:ToObjectSpace(self.Target.CFrame)
end

function Handler:GetControlType()
    return "Transform"
end

return Handler