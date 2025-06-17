---@type Object
local Object
local Passive, private

Object = require("lib.Classy")
private = require("lib.Classy.instances")

Passive = Object:extend()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Passive:new(name, condition, effect)
    local p = private[self]

    p.condition = condition
    p.effect    = effect
    p.name      = name
end

    --======METHODS======--

function Passive:isValid(game, piece, turn)
    return private[self]:condition(game, piece, turn)
end

function Passive:enact(game, piece)
    return private[self]:effect(game, piece)
end

    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function Passive:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.name) end

    return self:tostringHelper("Class")
end

Passive.__type = "passive"

return Passive