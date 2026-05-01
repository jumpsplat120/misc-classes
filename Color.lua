--TODO: Fix all of this to match style of other classes

---@type Object
local Object
local Color, Symbol
local private, is, tobase, TL
local Unpack, Ipairs, AsTable
local TypeError, ConstructorError, RangeError, UnsetError
local LengthError, PatternError, InvalidError

Object  = require("lib.Classy")
Symbol  = require("lib.Classy.Symbol")
private = require("lib.Classy.instances")

TL     = require("lib.string_template")
is     = require("lib.is")
tobase = require("lib.tobase")

Unpack  = require("classes.mixins.Unpack")
Ipairs  = require("classes.mixins.Ipairs")
AsTable = require("classes.mixins.AsTable")

ConstructorError = require("classes.errors.ConstructorError")
InvalidError     = require("classes.errors.InvalidError")
PatternError     = require("classes.errors.PatternError")
LengthError      = require("classes.errors.LengthError")
RangeError       = require("classes.errors.RangeError")
UnsetError       = require("classes.errors.UnsetError")
TypeError        = require("classes.errors.TypeError")

Color = Object:init()

    --======PRIVATE FUNCTIONS======--

local MULTIPLY, SCREEN, OVERLAY, HARD_LIGHT
local SOFT_LIGHT, DIVIDE, ADDITIVE, SUBTRACTIVE
local DIFFERENCE, DARKEN, LIGHTEN, EXCLUSION
local internal, blend_modes, blend

private[Color] = {
    subtractive = true,
    difference  = true,
    hard_light  = true,
    soft_light  = true,
    exclusion   = true,
    multiply    = true,
    additive    = true,
    overlay     = true,
    lighten     = true,
    screen      = true,
    darken      = true,
    divide      = true
}

blend_modes = table.join(table.keys(private[Color]), ", ", " and ")

blend = {
    setup = function(a, b, t)
        local p1, p2, inv

        p1    = private[a].values
        p2    = private[b].values
        a     = {}
        b     = {}
        inv   = 1 - t

        for i, v in ipairs(p1) do
            a[i] = v * inv
        end

        for i, v in ipairs(p2) do
            b[i] = v * t
        end

        return a, b
    end,
    calculate = function(mode, a, b, t)
        local color = {}

        a, b = blend.setup(a, b, t)

        for i, v in ipairs(a) do
            color[i] = math.clamp(blend[mode](v, b[i]), 0, 1)
        end

        return color
    end,
    subtractive = function(a, b)
        return a - b
    end,
    difference = function(a, b)
        return math.abs(b - a)
    end,
    hard_light = function(a, b)
        if a < 0.5 then
            return blend[MULTIPLY](2 * a, b)
        end

        return blend[SCREEN](2 * a - 1, b)
    end,
    --There are many different versions of soft light;
    --this version is pulled from https://codepen.io/Praseetha-KR/pen/grrWba?editors=1010
    soft_light = function(a, b)
        if a <= 0.5 then
            return b - (1 - 2 * a) * b * (1 - b)
        end

        local d = b <= 0.5 and ((16 * b - 12) * b + 4) * b or b:sqrt()

        return b + (2 * a - 1) * (d - b)
    end,
    exclusion = function(a, b)
        return a + b - 2 * a * b
    end,
    multiply = function(a, b)
        return a * b
    end,
    additive = function(a, b)
        return a + b
    end,
    overlay = function(a, b)
        if b < 0.5 then
            return blend.multiply(2 * a, b)
        end

        return blend.screen(2 * a - 1, b)
    end,
    lighten = function(a, b)
        return math.max(a, b)
    end,
    screen = function(a, b)
        return 1 - (1 - a) * (1 - b)
    end,
    darken = function(a, b)
        return math.min(a, b)
    end,
    divide = function(a, b)
        if a == 0 then return 0 end
        if b == 0 then return 1 end

        return a / b
    end
}

local function fromHSV(h, s, v, a)
    local hsec, hsecoff, p, q, t

    if s == 0 then return v, v, v, a end
	
	hsec = math.floor(h / 60)
	hsecoff = (h / 60) - hsec

	p = v * (1 - s)
	q = v * (1 - s * hsecoff)
	t = v * (1 - s * (1 - hsecoff))

	if hsec == 0 then return v, t, p, a end
	if hsec == 1 then return q, v, p, a end
	if hsec == 2 then return p, v, t, a end
	if hsec == 3 then return p, q, v, a end
	if hsec == 4 then return t, p, v, a end
	if hsec == 5 then return v, p, q, a end
end

local function fromHSL(h, s, l, a)
    local c, x, m

    c = (1 - math.abs(2 * l - 1)) * s
    x = c * (1 - math.abs((h / 60) % 2 - 1))
    m = l - c / 2

    if 0   <= h and h < 60  then return c + m, x + m,     m, a end
    if 60  <= h and h < 120 then return x + m, c + m,     m, a end
    if 120 <= h and h < 180 then return     m, c + m, x + m, a end
    if 180 <= h and h < 240 then return     m, x + m, c + m, a end
    if 240 <= h and h < 300 then return x + m,     m, c + m, a end
    if 300 <= h and h < 360 then return c + m,     m, x + m, a end
end

local function fromHex(hex)
    local len, r, g, b, a
    
    TypeError:assert(is(hex, "string"), "hex", type(hex), "string")

    len = #hex

    LengthError:assert(3 <= len and len <= 9, len, hex, 3, 9)
    
    if hex:startswith("#") then hex = hex:sub(2) end
    
    len = #hex
    
    if len == 3 then
        r, g, b = hex:match("(%x)(%x)(%x)")
        
        PatternError:assert(r, hex, "(%x)(%x)(%x)")

        r = r:rep(2)
        g = g:rep(2)
        b = b:rep(2)
    end
    
    if len == 4 then
        r, g, b, a = hex:match("(%x)(%x)(%x)(%x)")

        PatternError:assert(r, hex, "(%x)(%x)(%x)(%x)")

        r = r:rep(2)
        g = g:rep(2)
        b = b:rep(2)
        a = a:rep(2)
    end
    
    if len == 6 then
        r, g, b = hex:match("(%x%x)(%x%x)(%x%x)")
        
        PatternError:assert(r, hex, "(%x%x)(%x%x)(%x%x)")
    end

    if len == 8 then
        r, g, b, a = hex:match("(%x%x)(%x%x)(%x%x)(%x%x)")
        
        PatternError:assert(r, hex, "(%x%x)(%x%x)(%x%x)(%x%x)")
    end

    a = a or "FF"

    return tonumber(r, 16) / 255,
           tonumber(g, 16) / 255,
           tonumber(b, 16) / 255,
           tonumber(a, 16) / 255
end

local function toHSV(r, g, b, a)
    local s, v, diff, rr, gg, bb

    v    =     math.max(r, g, b)
    diff = v - math.min(r, g, b)
    
    if diff == 0 then return 0, 0, v, a end

    s  = diff / v
    rr = (v - r) / 6 / diff + 1 / 2
    gg = (v - g) / 6 / diff + 1 / 2
    bb = (v - b) / 6 / diff + 1 / 2
    
    if r == v then return ((bb - gg):clamp(0, 1) * 360):round(),           s, v, a end
    if g == v then return (((1 / 3) + rr - bb):clamp(0, 1) * 360):round(), s, v, a end
    if b == v then return (((2 / 3) + gg - rr):clamp(0, 1) * 360):round(), s, v, a end
end

local function toHSL(r, g, b, a)
    local min, max, diff, s, l

    min  = math.min(r, g, b)
    max  = math.max(r, g, b)
    diff = max - min

    l = (max + min) * 0.5
    s = diff / (1 - math.abs(2 * l - 1))

    if diff == 0 then return 0, l, s, a end
    if max == r  then return ((((g - b) / diff) % 6) * 60):round():cycle(0, 360), l, s, a end
    if max == g  then return (((b - r) / diff + 2)   * 60):round():cycle(0, 360), l, s, a end
    if max == b  then return (((r - g) / diff + 4)   * 60):round():cycle(0, 360), l, s, a end
end

local function toHex(r, g, b, a)
    return TL(
        "%{tobase(r * 255, 16):padleft(2, '0')}" ..
        "%{tobase(g * 255, 16):padleft(2, '0')}" ..
        "%{tobase(b * 255, 16):padleft(2, '0')}" ..
        "%{tobase(a * 255, 16):padleft(2, '0')}", {
        tobase = tobase,
        r = r,
        g = g,
        b = b,
        a = a
    })
end

      --======CONSTRUCTOR======--

--Create a `color` from `hue`, `saturation`, `value`, and `alpha` values.
function Color:fromHSV(hue, saturation, value, alpha)
    local red, green, blue

    alpha = alpha or 1

    TypeError:assert(type(hue) == "number", "hue", type(hue), "number")
    TypeError:assert(type(value) == "number", "value", type(value), "number")
    TypeError:assert(type(alpha) == "number", "alpha", type(alpha), "number")
    TypeError:assert(type(saturation) == "number", "saturation", type(saturation), "number")

    RangeError:assert(0 <= hue and hue <= 360, hue, "hue", 0, 360)
    RangeError:assert(0 <= value and value <= 1, value, "value", 0, 1)
    RangeError:assert(0 <= alpha and alpha <= 1, alpha, "alpha", 0, 1)
    RangeError:assert(0 <= saturation and saturation <= 1, saturation, "saturation", 0, 1)

    --A hue of 360 *is* a hue of zero. Technically it goes from 0 to 359.9999999.
    hue = hue == 360 and 0 or hue

    red, green, blue, alpha = fromHSV(hue, saturation, value, alpha)

    internal = math.uuid()

    return self {
        red      = red,
        blue     = blue,
        green    = green,
        alpha    = alpha,
        internal = internal
    }
end

function Color:fromHSB(h, s, b, a)
    a = a or 1

    TypeError:assert(is(h, "number"), "hue",        type(h), "number")
    TypeError:assert(is(s, "number"), "saturation", type(s), "number")
    TypeError:assert(is(b, "number"), "brightness", type(b), "number")
    TypeError:assert(is(a, "number"), "alpha",      type(a), "number")

    RangeError:assert(0 <= h and h <= 360, h, "hue",        0, 360)
    RangeError:assert(0 <= s and s <= 1,   s, "saturation", 0, 1)
    RangeError:assert(0 <= b and b <= 1,   b, "brightness", 0, 1)
    RangeError:assert(0 <= a and a <= 1,   a, "alpha",      0, 1)

    if h == 360 then h = 0 end

    internal = math.uuid()

    return Color(internal, fromHSV(h, s, b, a))
end

function Color:fromHSL(h, s, l, a)
    a = a or 1

    TypeError:assert(is(h, "number"), "hue",        type(h), "number")
    TypeError:assert(is(s, "number"), "saturation", type(s), "number")
    TypeError:assert(is(l, "number"), "lightness",  type(l), "number")
    TypeError:assert(is(a, "number"), "alpha",      type(a), "number")

    RangeError:assert(0 <= h and h <= 360, h, "hue",        0, 360)
    RangeError:assert(0 <= s and s <= 1,   s, "saturation", 0, 1)
    RangeError:assert(0 <= l and l <= 1,   l, "lightness",  0, 1)
    RangeError:assert(0 <= a and a <= 1,   a, "alpha",      0, 1)

    if h == 360 then h = 0 end

    internal = math.uuid()

    return Color(internal, fromHSL(h, s, l, a))
end

--Create a `color` from `red`, `green`, `blue`, and `alpha` values.
function Color:fromRGB(red, green, blue, alpha)
    alpha = alpha or 1

    TypeError:assert(type(red) == "number", "red", type(red), "number")
    TypeError:assert(type(blue) == "number", "blue", type(blue), "number")
    TypeError:assert(type(green) == "number", "green", type(green), "number")
    TypeError:assert(type(alpha) == "number", "alpha", type(alpha), "number")

    RangeError:assert(0 <= red and red <= 1, red, "red", 0, 1)
    RangeError:assert(0 <= blue and blue <= 1, blue, "blue", 0, 1)
    RangeError:assert(0 <= green and green <= 1, green, "green", 0, 1)
    RangeError:assert(0 <= alpha and alpha <= 1, alpha, "alpha", 0, 1)

    internal = math.uuid()

    return self {
        red      = red,
        blue     = blue,
        green    = green,
        alpha    = alpha,
        internal = internal
    }
end

function Color:fromRGB255(r, g, b, a)
    a = a or 1

    TypeError:assert(is(r, "number"), "red",   type(r), "number")
    TypeError:assert(is(g, "number"), "green", type(g), "number")
    TypeError:assert(is(b, "number"), "blue",  type(b), "number")
    TypeError:assert(is(a, "number"), "alpha", type(a), "number")

    RangeError:assert(0 <= r and r <= 255, r, "red",   0, 1)
    RangeError:assert(0 <= g and g <= 255, g, "green", 0, 1)
    RangeError:assert(0 <= b and b <= 255, b, "blue",  0, 1)
    RangeError:assert(0 <= a and a <= 1, a, "alpha", 0, 1)

    internal = math.uuid()

    return Color(internal, r / 255, g / 255, b / 255, a)
end

function Color:fromHex(hex)
    internal = math.uuid()

    return Color(internal, fromHex(hex))
end

--Contstructor.
function Color:new(opts)
    local p = private[self]
    
    ConstructorError:assert(opts.internal == internal, "Color")
    
    p.values = { opts.red, opts.green, opts.blue, opts.alpha }

    p.previous = {
        foreground = {},
        background = {}
    }

    p.active = {
        foreground = false,
        background = false
    }
end

    --======METHODS======--

function Color:apply()
    love.graphics.setColor(private[self].values)
    
    return self
end

function Color:applyBackground()
    love.graphics.setBackgroundColor(private[self].values)
    
    return self
end

function Color:setRGB(r, g, b, a)
    local v = private[self].values

    if r then
        TypeError:assert(is(r, "number"), "red", type(r), "number")
        RangeError:assert(0 <= r and r <= 1, r, "red", 0, 1)

        v[1] = r
    end

    if g then
        TypeError:assert(is(g, "number"), "green", type(g), "number")
        RangeError:assert(0 <= g and g <= 1, g, "green", 0, 1)

        v[2] = g
    end
    
    if b then
        TypeError:assert(is(b, "number"), "blue", type(b), "number")
        RangeError:assert(0 <= b and b <= 1, b, "blue", 0, 1)

        v[3] = b
    end

    if a then
        TypeError:assert(is(a, "number"), "alpha", type(a), "number")
        RangeError:assert(0 <= a and a <= 1, a, "alpha", 0, 1)

        v[4] = a
    end

    return self
end

function Color:setRGB255(r, g, b, a)
    local v = private[self].values

    if r then
        TypeError:assert(is(r, "number"), "red", type(r), "number")
        RangeError:assert(0 <= r and r <= 1, r, "red", 0, 1)

        v[1] = r / 255
    end

    if g then
        TypeError:assert(is(g, "number"), "green", type(g), "number")
        RangeError:assert(0 <= g and g <= 1, g, "green", 0, 1)

        v[2] = g / 255
    end
    
    if b then
        TypeError:assert(is(b, "number"), "blue", type(b), "number")
        RangeError:assert(0 <= b and b <= 1, b, "blue", 0, 1)

        v[3] = b / 255
    end

    if a then
        TypeError:assert(is(a, "number"), "alpha", type(a), "number")
        RangeError:assert(0 <= a and a <= 1, a, "alpha", 0, 1)

        v[4] = a
    end

    return self
end

function Color:setHSL(h, s, l, a)
    local hh, ss, ll, aa, v

    v = private[self].values

    hh, ss, ll, aa = toHSL(v[1], v[2], v[3], v[4])

    if h then
        TypeError:assert(is(h, "number"), "hue", type(h), "number")
        RangeError:assert(0 <= h and h <= 360, h, "hue", 0, 360)
    end

    if s then
        TypeError:assert(is(s, "number"), "saturation", type(s), "number")
        RangeError:assert(0 <= s and s <= 1, s, "saturation", 0, 1)
    end
    
    if l then
        TypeError:assert(is(l, "number"), "lightness", type(l), "number")
        RangeError:assert(0 <= l and l <= 1, l, "lightness", 0, 1)
    end

    if a then
        TypeError:assert(is(a, "number"), "alpha", type(a), "number")
        RangeError:assert(0 <= a and a <= 1, a, "alpha", 0, 1)
    end

    v[1], v[2], v[3], v[4] = fromHSL(h or hh, s or ss, l or ll, a or aa)

    return self
end

function Color:setHSB(h, s, b, a)
    local hh, ss, bb, aa, v

    v = private[self].values

    hh, ss, bb, aa = toHSV(v[1], v[2], v[3], v[4])

    if h then
        TypeError:assert(is(h, "number"), "hue", type(h), "number")
        RangeError:assert(0 <= h and h <= 360, h, "hue", 0, 360)
    end

    if s then
        TypeError:assert(is(s, "number"), "saturation", type(s), "number")
        RangeError:assert(0 <= s and s <= 1, s, "saturation", 0, 1)
    end
    
    if b then
        TypeError:assert(is(b, "number"), "brightness", type(b), "number")
        RangeError:assert(0 <= b and b <= 1, b, "brightness", 0, 1)
    end

    if a then
        TypeError:assert(is(a, "number"), "alpha", type(a), "number")
        RangeError:assert(0 <= a and a <= 1, a, "alpha", 0, 1)
    end

    v[1], v[2], v[3], v[4] = fromHSV(h or hh, s or ss, b or bb, a or aa)

    return self
end

function Color:setHSV(h, s, v, a)
    local hh, ss, vv, aa, val

    val = private[self].values

    hh, ss, bb, aa = toHSV(val[1], val[2], val[3], val[4])

    if h then
        TypeError:assert(is(h, "number"), "hue", type(h), "number")
        RangeError:assert(0 <= h and h <= 360, h, "hue", 0, 360)
    end

    if s then
        TypeError:assert(is(s, "number"), "saturation", type(s), "number")
        RangeError:assert(0 <= s and s <= 1, s, "saturation", 0, 1)
    end
    
    if v then
        TypeError:assert(is(v, "number"), "value", type(v), "number")
        RangeError:assert(0 <= v and v <= 1, v, "brightness", 0, 1)
    end

    if a then
        TypeError:assert(is(a, "number"), "alpha", type(a), "number")
        RangeError:assert(0 <= a and a <= 1, a, "alpha", 0, 1)
    end

    val[1], val[2], val[3], val[4] = fromHSV(h or hh, s or ss, v or vv, a or aa)

    return self
end

function Color:matches(color)
    local a, b
    
    TypeError:assert(is(color, Color), "color", type(color), Color)

    a = private[self].values
    b = private[color].values

    for i, v in ipairs(a) do
        if b[i] ~= v then return false end
    end

    return true
end

function Color:blend(color, mode, percentage, modify)
    local p, mod
    
    p = private[self]

    TypeError:assert(is(color, Color), "color", type(color), Color)
    TypeError:assert(is(percentage, "number"), "percentage", type(percentage), "number")
    TypeError:assert(is(mode, Symbol), "mode", type(mode), Symbol)
    InvalidError:assert(private[Color][mode], mode, "mode", blend_modes)
    RangeError:assert(0 <= percentage and percentage <= 1, percentage, "percentage", 0, 1)

    mod = blend.calculate(mode, self, color, percentage)

    if not modify then
        return Color:fromRGB(mod[1], mod[2], mod[3], mod[4])
    end

    for i, v in ipairs(mod) do
        p.values[i] = v
    end

    return self
end

function Color:clone()
    internal = math.uuid()

    return Color(internal, table.unpack(private[self].values))
end

    --======GETTERS======--

function Color.__get:hex()
    local v = private[self].values

    return toHex(v[1], v[2], v[3], v[4])
end

function Color.__get:hsv_hue()
    local v = private[self].values
    
    return select(1, toHSV(v[1], v[2], v[3], v[4]))
end

function Color.__get:hsv_saturation()
    local v = private[self].values

    return select(2, toHSV(v[1], v[2], v[3], v[4]))
end

function Color.__get:hsl_hue()
    local v = private[self].values

    return select(1, toHSL(v[1], v[2], v[3], v[4]))
end

function Color.__get:hsl_saturation()
    local v = private[self].values

    return select(2, toHSL(v[1], v[2], v[3], v[4]))
end

function Color.__get:hsv_value()
    local v = private[self].values

    return select(3, toHSV(v[1], v[2], v[3], v[4]))
end

function Color.__get:brightness()
    return self.__get.hsv_value(self)
end

function Color.__get:lightness()
    local v = private[self].values

    return select(3, toHSL(v[1], v[2], v[3], v[4]))
end

function Color.__get:red()
    return private[self].values[1]
end

function Color.__get:green()
    return private[self].values[2]
end

function Color.__get:blue()
    return private[self].values[3]
end

function Color.__get:red255()
    return (private[self].values[1] * 255):round()
end

function Color.__get:green255()
    return (private[self].values[2] * 255):round()
end

function Color.__get:blue255()
    return (private[self].values[3] * 255):round()
end

function Color.__get:alpha()
    return private[self].values[4]
end

function Color.__get:rgb()
    local v = private[self].values

    return {
        red   = v[1],
        blue  = v[2],
        green = v[3],
        alpha = v[4]
    }
end

function Color.__get:love_rgb()
    local v = private[self].values
    
    return {
        v[1], v[2], v[3], v[4]
    }
end

function Color.__get:rgb255()
    local v = private[self].values

    return {
        red   = (v[1] * 255):round(),
        blue  = (v[2] * 255):round(),
        green = (v[3] * 255):round(),
        alpha = v[4]
    }
end

function Color.__get:hsl()
    local tbl, v

    v   = private[self].values
    tbl = { toHSL(v[1], v[2], v[3], v[4]) }

    return {
        hue        = tbl[1],
        saturation = tbl[2],
        lightness  = tbl[3],
        alpha      = tbl[4]
    }
end

function Color.__get:hsb()
    local tbl, v

    v   = private[self].values
    tbl = { toHSV(v[1], v[2], v[3], v[4]) }

    return {
        hue        = tbl[1],
        saturation = tbl[2],
        brightness = tbl[3],
        alpha      = tbl[4]
    }
end

function Color.__get:hsv()
    local tbl, v

    v   = private[self].values
    tbl = { toHSV(v[1], v[2], v[3], v[4]) }

    return {
        hue        = tbl[1],
        saturation = tbl[2],
        value      = tbl[3],
        alpha      = tbl[4]
    }
end

    --======SETTERS======--

function Color.__set:hex(value)
    local v = private[self].values

    v[1], v[2], v[3], v[4] = fromHex(value)
end

function Color.__set:hsv_hue(value)
    local _, s, v, a, val
    
    val = private[self].values

    TypeError:assert(is(value, "number"), "hsv_hue", type(value), "number")
    RangeError:assert(0 <= value and value <= 360, value, "hsv_hue", 0, 360)

    if value == 360 then value = 0 end

    _, s, v, a = toHSV(val[1], val[2], val[3], val[4])

    val[1], val[2], val[3], val[4] = fromHSV(value, s, v, a)
end

function Color.__set:hsv_saturation(value)
    local h, _, v, a, val
    
    val = private[self].values

    TypeError:assert(is(value, "number"), "hsv_saturation", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "hsv_saturation", 0, 1)

    h, _, v, a = toHSV(val[1], val[2], val[3], val[4])

    val[1], val[2], val[3], val[4] = fromHSV(h, value, v, a)
end

function Color.__set:hsl_hue(value)
    local _, s, l, a, val
    
    val = private[self].values

    TypeError:assert(is(value, "number"), "hsl_hue", type(value), "number")
    RangeError:assert(0 <= value and value <= 360, value, "hsl_hue", 0, 360)

    if value == 360 then value = 0 end

    _, s, l, a = toHSL(val[1], val[2], val[3], val[4])

    val[1], val[2], val[3], val[4] = fromHSL(value, s, l, a)
end

function Color.__set:hsl_saturation(value)
    local h, _, l, a, val
    
    val = private[self].values

    TypeError:assert(is(value, "number"), "hsl_saturation", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "hsl_saturation", 0, 1)

    h, _, l, a = toHSL(val[1], val[2], val[3], val[4])
    
    val[1], val[2], val[3], val[4] = fromHSL(h, value, l, a)
end

function Color.__set:hsv_value(value)
    local h, s, _, a, val
    
    val = private[self].values

    TypeError:assert(is(value, "number"), "value", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "value", 0, 1)

    h, s, _, a = toHSV(val[1], val[2], val[3], val[4])

    val[1], val[2], val[3], val[4] = fromHSV(h, s, value, a)
end

function Color.__set:brightness(value)
    local h, s, _, a, val
    
    val = private[self].values

    TypeError:assert(is(value, "number"), "brightness", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "brightness", 0, 1)

    h, s, _, a = toHSV(val[1], val[2], val[3], val[4])
    
    val[1], val[2], val[3], val[4] = fromHSV(h, s, value, a)
end

function Color.__set:lightness(value)
    local h, s, _, a, val
    
    val = private[self].values

    TypeError:assert(is(value, "number"), "lightness", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "lightness", 0, 1)

    h, s, _, a = toHSL(val[1], val[2], val[3], val[4])
    
    val[1], val[2], val[3], val[4] = fromHSL(h, s, value, a)
end

function Color.__set:red(value)
    TypeError:assert(is(value, "number"), "red", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "red", 0, 1)

    private[self].values[1] = value
end

function Color.__set:green(value)
    TypeError:assert(is(value, "number"), "green", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "green", 0, 1)

    private[self].values[2] = value
end

function Color.__set:blue(value)
    TypeError:assert(is(value, "number"), "blue", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "blue", 0, 1)

    private[self].values[3] = value
end

function Color.__set:red255(value)
    TypeError:assert(is(value, "number"), "red", type(value), "number")
    RangeError:assert(0 <= value and value <= 255, value, "red", 0, 255)

    private[self].values[1] = value == 0 and 0 or value / 255
end

function Color.__set:green255(value)
    TypeError:assert(is(value, "number"), "green", type(value), "number")
    RangeError:assert(0 <= value and value <= 255, value, "green", 0, 255)

    private[self].values[2] = value == 0 and 0 or value / 255
end

function Color.__set:blue255(value)
    TypeError:assert(is(value, "number"), "blue", type(value), "number")
    RangeError:assert(0 <= value and value <= 255, value, "blue", 0, 255)

    private[self].values[3] = value == 0 and 0 or value / 255
end

function Color.__set:alpha(value)
    TypeError:assert(is(value, "number"), "alpha", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "alpha", 0, 1)

    private[self].values[4] = value
end

function Color.__set:rgb(value)
    local r, g, b, a, rr, gg, bb, aa, v
    
    TypeError:assert(is(value, "table"), "rgb", type(value), "table")

    if value.red then
        r  = value.red
        rr = ".red"
    elseif value.r then
        r  = value.r
        rr = ".r"
    elseif value[1] then
        r  = value[1]
        rr = "[1]"
    else
        UnsetError:throw("red/r/[1]", "rgb")
    end

    if value.green then
        g  = value.green
        gg = ".green"
    elseif value.g then
        g  = value.g
        gg = ".g"
    elseif value[2] then
        g  = value[2]
        gg = "[2]"
    else
        UnsetError:throw("green/g/[2]", "rgb")
    end

    if value.blue then
        b  = value.blue
        bb = ".blue"
    elseif value.b then
        b  = value.b
        bb = ".b"
    elseif value[3] then
        b  = value[3]
        bb = "[3]"
    else
        UnsetError:throw("blue/b/[3]", "rgb")
    end

    if value.alpha then
        a  = value.alpha
        aa = ".alpha"
    elseif value.a then
        a  = value.a
        aa = ".a"
    elseif value[4] then
        a  = value[4]
        aa = "[4]"
    else
        a = 1
    end

    TypeError:assert(is(r, "number"), "rgb" .. rr, type(r), "number")
    TypeError:assert(is(g, "number"), "rgb" .. gg, type(g), "number")
    TypeError:assert(is(b, "number"), "rgb" .. bb, type(b), "number")
    TypeError:assert(is(a, "number"), "rgb" .. aa, type(a), "number")

    RangeError:assert(0 <= r and r <= 1, r, "rgb" .. rr, 0, 1)
    RangeError:assert(0 <= g and g <= 1, g, "rgb" .. gg, 0, 1)
    RangeError:assert(0 <= b and b <= 1, b, "rgb" .. bb, 0, 1)
    RangeError:assert(0 <= a and a <= 1, a, "rgb" .. aa, 0, 1)

    v = private[self].values

    v[1] = r
    v[2] = g
    v[3] = b
    v[4] = a
end

function Color.__set:rgb255(value)
    local r, g, b, a, rr, gg, bb, aa, v
    
    TypeError:assert(is(value, "table"), "rgb255", type(value), "table")

    if value.red then
        r  = value.red
        rr = ".red"
    elseif value.r then
        r  = value.r
        rr = ".r"
    elseif value[1] then
        r  = value[1]
        rr = "[1]"
    else
        UnsetError:throw("red/r/[1]", "rgb255")
    end

    if value.green then
        g  = value.green
        gg = ".green"
    elseif value.g then
        g  = value.g
        gg = ".g"
    elseif value[2] then
        g  = value[2]
        gg = "[2]"
    else
        UnsetError:throw("green/g/[2]", "rgb255")
    end

    if value.blue then
        b  = value.blue
        bb = ".blue"
    elseif value.b then
        b  = value.b
        bb = ".b"
    elseif value[3] then
        b  = value[3]
        bb = "[3]"
    else
        UnsetError:throw("blue/b/[3]", "rgb255")
    end

    if value.alpha then
        a  = value.alpha
        aa = ".alpha"
    elseif value.a then
        a  = value.a
        aa = ".a"
    elseif value[4] then
        a  = value[4]
        aa = "[4]"
    else
        a = 1
    end

    TypeError:assert(is(r, "number"), "rgb255" .. rr, type(r), "number")
    TypeError:assert(is(g, "number"), "rgb255" .. gg, type(g), "number")
    TypeError:assert(is(b, "number"), "rgb255" .. bb, type(b), "number")
    TypeError:assert(is(a, "number"), "rgb255" .. aa, type(a), "number")

    RangeError:assert(0 <= r and r <= 255, r, "rgb255" .. rr, 0, 255)
    RangeError:assert(0 <= g and g <= 255, g, "rgb255" .. gg, 0, 255)
    RangeError:assert(0 <= b and b <= 255, b, "rgb255" .. bb, 0, 255)
    RangeError:assert(0 <= a and a <= 1, a, "rgb255" .. aa, 0, 1)

    v = private[self].values

    v[1] = r / 255
    v[2] = g / 255
    v[3] = b / 255
    v[4] = a
end

function Color.__set:hsl(value)
    local h, s, l, a, hh, ss, ll, aa, v
    
    TypeError:assert(is(value, "table"), "hsl", type(value), "table")

    if value.hue then
        h  = value.hue
        hh = ".hue"
    elseif value.h then
        h  = value.h
        hh = ".h"
    elseif value[1] then
        h  = value[1]
        hh = "[1]"
    else
        UnsetError:throw("hue/h/[1]", "hsl")
    end

    if value.saturation then
        s  = value.saturation
        ss = ".saturation"
    elseif value.s then
        s  = value.s
        ss = ".s"
    elseif value[2] then
        s  = value[2]
        ss = "[2]"
    else
        UnsetError:throw("saturation/s/[2]", "hsl")
    end

    if value.lightness then
        l  = value.lightness
        ll = ".lightness"
    elseif value.l then
        l  = value.l
        ll = ".l"
    elseif value[3] then
        l  = value[3]
        ll = "[3]"
    else
        UnsetError:throw("lightness/l/[3]", "hsl")
    end

    if value.alpha then
        a  = value.alpha
        aa = ".alpha"
    elseif value.a then
        a  = value.a
        aa = ".a"
    elseif value[4] then
        a  = value[4]
        aa = "[4]"
    else
        a = 1
    end

    TypeError:assert(is(h, "number"), "hsl" .. hh, type(h), "number")
    TypeError:assert(is(s, "number"), "hsl" .. ss, type(s), "number")
    TypeError:assert(is(l, "number"), "hsl" .. ll, type(l), "number")
    TypeError:assert(is(a, "number"), "hsl" .. aa, type(a), "number")

    RangeError:assert(0 <= h and h <= 360, h, "hsl" .. hh, 0, 360)
    RangeError:assert(0 <= s and s <= 1, s, "hsl" .. ss, 0, 1)
    RangeError:assert(0 <= l and l <= 1, l, "hsl" .. ll, 0, 1)
    RangeError:assert(0 <= a and a <= 1, a, "hsl" .. aa, 0, 1)

    v = private[self].values

    v[1], v[2], v[3], v[4] = fromHSL(h, s, l, a)
end

function Color.__set:hsb(value)
    local h, s, b, a, hh, ss, bb, aa, v
    
    TypeError:assert(is(value, "table"), "hsb", type(value), "table")

    if value.hue then
        h  = value.hue
        hh = ".hue"
    elseif value.h then
        h  = value.h
        hh = ".h"
    elseif value[1] then
        h  = value[1]
        hh = "[1]"
    else
        UnsetError:throw("hue/h/[1]", "hsb")
    end

    if value.saturation then
        s  = value.saturation
        ss = ".saturation"
    elseif value.s then
        s  = value.s
        ss = ".s"
    elseif value[2] then
        s  = value[2]
        ss = "[2]"
    else
        UnsetError:throw("saturation/s/[2]", "hsb")
    end

    if value.brightness then
        b  = value.brightness
        bb = ".brightness"
    elseif value.b then
        b  = value.b
        bb = ".b"
    elseif value[3] then
        b  = value[3]
        bb = "[3]"
    else
        UnsetError:throw("brightness/b/[3]", "hsb")
    end

    if value.alpha then
        a  = value.alpha
        aa = ".alpha"
    elseif value.a then
        a  = value.a
        aa = ".a"
    elseif value[4] then
        a  = value[4]
        aa = "[4]"
    else
        a = 1
    end

    TypeError:assert(is(h, "number"), "hsb" .. hh, type(h), "number")
    TypeError:assert(is(s, "number"), "hsb" .. ss, type(s), "number")
    TypeError:assert(is(b, "number"), "hsb" .. bb, type(b), "number")
    TypeError:assert(is(a, "number"), "hsb" .. aa, type(a), "number")

    RangeError:assert(0 <= h and h <= 360, h, "hsb" .. hh, 0, 360)
    RangeError:assert(0 <= s and s <= 1, s, "hsb" .. ss, 0, 1)
    RangeError:assert(0 <= b and b <= 1, b, "hsb" .. bb, 0, 1)
    RangeError:assert(0 <= a and a <= 1, a, "hsb" .. aa, 0, 1)

    v = private[self].values

    v[1], v[2], v[3], v[4] = fromHSV(h, s, b, a)
end

function Color.__set:hsv(value)
    local h, s, v, a, hh, ss, vv, aa, val
    
    TypeError:assert(is(value, "table"), "hsv", type(value), "table")

    if value.hue then
        h  = value.hue
        hh = ".hue"
    elseif value.h then
        h  = value.h
        hh = ".h"
    elseif value[1] then
        h  = value[1]
        hh = "[1]"
    else
        UnsetError:throw("hue/h/[1]", "hsv")
    end

    if value.saturation then
        s  = value.saturation
        ss = ".saturation"
    elseif value.s then
        s  = value.s
        ss = ".s"
    elseif value[2] then
        s  = value[2]
        ss = "[2]"
    else
        UnsetError:throw("saturation/s/[2]", "hsv")
    end

    if value.value then
        v  = value.value
        vv = ".value"
    elseif value.v then
        v  = value.v
        vv = ".v"
    elseif value[3] then
        v  = value[3]
        vv = "[3]"
    else
        UnsetError:throw("value/v/[3]", "hsv")
    end

    if value.alpha then
        a  = value.alpha
        aa = ".alpha"
    elseif value.a then
        a  = value.a
        aa = ".a"
    elseif value[4] then
        a  = value[4]
        aa = "[4]"
    else
        a = 1
    end

    TypeError:assert(is(h, "number"), "hsv" .. hh, type(h), "number")
    TypeError:assert(is(s, "number"), "hsv" .. ss, type(s), "number")
    TypeError:assert(is(v, "number"), "hsv" .. vv, type(v), "number")
    TypeError:assert(is(a, "number"), "hsv" .. aa, type(a), "number")

    RangeError:assert(0 <= h and h <= 360, h, "hsv" .. hh, 0, 360)
    RangeError:assert(0 <= s and s <= 1, s, "hsv" .. ss, 0, 1)
    RangeError:assert(0 <= v and v <= 1, v, "hsv" .. vv, 0, 1)
    RangeError:assert(0 <= a and a <= 1, a, "hsv" .. aa, 0, 1)

    val = private[self].values

    val[1], val[2], val[3], val[4] = fromHSV(h, s, v, a)
end

    --======METAMETHODS======--

function Color:__tostring()
    return self:tostring(table.unpack(private[self].values))
end

Color.__type = "color"

return Object:create(Color, Unpack, Ipairs, AsTable)