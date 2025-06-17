---@type Object
local Object
local Checkbox, Vector, Rectangle, Color, private
local Emitter
local is
local TypeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Rectangle = require("classes.Rectangle")
Vector    = require("classes.Vector")
Color     = require("classes.Color")

Emitter = require("classes.mixins.Emitter")

is = require("lib.is")

VectorSizeError = require("classes.errors.VectorSizeError")
TypeError       = require("classes.errors.TypeError")

Checkbox = Object:extend()

Checkbox:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local function toggle(_, event, self, ...)
    local p = private[self]
    
    self:dispatchSync(event, ...)
    
    p.state = not p.state
    
    self:dispatchSync(p.state and "enable" or "disable", ...)
end

    --======CONSTRUCTOR======--

function Checkbox:new(position, size)
    local p = private[self]

    TypeError:assert(is(position, Vector), "position", type(position), Vector)
    TypeError:assert(is(size, "number"), "size", type(size), "number")
    VectorSizeError:assert(position.size == 2, position.size, 2)

    p.outline = Rectangle(0, 0, size, size)
    p.body    = Rectangle(0, 0, size, size)

    p.body.mode = Rectangle.FILL

    p.outline.position = position
    p.body.position    = position

    p.origin = Vector:fromValues(0, 0)

    p.outline.color = Color:fromRGB(0, 0, 0, 1)
    p.body.color    = Color:fromRGB(1, 1, 1, 1)

    p.check_color = Color:fromRGB(0, 1, 0, 1)
    p.x_color     = Color:fromRGB(1, 0, 0, 1)

    p.outline.origin = p.origin
    p.body.origin    = p.origin

    p.state     = true
    p.thickness = 2
    
    p.body:onSync("fullclick", toggle, "toggle", self)
end

    --======METHODS======--

function Checkbox:draw()
    local p, size, color 
    
    p     = private[self]
    size  = p.body.height
    color = p[p.state and "check_color" or "x_color"]

    p.body:draw()
    p.outline:draw()

    color:apply()
    
    love.graphics.push()
    love.graphics.translate(p.body.position:unpack())
    love.graphics.translate(p.origin:invert(true):unpack())
    
    love.graphics.setLineWidth(p.thickness)

    if p.state then
        love.graphics.line(
            size * 0.775, size * 0.2,
            size * 0.475, size * 0.8,
            size * 0.275, size * 0.6
        )
    else
        love.graphics.line(
            size * 0.2, size * 0.2,
            size * 0.8, size * 0.8
        )
        love.graphics.line(
            size * 0.8, size * 0.2,
            size * 0.2, size * 0.8
        )
    end

    p.origin:invert(true)
    love.graphics.pop()
    
    color:remove()

    return self
end

function Checkbox:update(dt)
    local p = private[self]

    p.body:update(dt)

    return self
end

function Checkbox:mousepressed(...)
    private[self].body:mousepressed(...)

    return self
end

function Checkbox:mousereleased(...)
    private[self].body:mousereleased(...)
    
    return self
end

function Checkbox:mousemoved(...)
    private[self].body:mousemoved(...)

    return self
end

    --======GETTERS======--

function Checkbox.__get:outline_color()
    return private[self].outline.color
end

function Checkbox.__get:check_color()
    return private[self].check_color
end

function Checkbox.__get:x_color()
    return private[self].x_color
end

function Checkbox.__get:position()
    return private[self].body.position
end

function Checkbox.__get:origin()
    return private[self].body.origin
end

function Checkbox.__get:size()
    return private[self].body.height
end

function Checkbox.__get:body()
    return private[self].body
end

function Checkbox.__get:checked()
    return private[self].state
end
    
    --======SETTERS======--

function Checkbox.__set:position(value)
    local p = private[self]

    TypeError:assert(is(value, Vector), "position", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    p.body.position    = value
    p.outline.position = value
end

function Checkbox.__set:origin(value)
    local p = private[self]

    TypeError:assert(is(value, Vector), "origin", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    p.origin:setToVector(value)
end

function Checkbox.__set:size(value)
    local p = private[self]

    TypeError:assert(is(value, "number"), "size", type(value), "number")

    p.body.size:setToValues(value, value)
    p.outline.size:setToValues(value, value)
end

function Checkbox.__set:checked(value)
    private[self].state = not not value
end

    --======METAMETHODS======--

function Checkbox:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.state and "checked" or "unchecked") end

    return self:tostringHelper("Class")
end

Checkbox.__type = "checkbox"

return Checkbox