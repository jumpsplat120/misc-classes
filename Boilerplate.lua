---@type Object
local Object
local NEW_CLASS, private

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

NEW_CLASS = Object:extend()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function NEW_CLASS:new()
end

    --======METHODS======--
    
    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function NEW_CLASS:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

NEW_CLASS.__type = "NEW_CLASS"

return NEW_CLASS