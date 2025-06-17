---@type Object
local Object
local Text, Font, Color, Symbol, Vector, Rectangle, slog, private, is
local Drawable, Emitter
local TypeError, InvalidError, VectorSizeError, RangeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")
Symbol  = require("lib.Classy.Symbol")

Emitter  = require("classes.mixins.Emitter")
Drawable = require("classes.mixins.Drawable")

Font      = require("classes.Font")
Color     = require("classes.Color")
Vector    = require("classes.Vector")
Rectangle = require("classes.Rectangle")

TypeError       = require("classes.errors.TypeError")
RangeError      = require("classes.errors.RangeError")
InvalidError    = require("classes.errors.InvalidError")
VectorSizeError = require("classes.errors.VectorSizeError")

is = require("lib.is")

slog = require("third_party.slog")

Text = Object:extend()

Text:implement(Drawable, Emitter)

    --======PRIVATE FUNCTIONS======--

local LEFT, RIGHT, CENTER, JUSTIFY
local HORIZONTAL, VERTICAL, BOTH
local alignments, centering

LEFT    = Symbol("left")
RIGHT   = Symbol("right")
CENTER  = Symbol("center")
JUSTIFY = Symbol("justify")

HORIZONTAL = Symbol("horizontal")
VERTICAL   = Symbol("vertical")
BOTH       = Symbol("both")

private[Text] = {
    alignments = {
        [LEFT]    = true,
        [RIGHT]   = true,
        [CENTER]  = true,
        [JUSTIFY] = true
    },
    centering = {
        [HORIZONTAL] = true,
        [VERTICAL]   = true,
        [BOTH]       = true
    }
}

Text.LEFT    = LEFT
Text.RIGHT   = RIGHT
Text.CENTER  = CENTER
Text.JUSTIFY = JUSTIFY

Text.HORIZONTAL = HORIZONTAL
Text.VERTICAL   = VERTICAL
Text.BOTH       = BOTH

alignments = table.join(table.keys(private[Text].alignments), ", ")
centering  = table.join(table.keys(private[Text].centering), ", ")

    --======CONSTRUCTOR======--

function Text:new(str, font)
    local p = private[self]
    
    TypeError:assert(is(str, "string"), str, type(str), "string")
    TypeError:assert(font == nil or is(font, Font), "font", type(font), Font)

    Drawable.new(self)

    p.sounds    = {}
    p.text      = str
    p.font      = font or Font:fromDefault(16)
    p.wrap      = math.huge
    p.state     = "running"
    p.shadow    = Color:fromRGB(0, 0, 0, 1)
    p.position  = Vector:fromValues(0, 0)
    p.alignment = Text.LEFT

    p.slog = slog.new(p.alignment.id, {
        default_strikethrough_position = 0, -- Adjust the position of the strikethough line.
        default_underline_position = 0,     -- Adjust the position of the underline line.
        adjust_line_height = 0,             -- Adjust the default line spacing.
        character_sound = false,            -- Use a voice when printing characters? True or false.
        default_warble = 0,                 -- How much to adjust the voice when printing each character. 
        shadow_color = p.shadow_color,      -- Default Drop Shadow Color.
        sound_number = 0,                   -- What voice to use when printing characters.
        print_speed = 0,                    -- How fast text prints.
        sound_every = 2,                    -- How many characters to wait before making another noise when printing text.
        autotags = "",                      -- This string is added at the start of every textbox, can include tags.
        color = p.drawable.color,           -- Default text color.
        font = p.font                       -- Default font for the textbox, love font object.
    })

    self:start()
end

    --======METHODS======--
   
function Text:update(dt)
    local p = private[self]

    if p.state == "paused" then return self end

    --If the text is empty, then we can early exit. We set the state to finished,
    --but don't trigger the "finished" event because it's misleading, and the
    --state means that when the text has been updated, the user can restart the
    --effect by triggering the 'play' method.
    if p.text == "" then
        p.state = "finished"

        return self
    end
    
    if p.slog.current_character == 0 and #p.slog.table_string > 0 then
        p.state = "starting"

        self:dispatch("text.start")
        self:dispatchSync("text.start")

        p.state = "running"
    end

    p.slog:update(dt)

    --If the state is "finished", then that means all text is displayed, but
    --you will still need to update it, in the case of animated text effects.
    --However, we don't want the "progress" event firing while the text is
    --animating, because it'll look like the text never finishes displaying,
    --which would be confusing.
    if p.state ~= "finished" then
        self:dispatch("text.progress")
        self:dispatchSync("text.progress")
    end

    if p.state ~= "waiting" and p.slog.waitforinput then
        p.state = "waiting"

        return self
    end

    if p.state == "waiting" then
        self:dispatch("text.waiting")
        self:dispatchSync("text.waiting")

        return self
    end

    if p.state ~= "finished" and p.slog.current_character == #p.slog.table_string then
        p.state = "finished"

        self:dispatch("text.end")
        self:dispatchSync("text.end")
    end
end

function Text:draw()
    local p = private[self]
    
    Drawable.apply(self)
    
    p.slog:draw(p.position:unpack())

    Drawable.remove(self)

    return self
end

--A "paused" state is different than a "waiting" or "finished" state,
--as a "paused" state will not only stop text from being displayed, but
--will also stop text from being animated.
function Text:pause()
    private[self].state = "paused"
    
    return self
end

--The 'resume' method will resume a "paused" or "waiting" state, but if
--the state is "finished", will have no effect. If you want the effect to
--continue playing from the beginning, then you need to use the 'start'
--method to restart the printing effect.
function Text:resume()
    local p = private[self]

    if p.state ~= "finished" then
        p.state = "running"
    end

    return self
end

--The 'start' method will always start the typing effect from the beginning.
--If the typing effect has been paused, or is waiting for input, and you
--simply want the effect to continue from where it currently is, then you
--want to use the 'resume' method. If you update the text with the text
--setter, then you will want to use the 'start'/'finish' method, otherwise
--the new text will not be displayed. The 'start' method will also set the
--state to "running", and so if you text is not visible when this method
--fires, you may miss the beginning of the text typing effect.
function Text:start()
    local p = private[self]

    p.state = "running"

    p.slog:send(p.text, p.wrap)

    return self
end

--The 'finish' method is much like the 'start' method, but it simply immediately
--draws all text, as though the text has already iterated through all characters.
--When the events fire, all three events ("start", "progress", "end") will fire
--sequentially. If you want the text to stop animating, then you want to use the
--'pause' method.
function Text:finish()
    local p = private[self]

    p.state = "running"
    
    p.slog:send(p.text, p.wrap, true)

    return self
end

function Text:fitWithin(rectangle)
    local p, positions, xwidest, ywidest, height
    
    p = private[self]
    
    TypeError:assert(is(rectangle, Rectangle), "rectangle", type(rectangle), Rectangle)

    self:finish()
    
    positions = p.slog
        :determinePos(
            p.position
                :subtract(p.drawable.origin, true)
                :unpack()
        )
    xwidest   = 0
    ywidest   = 0
    height    = p.font.height
    
    p.position:add(p.drawable.origin, true)

    for _, position in ipairs(positions) do
        xwidest = math.max(position[1], xwidest)
        ywidest = math.max(position[2] + height, ywidest)
    end
    
    p.font.size = math.round(p.font.size * (rectangle.size.x < rectangle.size.y and
        rectangle.size.x / xwidest or
        rectangle.size.y / ywidest
    ))
    
    self:start()
    
    return self
end

function Text:centerWithin(rectangle, direction)
    local p = private[self]
    
    TypeError:assert(is(rectangle, Rectangle), "rectangle", type(rectangle), Rectangle)
    TypeError:assert(is(direction, Symbol), "direction", type(direction), Symbol)
    InvalidError:assert(private[Text].centering[direction], direction, "direction", centering)

    p.position:setToVector(rectangle.position)
    
    if direction == VERTICAL or direction == BOTH then
        p.drawable.origin
            :setToValues(0, 0)
            :shiftByValues(0, p.font.ascent * 0.5)
            :shiftByValues(0, -rectangle.size.y * 0.5)
    end

    p.wrap = rectangle.size.x

    if direction == HORIZONTAL or direction == BOTH then
        p.alignment      = Text.CENTER
        p.slog.rendering = p.alignment.id
    end
    
    self:start()

    return self
end

    --======GETTERS======--

function Text.__get:shadow_color()
    return private[self].shadow_color
end

function Text.__get:position()
    return private[self].position
end

function Text.__get:font()
    return private[self].font
end

function Text.__get:wrap()
    return private[self].wrap
end

function Text.__get:text()
    return private[self].text
end

function Text.__get:alignment()
    return private[self].alignment
end

function Text.__get:bounds()
    local p, positions, tbl
    
    p         = private[self]
    positions = p.slog
        :determinePos(
            p.position
                :subtract(p.drawable.origin, true)
                :unpack()
        )
    height    = p.font.height
    tbl       = {
        p.position:clone(),
        Vector:fromValues(0, 0)
    }

    p.position:add(p.drawable.origin, true)

    for _, position in ipairs(positions) do
        tbl[2]:setToValues(
            math.max(tbl[2].x, position[1]),
            math.max(tbl[2].y + height, position[2])
        )
    end

    return tbl
end
    
    --======SETTERS======--

function Text.__set:color(value)
    local p = private[self]

    TypeError:assert(is(value, Color), "color", type(value), Color)

    p.drawable.color     = value
    p.slog.default_color = value
end

function Text.__set:wrap(value)
    TypeError:assert(is(value, "number"), "wrap", type(value), "number")
    RangeError:assert(value > 0, value, ">0", math.huge)

    private[self].wrap = value

    self:start()
end

function Text.__set:text(value)
    local p = private[self]
    
    TypeError:assert(is(value, "string"), "text", type(value), "string")

    p.text = value

    self:start()
end

function Text.__set:alignment(value)
    local p = private[self]

    TypeError:assert(is(value, Symbol), "alignment", type(value), Symbol)
    InvalidError:assert(private[Text].alignments[value], value, "alignment", alignments)

    p.alignment      = value
    p.slog.rendering = value.id

    self:start()
end

function Text.__set:position(value)
    TypeError:assert(is(value, Vector), "position", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].position = value
end

    --======METAMETHODS======--

function Text:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.text) end

    return self:tostringHelper("Class")
end

Text.__type = "text"

return Text