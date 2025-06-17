local Object
local Rectangle, private, Vector, is, Symbol
local MouseInteractions, Drawable, Emitter
local VectorSizeError, TypeError, InvalidError

Symbol  = require("lib.Classy.Symbol")
Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Vector = require("classes.Vector")

MouseInteractions = require("classes.mixins.MouseInteractions")
Drawable          = require("classes.mixins.Drawable")
Emitter           = require("classes.mixins.Emitter")

is = require("lib.is")

VectorSizeError = require("classes.errors.VectorSizeError")
InvalidError    = require("classes.errors.InvalidError")
TypeError       = require("classes.errors.TypeError")

Rectangle = Object:extend()

Rectangle:implement(MouseInteractions, Drawable, Emitter)

    --======PRIVATE FUNCTIONS======--

local symbols

    --======STATIC======--

Rectangle.FILL = Symbol("fill")
Rectangle.LINE = Symbol("line")

private[Rectangle] = {
    [Rectangle.FILL] = true,
    [Rectangle.LINE] = true
}

symbols = table.join(table.keys(private[Rectangle]), ", ")

    --======CONSTRUCTOR======--

function Rectangle:new(a, b, c, d)
    local p = private[self]
    
    Drawable.new(self)
    MouseInteractions.new(self)

    if is(a, Vector) and is(b, Vector) then
        p.position = a:clone()
        p.size     = b:clone()
    elseif is(a, "number") and is(b, "number") and is(c, Vector) then
        p.position = Vector:fromValues(a, b)
        p.size     = c:clone()
    elseif is(a, Vector) and is(b, "number") and is(c, "number") then
        p.position = a:clone()
        p.size     = Vector:fromValues(b, c)
    elseif is(a, "number") and is(b, "number") and is(c, "number") and is(d, "number") then
        p.position = Vector:fromValues(a, b)
        p.size     = Vector:fromValues(c, d)
    else
        local ta, tb, tc, td

        ta = type(a)
        tb = type(b)
        tc = type(c)
        td = type(d)

        if ta == "vector" then
            TypeError:assert(tb == "number" or tb == "vector", "b", tb, "number/Vector")
            TypeError:throw("c", tc, "Vector")
        elseif ta == "number" then
            TypeError:assert(tb == "number", "b", tb, "number")
            TypeError:assert(tc == "number" or tc == "vector", "c", tc, "number/Vector")
            TypeError:throw("d", td, "number")
        else
            TypeError:throw("a", ta, "number/Vector")
        end
    end

    p.mode = Rectangle.LINE
end

    --======METHODS======--

function Rectangle:set(position, size)
    local p = private[self]
    
    if position then p.position:setToVector(position) end
    if size     then p.size:setToVector(size)         end

    return self
end

function Rectangle:matches(rectangle)
    local p = private[self]

    return p.position:matches(rectangle.position) and p.size:matches(rectangle.size)
end

function Rectangle:contains(vector)
    local x, y, p, origin

    p      = private[self]
    x, y   = vector:unpack()
    origin = p.drawable.origin
    
    return x >= p.position.x - origin.x and
           y >= p.position.y - origin.y and
           x <  p.position.x - origin.x + p.size.x and
           y <  p.position.y - origin.y + p.size.y
end

function Rectangle:touching(rectangle)
    local x, y, w, h, p, origin

    p = private[self]
    x, y, w, h = rectangle:unpack()
    origin = p.drawable.origin

    return p.position.x - origin.x + p.size.x >= x and
           p.position.x - origin.x <= x + w and
           p.position.y - origin.y + p.size.y >= y and
           p.position.y - origin.y <= y + h
end

function Rectangle:draw()
    local p = private[self]

    Drawable.apply(self)
    
    love.graphics.rectangle(p.mode.id, p.position.x, p.position.y, p.size.x, p.size.y)

    Drawable.remove(self)
end

function Rectangle:clone()
    local p = private[self]
    
    return Rectangle(p.position:clone(), p.size:clone())
end

function Rectangle:unpack()
    local p = private[self]

    return p.position.x, p.position.y, p.size.x, p.size.y
end

    --======GETTERS======--

function Rectangle.__get:size()
    return private[self].size
end

function Rectangle.__get:position()
    return private[self].position
end

function Rectangle.__get:mode()
    return private[self].mode
end

--======SETTERS======--

function Rectangle.__set:size(value)
    private[self].size:setToVector(value)
end

function Rectangle.__set:position(value)
    TypeError:assert(is(value, Vector), "position", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].position = value
end

function Rectangle.__set:mode(value)
    TypeError:assert(is(value, Symbol), "mode", type(value), Symbol)
    InvalidError:assert(private[Rectangle][value], value, "mode", symbols)

    private[self].mode = value
end

    --======METAMETHODS======--

function Rectangle:__tostring()
    local p = private[self]

    if self.is_instance then
        return self:tostringHelper(p.mode.id, p.position.x, p.position.y, p.size.x, p.size.y)
    else
        return self:tostringHelper("Class")
    end
end

Rectangle.__type = "rectangle"

return Rectangle
