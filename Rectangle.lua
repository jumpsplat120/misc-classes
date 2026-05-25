local Object, private
local Rectangle
local MouseInteractions, Drawable, Emitter
local ConstructorError, VectorSizeError, TypeError, InvalidError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Emitter           = require("classes.mixins.Emitter")
Drawable          = require("classes.mixins.Drawable")
MouseInteractions = require("classes.mixins.MouseInteractions")

TypeError        = require("classes.errors.TypeError")
InvalidError     = require("classes.errors.InvalidError")
VectorSizeError  = require("classes.errors.VectorSizeError")
ConstructorError = require("classes.errors.ConstructorError")

Rectangle = Object:init()

    --======PRIVATE FUNCTIONS======--

local internal, valid_modes, valid_modes_lut

valid_modes_lut = {
    fill = true,
    line = true
}

valid_modes = table.join(valid_modes_lut, ", ", " and ")

internal = math.random()

    --======STATIC======--

    --======CONSTRUCTOR======--

function Rectangle:fromValues(mode, x, y, width, height)
    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")
    TypeError:assert(type(mode) == "string", "mode", type(mode), "string")
    TypeError:assert(type(width) == "number", "width", type(width), "number")
    TypeError:assert(type(height) == "number", "height", type(height), "number")

    mode = mode:lower()

    InvalidError:assert(valid_modes_lut[mode], mode, "mode", valid_modes)

    internal = math.random()
    
    return self {
        mode     = mode,
        size     = { width, height },
        position = { x, y },
        internal = internal
    }
end

function Rectangle:fromVectors(mode, position, size)
    TypeError:assert(type(mode) == "string", "mode", type(mode), "string")
    TypeError:assert(type(size) == "vector", "size", type(size), "vector")
    TypeError:assert(type(position) == "vector", "position", type(position), "vector")

    mode = mode:lower()

    InvalidError:assert(valid_modes_lut[mode], mode, "mode", valid_modes)
    
    VectorSizeError:assert(size.size == 2, size.size, 2)
    VectorSizeError:assert(position.size == 2, position.size, 2)

    internal = math.random()
    
    return self {
        mode     = mode,
        size     = size.table,
        position = position.table,
        internal = internal
    }
end

function Rectangle:new(opts)
    local p = private[self]
    
    ConstructorError:assert(opts.internal == internal, "Rectangle")

    Emitter.new(self)
    Drawable.new(self)
    MouseInteractions.new(self)

    p.mode   = opts.mode
    p.size   = opts.size
    p.offset = { 0, 0 }

    p.drawable.transform:translate(opts.position[1], opts.position[2])
end

    --======METHODS======--

function Rectangle:contains(x, y)
    local p = private[self]

    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")

    x, y = p.drawable.transform:inverseTransform(x, y)

    return x >= p.offset[1] and
           y >= p.offset[2] and
           x <  p.offset[1] + p.size[1] and
           y <  p.offset[2] + p.size[2]
end

--TODO: Convert second rectangle to localspace of first rectangle, using inverseTransformValues
--then do AABB
function Rectangle:touching(rectangle)
    --local x, y, w, h, p, origin
    --
    --p = private[self]
    --x, y, w, h = rectangle:unpack()
    --
    --return p.offset.x + p.size.x >= x     and
    --       p.offset.x            <= x + w and
    --       p.offset.y + p.size.y >= y     and
    --       p.offset.y            <= y + h
end

function Rectangle:draw()
    local p = private[self]

    love.graphics.push()

    Drawable.apply(self)
    
    love.graphics.rectangle(p.mode, p.offset[1], p.offset[2], p.size[1], p.size[2])

    love.graphics.pop()

    return self
end

function Rectangle:clone()
    local p, rectangle
    
    p         = private[self]
    rectangle = getmetatable(self):fromValues(p.mode, 0, 0, p.size[1], p.size[2])

    rectangle.ox = p.offset[1]
    rectangle.oy = p.offset[2]

    rectangle.transform.matrix = self.transform.matrix
    
    return rectangle
end

function Rectangle:unpack()
    local p = private[self]

    return p.offset[1], p.offset[2], p.size[1], p.size[2]
end

    --======GETTERS======--

function Rectangle.__get:ox()
    return private[self].offset[1]
end

function Rectangle.__get:oy()
    return private[self].offset[2]
end

function Rectangle.__get:mode()
    return private[self].mode
end

function Rectangle.__get:width()
    return private[self].size[1]
end

function Rectangle.__get:height()
    return private[self].size[1]
end

    --======SETTERS======--

function Rectangle.__set:ox(value)
    TypeError:assert(type(value) == "number", "ox", type(value), "number")

    private[self].offset.x = value
end

function Rectangle.__set:oy(value)
    TypeError:assert(type(value) == "number", "oy", type(value), "number")

    private[self].offset.y = value
end

function Rectangle.__set:mode(value)
    TypeError:assert(type(value) == "string", "mode", type(value), "string")

    value = value:lower()

    InvalidError:assert(modes[value], value, "mode", table.join(modes, ", ", " and "))

    private[self].mode = value
end

function Rectangle.__set:width(value)
    TypeError:assert(type(value) == "number", "width", type(value), "number")

    private[self].size.x = value
end

function Rectangle.__set:height(value)
    TypeError:assert(type(value) == "number", "height", type(value), "number")

    private[self].size.y = value
end

    --======METAMETHODS======--

function Rectangle:__tostring()
    local p, sx, sy, ox, oy
    
    p = private[self]

    sx, sy = p.drawable.transform:transform(p.size[1], p.size[2])
    ox, oy = p.drawable.transform:transform(p.offset[1], p.offset[2])

    return self:tostring(p.mode, ox, oy, sx, sy)
end

Rectangle.__type = "rectangle"

---@type Rectangle.Class
local Class = Object:create(Rectangle, MouseInteractions, Drawable, Emitter)

return Class
