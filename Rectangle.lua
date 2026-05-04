local Object, private
local Rectangle
local Vector
local MouseInteractions, Drawable, Emitter
local ConstructorError, VectorSizeError, TypeError, InvalidError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Vector = require("classes.Vector")

Emitter           = require("classes.mixins.Emitter")
Drawable          = require("classes.mixins.Drawable")
MouseInteractions = require("classes.mixins.MouseInteractions")

TypeError        = require("classes.errors.TypeError")
InvalidError     = require("classes.errors.InvalidError")
VectorSizeError  = require("classes.errors.VectorSizeError")
ConstructorError = require("classes.errors.ConstructorError")

Rectangle = Object:init()

    --======PRIVATE FUNCTIONS======--

local modes, internal

modes = {
    fill = true,
    line = true
}

internal = math.uuid()

    --======STATIC======--

    --======CONSTRUCTOR======--

function Rectangle:fromValues(mode, x, y, width, height)
    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")
    TypeError:assert(type(mode) == "string", "mode", type(mode), "string")
    TypeError:assert(type(width) == "number", "width", type(width), "number")
    TypeError:assert(type(height) == "number", "height", type(height), "number")

    mode = mode:lower()

    InvalidError:assert(modes[mode], mode, "mode", table.join(modes, ", ", " and "))

    internal = math.uuid()
    
    return self {
        mode     = mode,
        size     = Vector:fromValues(width, height),
        position = Vector:fromValues(x, y),
        internal = internal
    }
end

function Rectangle:fromVectors(mode, position, size)
    TypeError:assert(type(mode) == "string", "mode", type(mode), "string")
    TypeError:assert(type(size) == "vector", "size", type(size), "vector")
    TypeError:assert(type(position) == "vector", "position", type(position), "vector")

    mode = mode:lower()

    InvalidError:assert(modes[mode], mode, "mode", table.join(modes, ", ", " and "))
    
    VectorSizeError:assert(size.size == 2, size.size, 2)
    VectorSizeError:assert(position.size == 2, position.size, 2)

    internal = math.uuid()
    
    return self {
        mode     = mode,
        size     = size:clone(),
        position = position:clone(),
        internal = internal
    }
end

function Rectangle:new(opts)
    local p = private[self]
    
    ConstructorError:assert(opts.internal == internal, "Rectangle")

    Drawable.new(self)
    MouseInteractions.new(self)

    p.mode   = opts.mode
    p.size   = opts.size
    p.offset = Vector:fromValues(0, 0)

    p.drawable.transform:translate(opts.position)
end

    --======METHODS======--

    --TODO
function Rectangle:matches(rectangle)
    local p = private[self]

    if p.drawable.transform:matches(private[rectangle].drawable.transform) then
    end
    p.size:matches(rectangle.size)
    p.offset:matches(rectangle.offset)
end

function Rectangle:contains(vector)
    local p, vx, vy
    
    p = private[self]

    TypeError:assert(type(vector) == "vector", "vector", type(vector), "vector")
    VectorSizeError:assert(vector.size == 2, vector.size, 2)

    vx, vy = p.drawable.transform:inverseTransformValues(vector.x, vector.y)

    return vx >= p.offset.x and
           vy >= p.offset.y and
           vx <  p.offset.x + p.size.x and
           vy <  p.offset.y + p.size.y
end

    --TODO
function Rectangle:touching(rectangle)
    local x, y, w, h, p, origin

    p = private[self]
    x, y, w, h = rectangle:unpack()

    return p.offset.x + p.size.x >= x     and
           p.offset.x            <= x + w and
           p.offset.y + p.size.y >= y     and
           p.offset.y            <= y + h
end

function Rectangle:draw()
    local p = private[self]

    love.graphics.push()

    self:drawable()
    
    love.graphics.rectangle(p.mode, p.offset.x, p.offset.y, p.size.x, p.size.y)

    love.graphics.pop()

    return self
end

function Rectangle:clone()
    local p, rectangle
    
    p         = private[self]
    rectangle = getmetatable(self):fromValues(p.mode, 0, 0, p.size.x, p.size.y)

    rectangle.offset:setToVector(p.offset)

    rectangle.transform.matrix = self.transform.matrix
    
    return rectangle
end

function Rectangle:unpack()
    local p = private[self]

    return p.offset.x, p.offset.y, p.size.x, p.size.y
end

    --======GETTERS======--

function Rectangle.__get:ox()
    return private[self].offset.x
end

function Rectangle.__get:oy()
    return private[self].offset.y
end

function Rectangle.__get:width()
    return private[self].size.x
end

function Rectangle.__get:height()
    return private[self].size.y
end

function Rectangle.__get:mode()
    return private[self].mode
end

function Rectangle.__get:size()
    return private[self].size
end

function Rectangle.__get:offset()
    return private[self].offset
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

function Rectangle.__set:width(value)
    TypeError:assert(type(value) == "number", "width", type(value), "number")

    private[self].size.x = value
end

function Rectangle.__set:height(value)
    TypeError:assert(type(value) == "number", "height", type(value), "number")

    private[self].size.y = value
end

function Rectangle.__set:mode(value)
    TypeError:assert(type(value) == "string", "mode", type(value), "string")

    value = value:lower()

    InvalidError:assert(modes[value], value, "mode", table.join(modes, ", ", " and "))

    private[self].mode = value
end

function Rectangle.__set:size(value)
    TypeError:assert(type(value) == "vector", "size", type(value), "vector")
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].size:setToVector(value)
end

function Rectangle.__set:offset(value)
    TypeError:assert(type(value) == "vector", "offset", type(value), "vector")
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].offset:setToVector(value)
end

    --======METAMETHODS======--

function Rectangle:__tostring()
    local p, sx, sy, ox, oy
    
    p = private[self]

    sx, sy = p.drawable.transform:transformValues(p.size.x, p.size.y)
    ox, oy = p.drawable.transform:transformValues(p.offset.x, p.offset.y)

    return self:tostring(p.mode, ox, oy, sx, sy)
end

Rectangle.__type = "rectangle"

return Object:create(Rectangle, MouseInteractions, Drawable, Emitter)
