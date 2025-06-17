---@type Object
local Object
local ChoiceOptions, UsingSkill, NeedsRoll, Rectangle, Color, Font, Text, private
local Emitter
local VectorSizeError, TypeError
local is

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

UsingSkill = require("classes.UsingSkill")
NeedsRoll  = require("classes.NeedsRoll")
Rectangle  = require("classes.Rectangle")
Color      = require("classes.Color")
Font       = require("classes.Font")
Text       = require("classes.Text")

Emitter = require("classes.mixins.Emitter")

VectorSizeError = require("classes.errors.VectorSizeError")
TypeError       = require("classes.errors.TypeError")

is = require("lib.is")

ChoiceOptions = Object:extend()

ChoiceOptions:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local function event(_, event, self, ...)
    self:dispatchSync(event, ...)
end

    --======CONSTRUCTOR======--

function ChoiceOptions:new(position, size, font)
    local p, xoff, yoff, pos
    
    TypeError:assert(is(size, "number"), "size", type(size), "number")
    TypeError:assert(is(position, Vector), "position", type(position), Vector)
    TypeError:assert(is(font, Font), "font", type(font), Font)
    VectorSizeError:assert(position.size == 2, position.size, 2)

    p = private[self]
    
    p.rectangles = {}
    p.texts      = {}
    p.lines      = {}

    xoff = size * 6
    yoff = size * 3

    p.rectangles.body    = Rectangle(0, 0, xoff, yoff)
    p.rectangles.outline = Rectangle(0, 0, xoff, yoff)
    
    xoff = size * 0.27

    p.rectangles.scrollbar    = Rectangle(0, 0, xoff, yoff * 0.1)
    p.rectangles.scrollbar_bg = Rectangle(0, 0, xoff, yoff)

    xoff = size * 6 - xoff
    yoff = yoff * 0.3

    pos = Vector:fromValues(xoff, yoff)

    p.lines.needs_roll  = NeedsRoll(position, pos:clone(), font:clone())
    p.lines.using_skill = UsingSkill(position, pos:clone(), font:clone())

    p.rectangles.body.mode         = Rectangle.FILL
    p.rectangles.scrollbar.mode    = Rectangle.FILL
    p.rectangles.scrollbar_bg.mode = Rectangle.FILL

    p.rectangles.scrollbar_bg.color = Color:fromRGB(0.6, 0.6, 0.6, 1)
    p.rectangles.scrollbar.color    = Color:fromRGB(0.4, 0.4, 0.4, 1)

    p.rectangles.body.color      = Color:fromRGB(1, 1, 1, 1)
    p.rectangles.outline.color   = Color:fromRGB(0, 0, 0, 1)
    
    p.rectangles.body.position         = position
    p.rectangles.outline.position      = position
    p.rectangles.scrollbar.position    = position
    p.rectangles.scrollbar_bg.position = position

    xoff = -size * 0.2
    yoff = -size * 1.2
    
    p.origin = Vector:fromValues(0, 0)

    for _, line in pairs(p.lines) do
        local fs = line.text.font.size

        line.outline_color = p.rectangles.outline.color
        line.body.color    = p.rectangles.body.color

        --Magic number to get text to be sized nicely to the eye.
        line.text.font.size = fs * 0.5

        line.text
            :centerWithin(line.body, Text.VERTICAL)
            :finish()
            :pause()

        --Left padding
        line.text.origin:shiftByValues(fs * -0.25, 0)
    end

    self.scroll = 0

    p.check         = 0
    p.skill         = "do anything"
    p.choice_text   = ""
    p.needs_roll    = true
    p.skill_unlocks = {}

    p.rectangles.body:onSync("scroll", event, "scroll", self)

    p.lines.needs_roll:onSync("checkbox.disable", event, "needs_roll.checkbox.disable", self)
    p.lines.needs_roll:onSync("checkbox.enable", event, "needs_roll.checkbox.enable", self)
    p.lines.needs_roll:onSync("checkbox.toggle", event, "needs_roll.checkbox.toggle", self)
    p.lines.using_skill:onSync("text_input.cursor_blink", event, "using_skill.text_input.cursor_blink", self)
end

    --======METHODS======--

function ChoiceOptions:update(dt)
    local p = private[self]
    
    p.rectangles.body.origin:shiftByVector(p.origin)

    p.rectangles.body:update(dt)

    p.rectangles.body.origin:shiftByVector(p.origin:invert(true))

    p.origin:invert(true)

    for _, line in pairs(p.lines) do
        line.origin:shiftByVector(p.origin)

        line:update(dt)

        line.origin:shiftByVector(p.origin:invert(true))

        p.origin:invert(true)
    end
    
    return self
end

function ChoiceOptions:draw()
    local p = private[self]

    love.graphics.push()
    love.graphics.translate(p.origin:invert(true):unpack())

    ---@diagnostic disable-next-line: undefined-field
    --love.graphics.setStencilMode("replace", "always", 1)

    p.rectangles.body:draw()
    p.rectangles.scrollbar_bg:draw()
    p.rectangles.scrollbar:draw()

    ---@diagnostic disable-next-line: undefined-field
    --love.graphics.setStencilMode("keep", "equal", 1)

    for _, line in pairs(p.lines) do
        line:draw()
    end

    ---@diagnostic disable-next-line: undefined-field
    --love.graphics.setStencilMode()

    p.rectangles.outline:draw()
    
    p.origin:invert(true)
    love.graphics.pop()

    return self
end

function ChoiceOptions:mousepressed(...)
    local p = private[self]

    for _, line in pairs(p.lines) do
        if line.mousepressed then
            line.origin:shiftByVector(p.origin)

            line:mousepressed(...)

            line.origin:shiftByVector(p.origin:invert(true))

            p.origin:invert(true)
        end
    end

    return self
end

function ChoiceOptions:mousereleased(...)
    local p = private[self]

    for _, line in pairs(p.lines) do
        if line.mousereleased then
            line.origin:shiftByVector(p.origin)

            line:mousereleased(...)

            line.origin:shiftByVector(p.origin:invert(true))

            p.origin:invert(true)
        end
    end

    return self
end

function ChoiceOptions:mousemoved(...)
    local p = private[self]

    for _, line in pairs(p.lines) do
        if line.mousemoved then
            line.origin:shiftByVector(p.origin)

            line:mousemoved(...)

            line.origin:shiftByVector(p.origin:invert(true))

            p.origin:invert(true)
        end
    end

    return self
end

function ChoiceOptions:keypressed(...)
    local p = private[self]
    
    for _, line in pairs(p.lines) do
        if line.keypressed then line:keypressed(...) end
    end

    return self
end

function ChoiceOptions:keyreleased(...)
    local p = private[self]

    for _, line in pairs(p.lines) do
        if line.keyreleased then line:keyreleased(...) end
    end
    
    return self
end

function ChoiceOptions:wheelmoved(...)
    local p = private[self]
    
    p.rectangles.body.origin:shiftByVector(p.origin)
    
    p.rectangles.body:wheelmoved(...)

    p.rectangles.body.origin:shiftByVector(p.origin:invert(true))

    p.origin:invert(true)

    return self
end

function ChoiceOptions:textinput(...)
    local p = private[self]

    for _, line in pairs(p.lines) do
        if line.textinput then line:textinput(...) end
    end

    return self
end

    --======GETTERS======--
    
function ChoiceOptions.__get:body()
    return private[self].rectangles.body
end

function ChoiceOptions.__get:scroll()
    return private[self].scroll
end

function ChoiceOptions.__get:origin()
    return private[self].origin
end

    --======SETTERS======--

function ChoiceOptions.__set:body_color(value)
    local p = private[self]

    TypeError:assert(is(value, Color), "body_color", type(value), Color)

    p.rectangles.body.color = value

    for _, line in pairs(p.lines) do
        line.body.color = value
    end
end

function ChoiceOptions.__set:outline_color(value)
    local p = private[self]

    TypeError:assert(is(value, Color), "outline_color", type(value), Color)

    p.rectangles.outline.color = value

    for _, line in pairs(p.lines) do
        line.outline_color = value
    end
end

function ChoiceOptions.__set:scrollbar_color(value)
    TypeError:assert(is(value, Color), "scrollbar_color", type(value), Color)

    private[self].rectangles.scrollbar.color = value

end

function ChoiceOptions.__set:scrollbar_bg_color(value)
    TypeError:assert(is(value, Color), "scrollbar_bg_color", type(value), Color)

    private[self].rectangles.scrollbar_bg.color = value
end

function ChoiceOptions.__set:origin(value)
    TypeError:assert(is(value, Vector), "origin", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].origin:setToVector(value)
end

function ChoiceOptions.__set:scroll(value)
    local p, size, xoff, yoff
    
    p = private[self]

    TypeError:assert(is(value, "number"), "scroll", type(value), "number")

    p.scroll = value:clamp(0, 1)

    size = p.rectangles.body.width / 4
    xoff = -size * 0.2
    yoff = -size * 1.2
    
    for _, line in pairs(p.lines) do
        line.origin:setToValues(xoff, 0)
    end

    yoff = -p.lines.needs_roll.body.height

    p.lines.using_skill.origin:shiftByValues(0, yoff)

    yoff = p.scroll * -(p.rectangles.body.height - p.lines.needs_roll.body.height * 5)

    for _, line in pairs(p.lines) do
        line.origin:shiftByValues(0, yoff)
    end

    p.rectangles.scrollbar.origin
        :setToValues(0, 0)
        :shiftByValues(0, -(p.rectangles.body.height - p.rectangles.scrollbar.height) * p.scroll)
end
    
    --======METAMETHODS======--

function ChoiceOptions:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

ChoiceOptions.__type = "choice_options"

return ChoiceOptions