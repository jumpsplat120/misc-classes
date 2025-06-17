local Object, private
local Playspace, Line, Vector, Rectangle, Color, Image
local ParameterAmountError, VectorSizeError, RangeError, TypeError, LengthError
local Drawable
local is

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Line      = require("classes.Line")
Color     = require("classes.Color")
Image     = require("classes.Image")
Vector    = require("classes.Vector")
Rectangle = require("classes.Rectangle")

ParameterAmountError = require("classes.errors.ParameterAmountError")
VectorSizeError      = require("classes.errors.VectorSizeError")
LengthError          = require("classes.errors.LengthError")
RangeError           = require("classes.errors.RangeError")
TypeError            = require("classes.errors.TypeError")

is = require("lib.is")

Playspace = Object:extend()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Playspace:new(paths, size, scale)
    local p = private[self]

    --TODO: Magic number
    --TODO: Error checking
    p.size    = size
    p.scale   = scale
    p.offset  = math.floor(p.size * 0.5)
    p.y_level = 0
    
    p.images = {
        love.graphics.newImage(paths[1]),
        love.graphics.newImage(paths[2])
    }

    p.colors = {
        Color:fromRGB(0.625, 0.625, 0.625, 1),
        Color:fromRGB(1, 1, 1, 1),
    }

    p.quads = {
        love.graphics.newQuad(0, 0, size, size, p.images[1]),
        love.graphics.newQuad(0, 0, size, size, p.images[2])
    }

    p.images[1]:setWrap("repeat", "repeat")
    p.images[2]:setWrap("repeat", "repeat")
end

    --======METHODS======--

function Playspace:draw()
    local p = private[self]
    
    p.colors[1]:apply()
    love.graphics.draw(p.images[1], p.quads[1], 0, 0, 0, 1, 1, p.offset, p.offset)
    p.colors[1]:remove()

    p.colors[2]:apply()
    love.graphics.draw(p.images[2], p.quads[2], 0, 0, 0, 1, 1, p.offset, p.offset)
    p.colors[2]:remove()
end

--TODO: Add error checking. This converts an x, y that you'd get from mousemoved
--and turns ito into a location on the board.
function Playspace:convert(x, z)
    local p = private[self]

    return Vector:fromValues(
        math.floor(x / p.scale),
        p.y_level,
        -math.floor(z / p.scale)
    )
end

    --======GETTERS======--

function Playspace.__get:scale()
    return private[self].scale
end

function Playspace.__get:y_level()
    return private[self].y_level
end

    --======SETTERS======--

--TODO: Error checking
function Playspace.__set:y_level(value)
    private[self].y_level = value
end

    --======METAMETHODS======--

function Playspace:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

Playspace.__type = "playspace"

return Playspace