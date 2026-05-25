local Object, private
local Spritebatch

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Spritebatch = Object:init()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

--TODO: Add all the methods, do all the error checking, etc.
function Spritebatch:new(image)
    local p = private[self]

    p.batch = love.graphics.newSpriteBatch(private[image].image)
end

    --======METHODS======--

function Spritebatch:add(x, y, r, sx, sy, ox, oy, kx, ky)
    return private[self].batch:add(x, y, r, sx, sy, ox, oy, kx, ky)
end

function Spritebatch:set(spriteindex, x, y, r, sx, sy, ox, oy, kx, ky)
    private[self].batch:set(spriteindex, x, y, r, sx, sy, ox, oy, kx, ky)

    return self
end

    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function Spritebatch:__tostring()
    local p = private[self]

    return self:tostring()
end

Spritebatch.__type = "spritebatch"

---@type Spritebatch.Class
local Class = Object:create(Spritebatch)

return Class