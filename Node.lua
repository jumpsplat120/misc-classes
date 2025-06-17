---@type Object
local Object
local Node, private, Rectangle, Vector, Color, Emitter, ChoiceNode, Font
local VectorSizeError, TypeError
local is

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

ChoiceNode = require("classes.ChoiceNode")
Rectangle  = require("classes.Rectangle")
Vector     = require("classes.Vector")
Color      = require("classes.Color")
Font       = require("classes.Font")

VectorSizeError = require("classes.errors.VectorSizeError")
TypeError       = require("classes.errors.TypeError")

is = require("lib.is")

Emitter = require("classes.mixins.Emitter")

Node = Object:extend()

Node:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local function event(_, event, self, ...)
    if private[self].plusdown then return end

    self:dispatchSync(event, ...)
end

local function plusdown(_, event, self, ...)
    private[self].plusdown = true
    
    self:dispatchSync(event, ...)
end

local function plusup(_, event, self, ...)
    private[self].plusdown = false

    self:dispatchSync(event, ...)
end

local function nocond(_, event, self, ...)
    self:dispatchSync(event, ...)
end

local function passthrough(self, event, node, ...)
    node:dispatchSync(event, self, ...)
end

    --======CONSTRUCTOR======--

function Node:new(position, size)
    local p = private[self]
    
    p.choices = {}
    p.plus    = {}
    p.from    = {}

    TypeError:assert(is(size, "number"), "size", type(size), "number")
    TypeError:assert(is(position, Vector), position, type(position), Vector)
    VectorSizeError:assert(position.size == 2, position.size, 2)

    p.size     = size
    p.scale    = 1
    p.position = position

    p.outline = Rectangle(p.position, p.size, p.size)
    p.body    = Rectangle(p.position, p.size, p.size)

    p.plus.outline = {}
    p.plus.body    = {}

    p.plus.hitbox    = Rectangle(p.position, p.size * 0.3, p.size * 0.3)
    p.plus.body.vert = Rectangle(p.position, p.size * 0.1, p.size * 0.3)
    p.plus.body.horz = Rectangle(p.position, p.size * 0.3, p.size * 0.1)
    p.plus.outline.vert = Rectangle(p.position, p.size * 0.1, p.size * 0.3)
    p.plus.outline.horz = Rectangle(p.position, p.size * 0.3, p.size * 0.1)
    
    p.draw_mouse_curve = false

    --Have all parts share the same single vector
    p.plus.outline.horz.position = p.position
    p.plus.outline.vert.position = p.position
    p.plus.body.horz.position = p.position
    p.plus.body.vert.position = p.position
    p.plus.hitbox.position    = p.position
    p.outline.position = p.position
    p.body.position    = p.position
    
    private[p.plus.outline.horz].drawable.origin
        :shiftByValues(-p.size, 0)                    --Right align
        :shiftByValues(p.size * 0.3, 0)               --Right align with right edge
        :shiftByValues(0, -p.size * 0.15)             --Center box
        :shiftByValues(p.size * 0.06, -p.size * 0.01) --Add buffer
    private[p.plus.outline.vert].drawable.origin
        :shiftByValues(-p.size, 0)
        :shiftByValues(p.size * 0.1,  0)
        :shiftByValues(p.size * 0.15, 0)
        :shiftByValues(p.size * 0.01, -p.size * 0.06)
    private[p.plus.hitbox].drawable.origin
        :shiftByValues(-p.size, 0)
        :shiftByValues(p.size * 0.3, 0)
        :shiftByValues(p.size * 0.06, -p.size * 0.06)
    
    private[p.plus.body.horz].drawable.origin = private[p.plus.outline.horz].drawable.origin
    private[p.plus.body.vert].drawable.origin = private[p.plus.outline.vert].drawable.origin

    p.body.mode           = Rectangle.FILL
    p.plus.hitbox.mode    = Rectangle.FILL
    p.plus.body.vert.mode = Rectangle.FILL
    p.plus.body.horz.mode = Rectangle.FILL

    p.outline.color = Color:fromRGB(0, 0, 0, 1)
    p.body.color    = Color:fromRGB(1, 1, 1, 1)

    p.plus.outline.vert.color = p.outline.color
    p.plus.body.vert.color    = Color:fromRGB(0.25, 0.25, 0.25, 1)
    p.plus.outline.horz.color = p.plus.outline.vert.color
    p.plus.body.horz.color    = p.plus.body.vert.color

    p.body:onSync("doubleclick", event, "doubleclick", self)
    p.body:onSync("fullclick", event, "fullclick", self)
    p.body:onSync("mouseover", event, "mouseover", self)
    p.body:onSync("mousedown", event, "mousedown", self)
    p.body:onSync("holddown", event, "holddown", self)
    p.body:onSync("mouseout", event, "mouseout", self)
    p.body:onSync("mousein", event, "mousein", self)
    p.body:onSync("dropout", event, "dropout", self)
    p.body:onSync("mouseup", event, "mouseup", self)
    p.body:onSync("dragout", event, "dragout", self)
    p.body:onSync("dropin", event, "dropin", self)
    p.body:onSync("dragin", event, "dragin", self)
    p.body:onSync("hover", event, "hover", self)
    p.body:onSync("drag", event, "drag", self)

    p.plus.hitbox:onSync("mousedown", plusdown, "plus.mousedown", self)
    p.plus.hitbox:onSync("fullclick", plusup, "plus.fullclick", self)
    p.plus.hitbox:onSync("mouseup", plusup, "plus.mouseup", self)
    p.plus.hitbox:onSync("dropout", plusup, "plus.dropout", self)

    p.plus.hitbox:onSync("mouseover", nocond, "plus.mouseover", self)
    p.plus.hitbox:onSync("holddown", nocond, "plus.holddown", self)
    p.plus.hitbox:onSync("mouseout", nocond, "plus.mouseout", self)
    p.plus.hitbox:onSync("mousein", nocond, "plus.mousein", self)
    p.plus.hitbox:onSync("dragout", nocond, "plus.dragout", self)
    p.plus.hitbox:onSync("dropin", nocond, "plus.dropin", self)
    p.plus.hitbox:onSync("dragin", nocond, "plus.dragin", self)
    p.plus.hitbox:onSync("hover", nocond, "plus.hover", self)
    p.plus.hitbox:onSync("drag", nocond, "plus.drag", self)
end

    --======METHODS======--

function Node:update(...)
    local p = private[self]

    p.plus.hitbox:update(...)
    p.body:update(...)

    for _, choice in ipairs(p.choices) do
        choice:update(...)
    end
end

function Node:mousepressed(...)
    local p = private[self]

    p.plus.hitbox:mousepressed(...)
    p.body:mousepressed(...)
    
    for _, choice in ipairs(p.choices) do
        choice:mousepressed(...)
    end

    return self
end

function Node:mousereleased(...)
    local p = private[self]

    p.plus.hitbox:mousereleased(...)
    p.body:mousereleased(...)

    for _, choice in ipairs(p.choices) do
        choice:mousereleased(...)
    end

    return self
end

function Node:mousemoved(...)
    local p = private[self]

    p.plus.hitbox:mousemoved(...)
    p.body:mousemoved(...)

    for _, choice in ipairs(p.choices) do
        choice:mousemoved(...)
    end

    return self
end

function Node:keypressed(...)
    local p = private[self]

    for _, choice in ipairs(p.choices) do
        choice:keypressed(...)
    end

    return self
end

function Node:keyreleased(...)
    local p = private[self]

    for _, choice in ipairs(p.choices) do
        choice:keyreleased(...)
    end
    
    return self
end

function Node:wheelmoved(...)
    local p = private[self]
    
    for _, choice in ipairs(p.choices) do
        choice:wheelmoved(...)
    end

    return self
end

function Node:textinput(...)
    local p = private[self]

    for _, choice in ipairs(p.choices) do
        choice:textinput(...)
    end
    
    return self
end

function Node:draw()
    local p, lw
    
    p  = private[self]
    lw = love.graphics.getLineWidth()
    
    love.graphics.setLineWidth(p.scale * 1.5)

    for _, choice in ipairs(p.choices) do
        choice:draw()
    end

    p.body:draw()

    p.plus.outline.vert:draw()
    p.plus.outline.horz:draw()
    p.plus.body.vert:draw()
    p.plus.body.horz:draw()

    p.outline:draw()

    love.graphics.setLineWidth(lw)
end

function Node:addChoice(success, tie, fail, scrollbar, font)
    local p, choice

    TypeError:assert(is(scrollbar, Color), "scrollbar", type(scrollbar), Color)
    TypeError:assert(is(success, Color), "success", type(success), Color)
    TypeError:assert(is(fail, Color), "fail", type(fail), Color)
    TypeError:assert(is(font, Font), "font", type(font), Font)
    TypeError:assert(is(tie, Color), "tie", type(tie), Color)

    p      = private[self]
    choice = ChoiceNode(
        self,
        p.position
            :clone()
            :shiftByValues(p.body.size.x * 1.05, 0),
        p.size * 0.4,
        font
    )

    choice.scrollbar_color = scrollbar
    choice.outline_color   = p.outline.color
    choice.success_color   = success
    choice.body_color      = p.body.color
    choice.fail_color      = fail
    choice.tie_color       = tie

    choice:onSync("doubleclick", passthrough, "choice.doubleclick", self)
    choice:onSync("fullclick", passthrough, "choice.fullclick", self)
    choice:onSync("mouseover", passthrough, "choice.mouseover", self)
    choice:onSync("mousedown", passthrough, "choice.mousedown", self)
    choice:onSync("holddown", passthrough, "choice.holddown", self)
    choice:onSync("mouseout", passthrough, "choice.mouseout", self)
    choice:onSync("mousein", passthrough, "choice.mousein", self)
    choice:onSync("dropout", passthrough, "choice.dropout", self)
    choice:onSync("mouseup", passthrough, "choice.mouseup", self)
    choice:onSync("dragout", passthrough, "choice.dragout", self)
    choice:onSync("dropin", passthrough, "choice.dropin", self)
    choice:onSync("dragin", passthrough, "choice.dragin", self)
    choice:onSync("hover", passthrough, "choice.hover", self)
    choice:onSync("drag", passthrough, "choice.drag", self)

    choice:onSync("success.doubleclick", passthrough, "choice.success.doubleclick", self)
    choice:onSync("success.fullclick", passthrough, "choice.success.fullclick", self)
    choice:onSync("success.mouseover", passthrough, "choice.success.mouseover", self)
    choice:onSync("success.mousedown", passthrough, "choice.success.mousedown", self)
    choice:onSync("success.holddown", passthrough, "choice.success.holddown", self)
    choice:onSync("success.mouseout", passthrough, "choice.success.mouseout", self)
    choice:onSync("success.mousein", passthrough, "choice.success.mousein", self)
    choice:onSync("success.dropout", passthrough, "choice.success.dropout", self)
    choice:onSync("success.mouseup", passthrough, "choice.success.mouseup", self)
    choice:onSync("success.dragout", passthrough, "choice.success.dragout", self)
    choice:onSync("success.dropin", passthrough, "choice.success.dropin", self)
    choice:onSync("success.dragin", passthrough, "choice.success.dragin", self)
    choice:onSync("success.hover", passthrough, "choice.success.hover", self)
    choice:onSync("success.drag", passthrough, "choice.success.drag", self)

    choice:onSync("fail.doubleclick", passthrough, "choice.fail.doubleclick", self)
    choice:onSync("fail.fullclick", passthrough, "choice.fail.fullclick", self)
    choice:onSync("fail.mouseover", passthrough, "choice.fail.mouseover", self)
    choice:onSync("fail.mousedown", passthrough, "choice.fail.mousedown", self)
    choice:onSync("fail.holddown", passthrough, "choice.fail.holddown", self)
    choice:onSync("fail.mouseout", passthrough, "choice.fail.mouseout", self)
    choice:onSync("fail.mousein", passthrough, "choice.fail.mousein", self)
    choice:onSync("fail.dropout", passthrough, "choice.fail.dropout", self)
    choice:onSync("fail.mouseup", passthrough, "choice.fail.mouseup", self)
    choice:onSync("fail.dragout", passthrough, "choice.fail.dragout", self)
    choice:onSync("fail.dropin", passthrough, "choice.fail.dropin", self)
    choice:onSync("fail.dragin", passthrough, "choice.fail.dragin", self)
    choice:onSync("fail.hover", passthrough, "choice.fail.hover", self)
    choice:onSync("fail.drag", passthrough, "choice.fail.drag", self)

    choice:onSync("tie.doubleclick", passthrough, "choice.tie.doubleclick", self)
    choice:onSync("tie.fullclick", passthrough, "choice.tie.fullclick", self)
    choice:onSync("tie.mouseover", passthrough, "choice.tie.mouseover", self)
    choice:onSync("tie.mousedown", passthrough, "choice.tie.mousedown", self)
    choice:onSync("tie.holddown", passthrough, "choice.tie.holddown", self)
    choice:onSync("tie.mouseout", passthrough, "choice.tie.mouseout", self)
    choice:onSync("tie.mousein", passthrough, "choice.tie.mousein", self)
    choice:onSync("tie.dropout", passthrough, "choice.tie.dropout", self)
    choice:onSync("tie.mouseup", passthrough, "choice.tie.mouseup", self)
    choice:onSync("tie.dragout", passthrough, "choice.tie.dragout", self)
    choice:onSync("tie.dropin", passthrough, "choice.tie.dropin", self)
    choice:onSync("tie.dragin", passthrough, "choice.tie.dragin", self)
    choice:onSync("tie.hover", passthrough, "choice.tie.hover", self)
    choice:onSync("tie.drag", passthrough, "choice.tie.drag", self)

    choice:onSync("options.scroll", passthrough, "options.scroll", self)

    choice:onSync("options.needs_roll.checkbox.disable", passthrough, "needs_roll.disable", self)
    choice:onSync("options.needs_roll.checkbox.enable", passthrough, "needs_roll.enable", self)
    choice:onSync("options.needs_roll.checkbox.toggle", passthrough, "needs_roll.toggle", self)
    choice:onSync("options.using_skill.text_input.cursor_blink", passthrough, "using_skill.cursor_blink", self)

    p.choices[#p.choices + 1] = choice

    return self
end

function Node:clone()
    local p = private[self]
    
    return Node({
        size  = p.size,
        scale = p.scale,
        position   = p.position:clone(),
        body_color = p.body.color:clone(),
        outline_color = p.outline.color:clone()
    })
end

    --======GETTERS======--

function Node.__get:size()
    return private[self].size
end

function Node.__get:position()
    return private[self].position
end

--TODO: Sort of Unsafe
function Node.__get:hitbox()
    return private[self].body
end

--TODO: Unsafe
function Node.__get:children()
    return private[self].choices
end

--TODO: Unsafe
function Node.__get:connections()
    return table.keys(private[self].from)
end

function Node.__get:plus_color()
    return private[self].plus.body.vert.color
end

function Node.__get:body_color()
    return private[self].body.color
end

function Node.__get:outline_color()
    return private[self].outline.color
end

function Node.__get:choices()
    return private[self].choices
end

    --======SETTERS======--

function Node.__set:plus_color(value)
    local p = private[self]

    TypeError:assert(is(value, Color), "plus_color", type(value), Color)

    p.plus.body.vert.color = value
    p.plus.body.horz.color = value
end

function Node.__set:body_color(value)
    TypeError:assert(is(value, Color), "body_color", type(value), Color)

    private[self].body.color = value
end

function Node.__set:outline_color(value)
    TypeError:assert(is(value, Color), "body_color", type(value), Color)

    private[self].outline.color = value
end

    --======METAMETHODS======--

function Node:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.body.position.x, p.body.position.y) end

    return self:tostringHelper("Class")
end

Node.__type = "node"

return Node