--!strict
--// TYPES
type EasingFunction = (Start : CFrame,End : CFrame,Time : number,Duration : number) -> CFrame
type EasingStyleTable = {[number | EnumItem] : EasingFunction}
type EasingDirectionTable = {[number | EnumItem] : EasingStyleTable}

--// CODE
local EasingDirection = {}
for i,v in pairs(Enum.EasingDirection:GetEnumItems()) do
	EasingDirection[v.Name] = v.Value
end

local EasingStyle = {}
for i,v in pairs(Enum.EasingStyle:GetEnumItems()) do
	EasingStyle[v.Name] = v.Value
end

local EasingData : EasingDirectionTable ; EasingData = {
	[EasingDirection.In] = {
		[EasingStyle.Linear] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,Time / Duration)
		end,
		[EasingStyle.Quad] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,(Time / Duration) ^ 2)
		end,
		[EasingStyle.Cubic] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,(Time / Duration) ^ 3)
		end,
		[EasingStyle.Quart] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,(Time / Duration) ^ 4)
		end,
		[EasingStyle.Quint] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,(Time / Duration) ^ 5)
		end,
		[EasingStyle.Sine] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,math.sin((Time / Duration) * math.pi/2))
		end
	},

	[EasingDirection.Out] = {
		[EasingStyle.Linear] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,Time / Duration)
		end,
		[EasingStyle.Quad] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,1 - (1 - Time / Duration) ^ 2)
		end,
		[EasingStyle.Cubic] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,1 - (1 - Time / Duration) ^ 3)
		end,
		[EasingStyle.Quart] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,1 - (1 - Time / Duration) ^ 4)
		end,
		[EasingStyle.Quint] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,1 - (1 - Time / Duration) ^ 5)
		end,
		[EasingStyle.Sine] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,1 - math.sin((1 - Time / Duration) * math.pi/2))
		end
	},
	[EasingDirection.InOut] = {
		[EasingStyle.Linear] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			return Start:Lerp(End,Time / Duration)
		end,
		[EasingStyle.Quad] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			if Time > 0.5 then return EasingData[EasingDirection.Out][EasingStyle.Quad](Start,End,Time,Duration) end
			return EasingData[EasingDirection.In][EasingStyle.Quad](Start,End,Time,Duration)
		end,
		[EasingStyle.Cubic] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			if Time > 0.5 then return EasingData[EasingDirection.Out][EasingStyle.Cubic](Start,End,Time,Duration) end
			return EasingData[EasingDirection.In][EasingStyle.Cubic](Start,End,Time,Duration)
		end,
		[EasingStyle.Quart] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			if Time > 0.5 then return EasingData[EasingDirection.Out][EasingStyle.Quart](Start,End,Time,Duration) end
			return EasingData[EasingDirection.In][EasingStyle.Quart](Start,End,Time,Duration)
		end,
		[EasingStyle.Quint] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			if Time > 0.5 then return EasingData[EasingDirection.Out][EasingStyle.Quint](Start,End,Time,Duration) end
			return EasingData[EasingDirection.In][EasingStyle.Quint](Start,End,Time,Duration)
		end,
		[EasingStyle.Sine] = function(Start : CFrame,End : CFrame,Time : number,Duration : number)
			if Time > 0.5 then return EasingData[EasingDirection.Out][EasingStyle.Sine](Start,End,Time,Duration) end
			return EasingData[EasingDirection.In][EasingStyle.Sine](Start,End,Time,Duration)
		end
	}
}

--// Metatable stuff so you can index with enums and still use array indexing (performance :chad:)
local EasingFunctionsMT = {
	__index = function(Table : {[any] : any},Index : any)
		if typeof(Index) ~= "EnumItem" then return end
		
		return Table[(Index :: EnumItem).Value]
	end
}

setmetatable(EasingData,EasingFunctionsMT)
setmetatable(EasingData[Enum.EasingDirection.In],EasingFunctionsMT)
setmetatable(EasingData[Enum.EasingDirection.Out],EasingFunctionsMT)
setmetatable(EasingData[Enum.EasingDirection.InOut],EasingFunctionsMT)

return EasingData