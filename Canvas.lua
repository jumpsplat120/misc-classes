---@type Object
local Object
local is
local Canvas, private, Vector
local Drawable
local TypeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

is = require("lib.is")

Vector = require("classes.Vector")

Drawable = require("classes.mixins.Drawable")

TypeError = require("classes.errors.TypeError")

Canvas = Object:extend()

Canvas:implement(Drawable)

    --======PRIVATE FUNCTIONS======--

local function scale(p)
    if p.size.magnitude < 0 then
        p.drawable.scale:setToValues(
            p.size.x < 0 and math.abs(p.drawable.scale.x) * -1,
            p.size.y < 0 and math.abs(p.drawable.scale.y) * -1
        )

        p.size:invert(true)
    end
end

    --======CONSTRUCTOR======--

function Canvas:new(draw_callback, position, size)
    local p, mode
    
    p    = private[self]
    mode = { love.window.getMode() }

    TypeError:assert(is(draw_callback, "function"), "draw_callback", type(draw_callback), "function")
    TypeError:assert(position == nil or is(position, Vector), "position", type(position), Vector)
    TypeError:assert(size == nil or is(size, Vector), "size", type(size), Vector)
    
    Drawable.new(self)

    p.callback  = draw_callback
    p.position  = position or Vector:fromValues(0, 0)
    p.size      = size or Vector:fromValues(mode[1], mode[2])
    p.curr_size = p.size:clone()
    p.stencil   = false

    scale(p)

    p.canvas = love.graphics.newCanvas(p.size:unpack())
end

    --======METHODS======--
--TODO: VecSizeError
function Canvas:set(position, size)
    local p = private[self]
    
    if position ~= nil then
        TypeError:assert(is(position, Vector), "position", type(position), Vector)

        p.position:setToVector(position)
    end
    
    if size then
        TypeError:assert(is(size, Vector), "size", type(size), Vector)

        p.size:setToVector(size)
    end

    return self
end

function Canvas:update(...)
    local p = private[self]
    
    if not p.curr_size:matches(p.size) then
        scale(p)

        p.canvas    = love.graphics.newCanvas(p.size.x, p.size.y)
        p.curr_size = p.size:clone()
    end

    love.graphics.push("all")

    love.graphics.setCanvas({ p.canvas, stencil = p.stencil })
    love.graphics.clear()

    p.callback(...)

    love.graphics.setCanvas()

    love.graphics.pop()
end

function Canvas:draw()
    local p = private[self]

    p.drawable.color:apply()
    
    love.graphics.draw(
        p.canvas,
        p.position.x - 1,
        p.position.y - 1,
        p.drawable.rotation,
        p.drawable.scale.x,
        p.drawable.scale.y,
        p.drawable.origin.x,
        p.drawable.origin.y,
        p.drawable.shear.x,
        p.drawable.shear.y
    )

    p.drawable.color:remove()
end

    --======GETTERS======--

function Canvas.__get:x()
    return private[self].position.x
end

function Canvas.__get:y()
    return private[self].position.y
end

function Canvas.__get:width()
    return private[self].size.x
end

function Canvas.__get:height()
    return private[self].size.y
end

function Canvas.__get:size()
    return private[self].size
end

function Canvas.__get:position()
    return private[self].position
end

function Canvas.__get:stencil()
    return private[self].stencil
end

    --======SETTERS======--

function Canvas.__set:x(value)
    TypeError:assert(is(value, "number"), "x", type(value), "number")

    private[self].position.x = value
end

function Canvas.__set:y(value)
    TypeError:assert(is(value, "number"), "y", type(value), "number")

    private[self].position.y = value
end

function Canvas.__set:width(value)
    local p = private[self]

    TypeError:assert(is(value, "number"), "width", type(value), "number")

    p.size.x = value
end

function Canvas.__set:height(value)
    local p = private[self]

    TypeError:assert(is(value, "number"), "height", type(value), "number")

    p.size.y = value
end

function Canvas.__set:size(value)
    local p = private[self]

    TypeError:assert(is(value, Vector), "size", type(value), Vector)

    p.size = value
end

function Canvas.__set:position(value)
    TypeError:assert(is(value, Vector), "position", type(value), Vector)

    private[self].position = value
end

function Canvas.__set:stencil(value)
    private[self].stencil = not not value
end

    --======METAMETHODS======--

function Canvas:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.size.x, p.size.y, p.position.x, p.position.y) end

    return self:tostringHelper("Class")
end

Canvas.__type = "canvas"

return Canvas