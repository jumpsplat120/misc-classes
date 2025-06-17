local ChoiceOptionLine
local NeedsRoll, Checkbox, Vector, private
local Emitter
local is
local TypeError

ChoiceOptionLine = require("classes.ChoiceOptionLine")
private          = require("lib.Classy.instances")

Checkbox  = require("classes.Checkbox")
Vector    = require("classes.Vector")
Color     = require("classes.Color")

Emitter = require("classes.mixins.Emitter")

is = require("lib.is")

VectorSizeError = require("classes.errors.VectorSizeError")
TypeError       = require("classes.errors.TypeError")

NeedsRoll = ChoiceOptionLine:extend()

NeedsRoll:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local function event(_, event, self, ...)
    self:dispatchSync(event, ...)
end

    --======CONSTRUCTOR======--

function NeedsRoll:new(position, size, font)
    local p, offset
    
    p = private[self]

    ChoiceOptionLine.new(self, "Needs Roll", position, size, font)

    p.checkbox = Checkbox(position, size.y * 0.8)

    p.checkbox.position = position
    
    offset = (size.y - p.checkbox.size) * -0.5

    p.checkbox.origin
        :shiftByVector(-size)
        :shiftByValues(p.checkbox.size, p.checkbox.size)
        :shiftByValues(-offset + size.y * 0.05, -offset)

    p.checkbox:onSync("disable", event, "checkbox.disable", self)
    p.checkbox:onSync("toggle", event, "checkbox.toggle", self)
    p.checkbox:onSync("enable", event, "checkbox.enable", self)
end

    --======METHODS======--

function NeedsRoll:draw()
    local p = private[self]

    ChoiceOptionLine.draw(self)

    love.graphics.push()
    love.graphics.translate(p.origin:invert(true):unpack())

    p.checkbox:draw()

    p.origin:invert(true)
    love.graphics.pop()

    return self
end

function NeedsRoll:update(dt)
    local p = private[self]

    ChoiceOptionLine.update(self, dt)

    p.checkbox:update(dt)

    return self
end

function NeedsRoll:mousepressed(...)
    local p = private[self]

    p.checkbox.position:shiftByVector(p.origin:invert(true))

    p.checkbox:mousepressed(...)

    p.checkbox.position:shiftByVector(p.origin:invert(true))

    return self
end

function NeedsRoll:mousereleased(...)
    local p = private[self]

    p.checkbox.position:shiftByVector(p.origin:invert(true))

    p.checkbox:mousereleased(...)
    
    p.checkbox.position:shiftByVector(p.origin:invert(true))

    return self
end

function NeedsRoll:mousemoved(...)
    local p = private[self]

    p.checkbox.position:shiftByVector(p.origin:invert(true))

    p.checkbox:mousemoved(...)

    p.checkbox.position:shiftByVector(p.origin:invert(true))

    return self
end

    --======GETTERS======--

function NeedsRoll.__get:checkbox()
    return private[self].checkbox
end
    
    --======SETTERS======--

    --======METAMETHODS======--

function NeedsRoll:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.checkbox.checked) end

    return self:tostringHelper("Class")
end

NeedsRoll.__type = "needs_roll"

return NeedsRoll