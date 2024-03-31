---!strict
local EventTypes = require(script.Parent.types)

type ANMXScriptSignal = EventTypes.ANMXScriptSignal

type ANMXScriptConnection = EventTypes.ANMXScriptConnection

local Handler = {}
Handler.__index = Handler

function Handler.new(Signal : ANMXScriptSignal,ConnectionId : {}) : ANMXScriptConnection
    local self : ANMXScriptConnection = setmetatable({},Handler) :: ANMXScriptConnection

    self.Signal = Signal
    self.ConnectionId = ConnectionId

    return self
end

function Handler.Disconnect(self : ANMXScriptConnection)
    self.Signal:_Disconnect(self)
end

return Handler