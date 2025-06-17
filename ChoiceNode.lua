---@type Object
local Object
local ChoiceNode, Symbol, Rectangle, Color, Triangle, Node, Font, ChoiceOptions, Vector, Game, private
local Emitter
local VectorSizeError, TypeError
local is

Object  = require("lib.Classy")
Symbol  = require("lib.Classy.Symbol")
private = require("lib.Classy.instances")

ChoiceOptions = require("classes.ChoiceOptions")
Rectangle     = require("classes.Rectangle")
Triangle      = require("classes.Triangle")
Vector        = require("classes.Vector")
Color         = require("classes.Color")
Font          = require("classes.Font")
Game          = require("classes.Game")
Text          = require("classes.Text")

Emitter = require("classes.mixins.Emitter")

VectorSizeError = require("classes.errors.VectorSizeError")
TypeError       = require("classes.errors.TypeError")

is = require("lib.is")

ChoiceNode = Object:extend()

ChoiceNode:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local game
local SUCCESS, FAIL, TIE

game = Game()

SUCCESS = Symbol("success")
FAIL    = Symbol("fail")
TIE     = Symbol("tie")

ChoiceNode.SUCCESS = SUCCESS
ChoiceNode.FAIL    = FAIL
ChoiceNode.TIE     = TIE

local function curve(a, b)
    local c, d, dir

    c   = a:lerp(b, 0.65)
    d   = a:lerp(b, 0.35)
    dir = (a - b)
        :normalize(true)
        :rotate2D(a.y > b.y and -90 or 90, true)
        :multiply(math.min(math.abs(c.x - d.x), math.abs(c.y - d.y)), true)
        :multiply(a.x > b.x and -1 or 1, true)

    c:shiftByVector(dir)
    d:shiftByVector(dir:invert(true))

    return love.math.newBezierCurve({
        a.x, a.y,
        c.x, c.y,
        d.x, d.y,
        b.x, b.y
    })
end

local function event(_, event, self, ...)
    self:dispatchSync(event, ...)
end

    --======CONSTRUCTOR======--

function ChoiceNode:new(parent, position, size, font)
    local p = private[self]
    
    --To avoid recursive requiring, require it on first construction.
    if not Node then Node = require("classes.Node") end

    p.connections = {}

    TypeError:assert(is(parent, Node), "parent", type(parent), Node)
    TypeError:assert(is(position, Vector), "position", type(position), Vector)
    TypeError:assert(is(size, "number"), "size", type(size), "number")
    TypeError:assert(is(font, Font), "font", type(font), Font)
    VectorSizeError:assert(position.size == 2, position.size, 2)

    p.text    = Text("0", font)
    p.body    = Rectangle(0, 0, size, size)
    p.outline = Rectangle(0, 0, size, size)
    p.options = ChoiceOptions(position, size, font)

    p.success = Triangle(position, size * 0.3)
    p.fail    = Triangle(position, size * 0.3)
    p.tie     = Triangle(position, size * 0.3)
    p.success_outline = Triangle(position, size * 0.3)
    p.fail_outline    = Triangle(position, size * 0.3)
    p.tie_outline     = Triangle(position, size * 0.3)

    p.success.mode = Triangle.FILL
    p.fail.mode    = Triangle.FILL
    p.tie.mode     = Triangle.FILL

    p.body.mode = Rectangle.FILL

    p.success.color = Color:fromRGB(0, 1, 0, 1)
    p.fail.color    = Color:fromRGB(1, 0, 0, 1)
    p.tie.color     = Color:fromRGB(0, 1, 1, 1)

    p.body.color    = Color:fromRGB(1, 1, 1, 1)
    p.outline.color = Color:fromRGB(0, 0, 0, 1)

    p.success_outline.color = p.outline.color
    p.fail_outline.color    = p.outline.color
    p.tie_outline.color     = p.outline.color

    p.body.position    = position
    p.outline.position = position

    p.success.origin:setToValues(-size * 1.1, 0)
    p.fail.origin:setToValues(-size * 1.1, -size + size * 0.3)
    p.tie.origin:setToValues(-size * 1.1, -size * 0.5 + size * 0.15)

    p.success_outline.origin:setToVector(p.success.origin)
    p.fail_outline.origin:setToVector(p.fail.origin)
    p.tie_outline.origin:setToVector(p.tie.origin)

    p.options.origin:shiftByValues(0, -size * 1.1)

    p.text.color    = p.outline.color
    p.text.position = p.body.position

    p.text:fitWithin(p.body)

    p.text
        :centerWithin(p.body, Text.BOTH)
        :finish()
        :pause()

    p.parent = parent

    self:recurve(p.parent)

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

    p.success:onSync("doubleclick", event, "success.doubleclick", self)
    p.success:onSync("fullclick", event, "success.fullclick", self)
    p.success:onSync("mouseover", event, "success.mouseover", self)
    p.success:onSync("mousedown", event, "success.mousedown", self)
    p.success:onSync("holddown", event, "success.holddown", self)
    p.success:onSync("mouseout", event, "success.mouseout", self)
    p.success:onSync("mousein", event, "success.mousein", self)
    p.success:onSync("dropout", event, "success.dropout", self)
    p.success:onSync("mouseup", event, "success.mouseup", self)
    p.success:onSync("dragout", event, "success.dragout", self)
    p.success:onSync("dropin", event, "success.dropin", self)
    p.success:onSync("dragin", event, "success.dragin", self)
    p.success:onSync("hover", event, "success.hover", self)
    p.success:onSync("drag", event, "success.drag", self)

    p.fail:onSync("doubleclick", event, "fail.doubleclick", self)
    p.fail:onSync("fullclick", event, "fail.fullclick", self)
    p.fail:onSync("mouseover", event, "fail.mouseover", self)
    p.fail:onSync("mousedown", event, "fail.mousedown", self)
    p.fail:onSync("holddown", event, "fail.holddown", self)
    p.fail:onSync("mouseout", event, "fail.mouseout", self)
    p.fail:onSync("mousein", event, "fail.mousein", self)
    p.fail:onSync("dropout", event, "fail.dropout", self)
    p.fail:onSync("mouseup", event, "fail.mouseup", self)
    p.fail:onSync("dragout", event, "fail.dragout", self)
    p.fail:onSync("dropin", event, "fail.dropin", self)
    p.fail:onSync("dragin", event, "fail.dragin", self)
    p.fail:onSync("hover", event, "fail.hover", self)
    p.fail:onSync("drag", event, "fail.drag", self)

    p.tie:onSync("doubleclick", event, "tie.doubleclick", self)
    p.tie:onSync("fullclick", event, "tie.fullclick", self)
    p.tie:onSync("mouseover", event, "tie.mouseover", self)
    p.tie:onSync("mousedown", event, "tie.mousedown", self)
    p.tie:onSync("holddown", event, "tie.holddown", self)
    p.tie:onSync("mouseout", event, "tie.mouseout", self)
    p.tie:onSync("mousein", event, "tie.mousein", self)
    p.tie:onSync("dropout", event, "tie.dropout", self)
    p.tie:onSync("mouseup", event, "tie.mouseup", self)
    p.tie:onSync("dragout", event, "tie.dragout", self)
    p.tie:onSync("dropin", event, "tie.dropin", self)
    p.tie:onSync("dragin", event, "tie.dragin", self)
    p.tie:onSync("hover", event, "tie.hover", self)
    p.tie:onSync("drag", event, "tie.drag", self)

    p.options:onSync("scroll", event, "options.scroll", self)
    
    p.options:onSync("needs_roll.checkbox.disable", event, "options.needs_roll.checkbox.disable", self)
    p.options:onSync("needs_roll.checkbox.enable", event, "options.needs_roll.checkbox.enable", self)
    p.options:onSync("needs_roll.checkbox.toggle", event, "options.needs_roll.checkbox.toggle", self)
    p.options:onSync("using_skill.text_input.cursor_blink", event, "options.using_skill.text_input.cursor_blink", self)
end

    --======METHODS======--

function ChoiceNode:update(dt)
    local p = private[self]

    p.body:update(dt)

    if p.draw_options then
        p.options:update(dt)
    end

    p.success:update(dt)
    p.fail:update(dt)
    p.tie:update(dt)

    p.text:update(dt)

    return self
end

function ChoiceNode:draw()
    local p, lw
    
    p  = private[self]
    lw = love.graphics.getLineWidth()

    p.outline.color:apply()

    love.graphics.line(p.curve:render())

    p.outline.color:remove()

    if p.mouse_curve then
        local bez = curve(
            p.mouse_curve,
            game.mouse.position
        )

        for i = 0, 0.95, 0.05 do
            p.curve_from.color:blend(p.outline.color, p.outline.color.LIGHTEN, i):apply()

            love.graphics.line(bez:renderSegment(i, math.min(i + 0.11, 1)))
        end
    end

    for _, connection in pairs(p.connections) do
        for _, segment in ipairs(connection.segments) do
            segment.color:apply()
            
            love.graphics.line(segment.vertices)

            segment.color:remove()
        end
    end

    p.body:draw()
    p.outline:draw()

    p.success:draw()
    p.fail:draw()
    p.tie:draw()

    love.graphics.setLineWidth(1)

    p.success_outline:draw()
    p.fail_outline:draw()
    p.tie_outline:draw()

    love.graphics.setLineWidth(lw)
    
    p.text:draw()

    if p.draw_options then
        p.options:draw()
    end

    return self
end

function ChoiceNode:mousemoved(...)
    local p = private[self]

    p.body:mousemoved(...)

    if p.draw_options then
        p.options:mousemoved(...)
    end

    p.success:mousemoved(...)
    p.fail:mousemoved(...)
    p.tie:mousemoved(...)

    return self
end

function ChoiceNode:mousereleased(...)
    local p = private[self]

    p.body:mousereleased(...)

    if p.draw_options then
        p.options:mousereleased(...)
    end

    p.success:mousereleased(...)
    p.fail:mousereleased(...)
    p.tie:mousereleased(...)

    return self
end

function ChoiceNode:mousepressed(...)
    local p = private[self]

    p.body:mousepressed(...)
    
    if p.draw_options then
        p.options:mousepressed(...)
    end

    p.success:mousepressed(...)
    p.fail:mousepressed(...)
    p.tie:mousepressed(...)

    return self
end

function ChoiceNode:keypressed(...)
    local p = private[self]

    if p.draw_options then
        p.options:keypressed(...)
    end

    return self
end

function ChoiceNode:keyreleased(...)
    local p = private[self]

    if p.draw_options then
        p.options:keyreleased(...)
    end

    return self
end

function ChoiceNode:wheelmoved(...)
    local p = private[self]
    
    if p.draw_options then
        p.options:wheelmoved(...)
    end

    return self
end

function ChoiceNode:textinput(...)
    local p = private[self]

    if p.draw_options then
        p.options:textinput(...)
    end

    return self
end

function ChoiceNode:connect(to, node)
    local p1, p2, tbl
    
    p1 = private[self]
    p2 = private[node]
    
    tbl  = {
        node     = node,
        color    = p1[to.id].color,
        curve    = curve(
            p1[to.id]:vertex(3),
            node.position
                :clone()
                :shiftByValues(0, node.size * 0.5)
        ),
        segments = {}
    }

    for i = 1, 20, 1 do    
        i = (i - 1) * 0.05

        tbl.segments[#tbl.segments + 1] = {
            color    = tbl.color:blend(p1.outline.color, p1.outline.color.LIGHTEN, i),
            vertices = tbl.curve:renderSegment(i, math.min(i + 1.1, 1))
        }
    end

    p1.connections[to] = tbl
    
    p2.from[self] = true

    return self
end

function ChoiceNode:disconnect(to)
    local p1, p2, tbl
    
    p1 = private[self]

    if not p1.connections[to] then return self end

    tbl = p1.connections[to]
    p2  = private[tbl.node]

    p1.connections[to] = nil
    p2.from[self]      = nil

    return self
end

function ChoiceNode:connected(to, node)
    return private[self].connections[to.id] == node
end

function ChoiceNode:recurve(node)
    local p = private[self]

    if node == p.parent then
        p.curve = curve(
            p.outline.position
                :clone()
                :shiftByValues(0, p.body.size.x * 0.5),
            p.parent.position
                :clone()
                :shiftByValues(p.parent.size, p.parent.size * 0.5)
            )
    else
        for key, connection in pairs(p.connections) do

            if node == connection.node then
                local tbl, segcolors

                segcolors = connection.segments
                tbl       = {
                    node     = connection.node,
                    color    = p[key.id].color,
                    curve    = curve(
                        p[key.id]:vertex(3),
                        connection.node.position
                            :clone()
                            :shiftByValues(0, connection.node.size * 0.5)
                    ),
                    segments = {}
                }
                
                --https://discord.com/channels/329400828920070144/329404715521802241/1206017998427783198
                --10 + 1 ~= 0.5 * 20 + 1 because floating point math.
                for i = 1, 20, 1 do
                    local x = (i - 1) * 0.05

                    tbl.segments[i] = {
                        color    = segcolors[i].color,
                        vertices = tbl.curve:renderSegment(x, math.min(x + 1.1, 1))
                    }
                end
        
                p.connections[key] = tbl
            end
        end
    end

    return self
end

function ChoiceNode:mouseCurveFrom(location)
    local p = private[self]

    if not location then
        p.curve_from  = nil
        p.mouse_curve = nil

        return self
    end

    p.curve_from  = p[location.id]
    p.mouse_curve = p.curve_from:vertex(3)

    return self
end

    --======GETTERS======--

function ChoiceNode.__get:body()
    return private[self].body
end

function ChoiceNode.__get:outline()
    return private[self].outline
end

function ChoiceNode.__get:options()
    return private[self].options.body
end

function ChoiceNode.__get:position()
    return private[self].body.position
end

function ChoiceNode.__get:parent()
    return private[self].parent
end

function ChoiceNode.__get:success_node()
    return table.deepget(private[self].connections, SUCCESS, "node")
end

function ChoiceNode.__get:fail_node()
    return table.deepget(private[self].connections, FAIL, "node")
end

function ChoiceNode.__get:tie_node()
    return table.deepget(private[self].connections, TIE, "node")
end

function ChoiceNode.__get:draw_options()
    return private[self].draw_options
end

function ChoiceNode.__get:scroll()
    return private[self].options.scroll
end

    --======SETTERS======--
    
function ChoiceNode.__set:body_color(value)
    local p = private[self]

    TypeError:assert(is(value, Color), "body_color", type(value), Color)

    p.body.color         = value
    p.options.body_color = value
end

function ChoiceNode.__set:outline_color(value)
    local p = private[self]

    TypeError:assert(is(value, Color), "outline_color", type(value), Color)

    p.options.outline_color = value
    p.success_outline.color = value
    p.fail_outline.color    = value
    p.tie_outline.color     = value
    p.outline.color         = value
    p.text.color            = value
end

function ChoiceNode.__set:success_color(value)
    TypeError:assert(is(value, Color), "success_color", type(value), Color)

    private[self].success.color = value
end

function ChoiceNode.__set:fail_color(value)
    TypeError:assert(is(value, Color), "fail_color", type(value), Color)

    private[self].fail.color = value
end

function ChoiceNode.__set:tie_color(value)
    TypeError:assert(is(value, Color), "tie_color", type(value), Color)

    private[self].tie.color = value
end

function ChoiceNode.__set:scrollbar_color(value)
    TypeError:assert(is(value, Color), "scrollbar_color", type(value), Color)

    private[self].options.scrollbar_color = value
end

function ChoiceNode.__set:scrollbar_bg_color(value)
    TypeError:assert(is(value, Color), "scrollbar_bg_color", type(value), Color)

    private[self].options.scrollbar_bg_color = value
end

function ChoiceNode.__set:draw_options(value)
    private[self].draw_options = not not value
end

function ChoiceNode.__set:scroll(value)
    TypeError:assert(is(value, "number"), "scroll", type(value), "number")

    private[self].options.scroll = value
end

    --======METAMETHODS======--

function ChoiceNode:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

ChoiceNode.__type = "choice_node"

return ChoiceNode