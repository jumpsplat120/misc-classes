---@type Object
local Object
local Triangle, Symbol, private
local MouseInteractions, Drawable, Emitter

Object  = require("lib.Classy")
Symbol  = require("lib.Classy.Symbol")
private = require("lib.Classy.instances")

MouseInteractions = require("classes.mixins.MouseInteractions")
Drawable          = require("classes.mixins.Drawable")
Emitter           = require("classes.mixins.Emitter")

Triangle = Object:extend()

Triangle:implement(MouseInteractions, Drawable, Emitter)

    --======PRIVATE FUNCTIONS======--

local FILL, LINE

FILL = Symbol("fill")
LINE = Symbol("line")

local function getverts(size)
    return {
        0,    0,
        0,    size,
        size, size * 0.5
    }
end

Triangle.FILL = FILL
Triangle.LINE = LINE

    --======CONSTRUCTOR======--

function Triangle:new(position, size)
    local p = private[self]

    Drawable.new(self)
    MouseInteractions.new(self)
    
    --TODO: Assertations
    p.mode     = LINE
    p.size     = size
    p.vertices = getverts(size)
    p.position = position
end

    --======METHODS======--

function Triangle:draw()
    local p = private[self]

    Drawable.apply(self)
    
    love.graphics.push()
    love.graphics.translate(p.position:unpack())
    love.graphics.polygon(p.mode.id, p.vertices)
    love.graphics.pop()

    Drawable.remove(self)
end

--The barycentric method.
--http://totologic.blogspot.com/2014/01/accurate-point-in-triangle-test.html
function Triangle:contains(vector)
    local p, p1, p2, p3
    local a, b, c, d, e
    local s, t, sub, denominator

    p = private[self]
    v = p.vertices

    p1 = self:vertex(1)
    p2 = self:vertex(2)
    p3 = self:vertex(3)

    a = p2.y - p3.y
    b = p1.x - p3.x
    c = p3.x - p2.x
    d = vector.x - p3.x
    e = vector.y - p3.y

    denominator = a * b + c * (p1.y - p3.y)

    s = (a * d + c * e) / denominator

    if s < 0 then return end
    if s > 1 then return end

    t = ((p3.y - p1.y) * d + b * e) / denominator

    if t < 0 then return end
    if t > 1 then return end

    sub = 1 - s - t

    return 0 <= sub and sub <= 1
end

function Triangle:vertex(point)
    local p, vertex
    
    p = private[self]

    vertex = p.position
        :clone()
        :shiftByVector(p.drawable.origin:invert(true))
        :shiftByTable({
            p.vertices[point * 2 - 1],
            p.vertices[point * 2]
        })
    
    p.drawable.origin:invert(true)

    return vertex
end

    --======GETTERS======--

function Triangle.__get:mode()
    return private[self].mode
end

function Triangle.__get:position()
    return private[self].position
end

function Triangle.__get:size()
    return private[self].size
end

    --======SETTERS======--
    
function Triangle.__set:mode(value)
    private[self].mode = value
end

    --======METAMETHODS======--

function Triangle:__tostring()
    local p = private[self]
    
    if self.is_instance then return self:tostringHelper(self:vertex(1), self:vertex(2), self:vertex(3)) end

    return self:tostringHelper("Class")
end

Triangle.__type = "Triangle"

return Triangle