---@type Object
local Object
local ChoiceOptionLine, Vector, Rectangle, Color, private
local Emitter
local is
local TypeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Rectangle = require("classes.Rectangle")
Checkbox  = require("classes.Checkbox")
Vector    = require("classes.Vector")
Color     = require("classes.Color")

Emitter = require("classes.mixins.Emitter")

is = require("lib.is")

VectorSizeError = require("classes.errors.VectorSizeError")
TypeError       = require("classes.errors.TypeError")

ChoiceOptionLine = Object:extend()

ChoiceOptionLine:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function ChoiceOptionLine:new(text, position, size, font)
    local p = private[self]
    
    p.text = Text(text, font)
    
    p.outline = Rectangle(0, 0, size.x, size.y)
    p.body    = Rectangle(0, 0, size.x, size.y)

    p.origin = Vector:fromValues(0, 0)

    p.outline.position  = position
    p.body.position     = position
    p.text.position     = position

    p.body.mode = Rectangle.FILL

    p.outline.color = Color:fromRGB(0, 0, 0, 1)
    p.body.color    = Color:fromRGB(1, 1, 1, 1)
    p.text.color    = p.outline.color
    
    p.text
        :fitWithin(p.body)
        :centerWithin(p.body, Text.VERTICAL)
        :finish()
        :pause()
end

    --======METHODS======--

function ChoiceOptionLine:draw()
    local p = private[self]
    
    love.graphics.push()

    love.graphics.translate(p.origin:invert(true):unpack())
    
    p.body:draw()
    p.outline:draw()
    p.text:draw()

    p.origin:invert(true)
    love.graphics.pop()

    return self
end

function ChoiceOptionLine:update(dt)
    local p = private[self]

    p.text:update(dt)

    return self
end

    --======GETTERS======--

function ChoiceOptionLine.__get:outline_color()
    return private[self].outline.color
end

function ChoiceOptionLine.__get:position()
    return private[self].body.position
end

function ChoiceOptionLine.__get:origin()
    return private[self].origin
end

function ChoiceOptionLine.__get:body()
    return private[self].body
end

function ChoiceOptionLine.__get:text()
    return private[self].text
end
    
    --======SETTERS======--

function ChoiceOptionLine.__set:outline_color(value)
    local p = private[self]

    TypeError:assert(is(value, Color), "outline_color", type(value), Color)

    p.outline.color = value
    p.text.color    = value
end

function ChoiceOptionLine.__set:position(value)
    local p = private[self]

    p.outline.position = value
    p.body.position    = value
    p.text.position    = value
end

function ChoiceOptionLine.__set:origin(value)
    private[self].origin = value
end

function ChoiceOptionLine.__set:size(value)
    private[self].size = value
end

    --======METAMETHODS======--

function ChoiceOptionLine:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.text.text) end

    return self:tostringHelper("Class")
end

ChoiceOptionLine.__type = "choice_option_line"

return ChoiceOptionLine