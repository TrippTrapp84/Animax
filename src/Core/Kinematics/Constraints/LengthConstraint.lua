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

    return self
end

function Handler:SolveForward(Bone0: KinematicBoneData, Bone1: KinematicBoneData)
    local Bone1CF = Bone1.Bone.CFrame

    local TransformedCFrame = Bone1CF:ToWorldSpace(Bone1.Transform)

    local ConstraintDistance = Bone1CF.Position.Magnitude

    local TransformedCFrameDirection = TransformedCFrame.Position.Unit
    if TransformedCFrameDirection ~= TransformedCFrameDirection then
        TransformedCFrameDirection = Bone1CF.Position.Unit

        if TransformedCFrameDirection ~= TransformedCFrameDirection then TransformedCFrameDirection = Vector3.zero end
    end

    return Bone1CF:ToObjectSpace(TransformedCFrame.Rotation + TransformedCFrameDirection * ConstraintDistance)
end

function Handler:SolveBackward(Bone0: KinematicBoneData, Targets: {KinematicBoneData})
    local Position = Vector3.new()
    local PosCount = 0

    for i,v in pairs(Targets) do
        local BoneCF = v.Bone.CFrame
        local Distance = v.Bone.CFrame.Position.Magnitude
        local TransformedCFrame = BoneCF:ToWorldSpace(v.Transform)

        local TransformedCFrameDirection = TransformedCFrame.Position.Unit
        if TransformedCFrameDirection ~= TransformedCFrameDirection then
            TransformedCFrameDirection = BoneCF.Position.Unit
            
            if TransformedCFrameDirection ~= TransformedCFrameDirection then TransformedCFrameDirection = Vector3.zero end
        end
        
        Position += TransformedCFrame.Position - TransformedCFrameDirection * Distance
        PosCount += 1
    end
    
    if PosCount < 1 then return end

    local NewPosition = Bone0.Transform:PointToWorldSpace(Position / PosCount)

    return Bone0.Transform.Rotation + NewPosition
end

function Handler:GetControlType()
    return "Position"
end

return Handler