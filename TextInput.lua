---@type Object
local Object
local TextInput, Text, Font, Color, Rectangle, private
local Emitter
local TypeError
local is, utf8

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Text      = require("classes.Text")
Font      = require("classes.Font")
Color     = require("classes.Color")
Vector    = require("classes.Vector")
Rectangle = require("classes.Rectangle")

Emitter = require("classes.mixins.Emitter")

TypeError = require("classes.errors.TypeError")

is = require("lib.is")

utf8 = require("utf8")

TextInput = Object:extend()

TextInput:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

--Conversion notes:
-- * slog uses square brackets to define special display behaviour.
--   You must wrap an open square bracket to prevent this behaviour.
local function convtoslog(text)
    return text:gsub("%[", "%[%[%]")
end

local function getcursorpos(p)
    if p.cursor == p.text:len() then
        p.textbox.text = convtoslog(p.text) .. "[cursorsave]"
    elseif p.cursor == 0 then
        p.textbox.text = "[cursorsave]" .. convtoslog(p.text)
    else
        p.textbox.text = TL("%{convtoslog(p.text:sub(1, p.cursor))}[cursorsave]%{convtoslog(p.text:sub(p.cursor + 1))}", {
            convtoslog = convtoslog,
            p = p
        })
    end
end

--TODO: Fix this for utf8 chars.
local function addchar(p, text)
    if p.cursor == p.text:len() then
        p.text = p.text .. text
    elseif p.cursor == 0 then
        p.text = text .. p.text
    else
        p.text = p.text:sub(0, p.cursor) .. text .. p.text:sub(p.cursor + 1)
    end

    p.cursor = p.cursor + text:len()

    getcursorpos(p)
end

local function changecursorline(p, height, adjust, final)
    local count, closest, positions, new_cursor
        
    current    = utf8.len(p.text)
    count      = 0
    closest    = math.huge
    positions  = private[p.textbox].slog:determinePos(p.textbox.position:unpack())
    new_cursor = Vector:fromValues(
        private[p.textbox].slog.cursor_storage.x,
        private[p.textbox].slog.cursor_storage.y + height
    )    
    
    --Move the cursor to it's new graphical position, then iterate
    --through all potential positions, and find the one closest to
    --this one. The index becomes the new cursor position (plus
    --some offsetting)

    for i, pos in ipairs(positions) do
        if pos[2] == new_cursor.y then
            local dist = new_cursor:distance(Vector:fromTable(pos))
            if dist < closest then
                current = i - adjust
                closest = dist
            end
        end

        count = count + 1
    end

    p.cursor = closest == math.huge and (final or count) or current

    p.textbox:finish():pause()

    getcursorpos(p)
end

    --======CONSTRUCTOR======--

function TextInput:new(font)
    local p = private[self]

    TypeError:assert(is(font, Font), "font", type(font), Font)

    p.text        = ""
    p.cursor      = 0
    p.blink_rate  = 0.3
    p.blink_timer = 0
    p.keyrepeat   = true
    p.highlight   = false
    p.ctrlmode    = false
    p.textbox     = Text(p.text, font)

    p.highlight_start = 0
    p.highlight_end   = 0
end

    --======METHODS======--

function TextInput:update(dt)
    local p = private[self]

    p.textbox:update(dt)

    p.blink_timer = p.blink_timer + dt

    if p.blink_timer > p.blink_rate then
        p.blink_timer = 0
        
        p.cursor_visible = not p.cursor_visible

        self:dispatch("cursor_blink", p.cursor_visible)
        self:dispatchSync("cursor_blink", p.cursor_visible)
    end

    return self
end

function TextInput:draw()
    local p, cursor
    
    p = private[self]

    p.textbox:draw()
    
    cursor = private[p.textbox].slog.cursor_storage
    
    if p.cursor_active and p.cursor_visible then
        p.textbox.color:apply()

        love.graphics.translate(p.textbox.position:unpack())
        love.graphics.translate(p.textbox.origin:invert(true):unpack())
        love.graphics.translate(cursor.x + 2, cursor.y)

        love.graphics.line(0, 0, 0, p.textbox.font.baseline)

        love.graphics.translate(-(cursor.x + 2), -cursor.y)
        love.graphics.translate(p.textbox.origin:invert(true):unpack())
        love.graphics.translate(p.textbox.position:invert(true):unpack())

        p.textbox.position:invert(true)
        
        p.textbox.color:remove()
    end

    return self
end

function TextInput:textinput(text)
    local p = private[self]

    addchar(p, text)
    
    p.textbox:finish():pause()

    self:dispatch("text_changed", p.text)
    self:dispatchSync("text_changed", p.text)
    
    return self
end

function TextInput:keypressed(key)
    local p = private[self]
      
    p.prev_keyrepeat = love.keyboard.hasKeyRepeat()

    love.keyboard.setKeyRepeat(p.keyrepeat)

    if key == "lshift" or key == "rshift" and not p.highlight then
        p.highlight = true
        
        p.highlight_start = p.cursor
        p.highlight_end   = p.cursor
    end

    if key == "lctrl" or key == "rctrl" then
        p.ctrlmode = true
    end

    if key == "return" then
        addchar(p, "\n")
    end

    if key == "left" and p.cursor ~= 0 then
        if p.ctrlmode then
            local index = 0

            for i, char in p.text do
                if i == p.cursor then
                    break
                elseif char:match("[^%a]") ~= nil then
                    index = i
                end
            end

            p.cursor = index
        else
            p.cursor = math.max(p.cursor - 1, 0)
        end

        getcursorpos(p)
    end

    if key == "right" and p.cursor ~= utf8.len(p.text) then
        if p.ctrlmode then
            local index, passed

            index  = utf8.len(p.text) + 1
            passed = false

            for i, char in p.text do
                if i - 1 == p.cursor then
                    passed = true
                elseif passed and char:match("[^%a]") ~= nil then
                    index = i

                    break
                end
            end

            p.cursor = index - 1
        else
            p.cursor = math.min(p.cursor + 1, utf8.len(p.text))
        end

        getcursorpos(p)
    end

    if key == "up" then
        changecursorline(p, -p.textbox.font.height, 0, 0)
    end

    if key == "down" then
        changecursorline(p, p.textbox.font.height, 1)
    end
    
    --TODO: Fix this for utf8 chars
    if key == "backspace" then
        if p.text:len() == 0 then
            p.cursor = 1
        elseif p.cursor == p.text:len() then
            p.text = p.text:sub(1, -2)
        elseif p.cursor == 0 then
            p.cursor = p.cursor + 1
        else
            p.text = p.text:sub(0, p.cursor - 1) .. p.text:sub(p.cursor + 1)
        end

        p.cursor = p.cursor - 1

        getcursorpos(p)
    end

    p.textbox:finish():pause()

    if key == "return" or key == "backspace" then
        self:dispatch("text_changed", p.text)
        self:dispatchSync("text_changed", p.text)
    end

    return self
end

function TextInput:keyreleased(key)
    local p = private[self]
    
    --keyreleased can sometimes fire before keypressed if using Game events,
    --instead of pure LOVE events.
    if p.prev_keyrepeat then love.keyboard.setKeyRepeat(p.prev_keyrepeat) end

    p.prevkeyrepeat = nil

    if key == "lshift" or key == "rshift" then
        p.highlight = false
    end

    if key == "lctrl" or key == "rctrl" then
        p.ctrlmode = false
    end

    return self
end

function TextInput:fit(rectangle, padding)
    local p = private[self]

    TypeError:assert(is(rectangle, Rectangle), "rectangle", type(rectangle), Rectangle)

    rectangle = rectangle:clone()

    rectangle.size:shiftByValues(-padding * 2, -padding * 2)

    p.textbox
        :fitWithin(rectangle)
        :centerWithin(rectangle, Text.HORIZONTAL)

    p.textbox.alignment = Text.LEFT
    p.textbox.wrap      = p.textbox.wrap - padding * 2

    p.textbox.origin:shiftByValues(-padding, -padding)
    
    p.textbox:finish():pause()

    return self
end

    --======GETTERS======--

function TextInput.__get:textbox()
    return private[self].textbox
end

function TextInput.__get:text()
    return private[self].text
end

function TextInput.__get:font()
    return private[self].textbox.font
end

function TextInput.__get:color()
    return private[self].textbox.color
end

function TextInput.__get:position()
    return private[self].textbox.position
end

function TextInput.__get:origin()
    return private[self].textbox.origin
end

function TextInput.__get:cursor_visible()
    return private[self].cursor_active
end
    
    --======SETTERS======--
    
function TextInput.__set:text(value)
    local p = private[self]

    TypeError:assert(is(value, "string"), "text", type(value), "string")
    
    p.text   = ""
    p.cursor = 0
    
    for _, char in value do addchar(p, char) end
    
    getcursorpos(p)

    p.textbox:finish():pause()
end

function TextInput.__set:color(value)
    TypeError:assert(is(value, Color), "color", type(value), Color)

    private[self].textbox.color = value
end

function TextInput.__set:position(value)
    TypeError:assert(is(value, Vector), "position", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].textbox.position = value
end

function TextInput.__set:origin(value)
    TypeError:assert(is(value, Vector), "origin", type(value), Vector)
    VectorSizeError:assert(value.size == 2, value.size, 2)

    private[self].textbox.origin = value
end

function TextInput.__set:cursor_visible(value)
    private[self].cursor_active = not not value
end

    --======METAMETHODS======--

function TextInput:__tostring()
    if self.is_instance then return self:tostringHelper(private[self].text) end

    return self:tostringHelper("Class")
end

TextInput.__type = "text_input"

return TextInput