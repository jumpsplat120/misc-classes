local ChoiceOptionLine
local UsingSkill, Rectangle, TextInput, Vector, Color, Line, private
local Emitter
local is
local TypeError

ChoiceOptionLine = require("classes.ChoiceOptionLine")
private          = require("lib.Classy.instances")

Rectangle = require("classes.Rectangle")
TextInput = require("classes.TextInput")
Vector    = require("classes.Vector")
Color     = require("classes.Color")
Line      = require("classes.Line")

Emitter = require("classes.mixins.Emitter")

is = require("lib.is")

VectorSizeError = require("classes.errors.VectorSizeError")
TypeError       = require("classes.errors.TypeError")

UsingSkill = ChoiceOptionLine:extend()

UsingSkill:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local function event(_, event, self, ...)
    self:dispatchSync(event, ...)
end

local function hitboxClicked(_, self)
    local p = private[self]

    p.active = true
    p.textinput.cursor_visible = true
end

    --======CONSTRUCTOR======--

function UsingSkill:new(position, size, font)
    local p
    
    p = private[self]

    ChoiceOptionLine.new(self, "Using Skill", position, size, font)

    p.hitbox    = Rectangle(0, 0, size.x * 0.5, size.y)
    p.textinput = TextInput(font:clone())
    p.underline = Line:fromVectors(Vector:fromValues(0, size.y * 0.8), Vector:fromValues(size.x * 0.5, size.y * 0.8))
    
    p.hitbox.position       = position
    p.textinput.position    = position
    p.underline.translation = position

    p.textinput.color = p.outline.color
    p.underline.color = p.outline.color
    
    p.textinput:fit(p.hitbox, p.hitbox.height * 0.1)

    p.textinput.textbox.wrap = math.huge
    
    p.hitbox.origin:shiftByValues(-(size.x - p.hitbox.width), 0)
    p.underline.origin:shiftByValues(-(size.x - p.hitbox.width), 0)
    p.textinput.origin:shiftByValues(-(size.x - p.hitbox.width), 0)

    p.textinput:onSync("cursor_blink", event, "text_input.cursor_blink", self)
    --TODO: Get text to slide left/right or w/e when typing so we can always see text
    p.textinput:onSync("text_changed")
    p.hitbox:onSync("mousedown", hitboxClicked, self)
end

    --======METHODS======--

function UsingSkill:draw()
    local p = private[self]

    ChoiceOptionLine.draw(self)

    love.graphics.push()

    love.graphics.translate(p.origin:invert(true):unpack())

    p.textinput:draw()
    p.underline:draw()

    p.origin:invert(true)

    love.graphics.pop()

    return self
end

function UsingSkill:update(dt)
    local p = private[self]

    ChoiceOptionLine.update(self, dt)

    p.textinput:update(dt)

    return self
end

function UsingSkill:mousepressed(...)
    local p = private[self]
    
    p.hitbox.position:shiftByVector(p.origin:invert(true))

    p.hitbox:mousepressed(...)

    --Special case for everything outside the hitbox. Might consider TODO; adding
    --this functionality to MouseInteractions. We'll have to see how often this
    --is something that we want to do.
    if not p.hitbox:contains(game.mouse.position) then
        p.active = false
        p.textinput.cursor_visible = false
    end

    p.hitbox.position:shiftByVector(p.origin:invert(true))

    return self
end

function UsingSkill:mousereleased(...)
    local p = private[self]

    p.hitbox.position:shiftByVector(p.origin:invert(true))

    p.hitbox:mousereleased(...)
    
    p.hitbox.position:shiftByVector(p.origin:invert(true))

    return self
end

function UsingSkill:mousemoved(...)
    local p = private[self]

    p.hitbox.position:shiftByVector(p.origin:invert(true))

    p.hitbox:mousemoved(...)

    p.hitbox.position:shiftByVector(p.origin:invert(true))

    return self
end

function UsingSkill:keypressed(...)
    local p = private[self]

    if p.active then
        p.textinput:keypressed(...)
    end

    return self
end

function UsingSkill:keyreleased(...)
    local p = private[self]

    if p.active then
        p.textinput:keyreleased(...)
    end

    return self
end

function UsingSkill:textinput(...)
    local p = private[self]
    
    if p.active then
        p.textinput:textinput(...)
    end

    return self
end

    --======GETTERS======--
    
    --======SETTERS======--

    --======METAMETHODS======--

function UsingSkill:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.textinput.text) end

    return self:tostringHelper("Class")
end

UsingSkill.__type = "using_skill"

return UsingSkill