local Object, private
local Circle
local Vector
local Drawable, Emitter, MouseInteractions
local TypeError, InvalidError, VectorSizeError, ConstructorError

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

Circle = Object:init()

    --======PRIVATE FUNCTIONS======--

local internal, valid_modes, valid_modes_lut

valid_modes_lut = {
    fill = true,
    line = true
}

valid_modes = table.join(valid_modes_lut, ", ", " and ")

internal = math.uuid()

    --======CONSTRUCTOR======--

function Circle:fromValues(mode, x, y, radius)
    TypeError:assert(type(x) == "number", "x", type(x), "number")
    TypeError:assert(type(y) == "number", "y", type(y), "number")
    TypeError:assert(type(mode) == "string", "mode", type(mode), "string")
    TypeError:assert(type(radius) == "number", "radius", type(radius), "number")

    mode = mode:lower()

    InvalidError:assert(valid_modes_lut[mode], mode, "mode", valid_modes)

    internal = math.uuid()

    return self {
        mode     = mode,
        radius   = radius,
        position = Vector:fromValues(x, y),
        internal = internal
    }
end

function Circle:fromVector(mode, position, radius)
    TypeError:assert(type(mode) == "string", "mode", type(mode), "string")
    TypeError:assert(type(radius) == "number", "radius", type(radius), "number")
    TypeError:assert(type(position) == "vector", "position", type(position), "vector")

    mode = mode:lower()

    InvalidError:assert(valid_modes_lut[mode], mode, "mode", valid_modes)

    VectorSizeError:assert(position.size == 2, position.size, 2)

    internal = math.uuid()

    return self {
        mode     = mode,
        radius   = radius,
        position = position:clone(),
        internal = internal
    }
end

function Circle:new(opts)
    local p = private[self]

    ConstructorError:assert(opts.internal == internal, "Circle")

    Emitter.new(self)
    Drawable.new(self)
    MouseInteractions.new(self)

    p.mode   = opts.mode
    p.radius = opts.radius
    p.offset = Vector:fromValues(0, 0)

    p.drawable.transform:translate(opts.position)
end

    --======METHODS======--

--TODO
function Circle:contains(vector)
    local p, vx, vy
    
    p = private[self]

    TypeError:assert(type(vector) == "vector", "vector", type(vector), "vector")
    VectorSizeError:assert(vector.size == 2, vector.size, 2)

    vx, vy = p.drawable.transform:inverseTransformValues(vector.x, vector.y)

    return (p.offset.x - vx) ^ 2 + (p.offset.y - vy) ^ 2 >= p.radius ^ 2
end

--TODO: Convert second circle to localspace of first circle, using inverseTransformValues
--then check if distance(a, b) < a.radius + b.radius
function Circle:touching(circle)
    local x, y, w, h, p

    p = private[self]
    x, y, w, h = circle:unpack()

    return p.pos.x + p.size.x >= x and
           p.pos.x <= x + w and
           p.pos.y + p.size.y >= y and
           p.pos.y <= y + h
end

function Circle:draw()
    local p = private[self]

    love.graphics.push()

    Drawable.apply(self)
    
    love.graphics.circle(p.mode, p.offset.x, p.offset.y, p.radius)

    love.graphics.pop()

    return self
end

function Circle:clone()
    local p, circle
    
    p      = private[self]
    circle = getmetatable(self):fromValues(p.mode, 0, 0, p.radius)

    circle.offset:setToVector(p.offset)

    circle.transform.matrix = self.transform.matrix
    
    return circle
end

function Circle:unpack()
    local p = private[self]

    return p.offset.x, p.offset.y, p.radius
end

    --======GETTERS======--

function Circle.__get:ox()
    return private[self].offset.x
end

function Circle.__get:oy()
    return private[self].offset.y
end

function Circle.__get:mode()
    return private[self].mode
end

function Circle.__get:radius()
    return private[self].radius
end

function Circle.__get:offset()
    return private[self].position
end

    --======SETTERS======--

function Circle.__set:ox(value)
    TypeError:assert(type(value) == "number", "ox", type(value), "number")

    private[self].offset.x = value
end

function Circle.__set:oy(value)
    TypeError:assert(type(value) == "number", "oy", type(value), "number")

    private[self].offset.y = value
end

function Circle.__set:mode(value)
    TypeError:assert(type(value) == "string", "mode", type(value), "string")

    value = value:lower()

    InvalidError:assert(valid_modes_lut[value], value, "mode", valid_modes)

    private[self].mode = value
end

function Circle.__get:radius(value)
    TypeError:assert(type(value) == "number", "radius", type(value), "number")

    private[self].radius = value
end

function Circle.__get:offset(value)
    TypeError:assert(type(value) == "vector", "offset", type(value), "vector")
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].offset:setToVector(value)
end

    --======METAMETHODS======--

function Circle:__tostring()
    local p = private[self]

    return self:tostring(p.position.x, p.position.y, p.radius)
end

Circle.__type = "circle"

local Class = Object:create(Circle, Drawable, Emitter, MouseInteractions)

return Class
