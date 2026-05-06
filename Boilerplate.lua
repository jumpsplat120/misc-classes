local Object, private
local NEW_CLASS

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

NEW_CLASS = Object:init()

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

    return self:tostring()
end

NEW_CLASS.__type = "NEW_CLASS"

---@type NEW_CLASS.Class
local Class = Object:create(NEW_CLASS)

return Class