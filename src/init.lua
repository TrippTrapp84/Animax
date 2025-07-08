---!strict
local DefaultAnimator = require(script.Core.Animators.DefaultAnimator)

local Handler = {}

function Handler.Init(InitParams)

end

function Handler.MakeDefaultAnimator(RigRoot : BasePart, BlendType)
    return DefaultAnimator.new(RigRoot,BlendType)
end

return Handler