local Object, private
local Color
local Vector
local Unpack, Ipairs, AsTable
local TypeError, ConstructorError, RangeError, UnsetError, LengthError, PatternError, InvalidError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Vector = require("classes.Vector")

Unpack  = require("classes.mixins.Unpack")
Ipairs  = require("classes.mixins.Ipairs")
AsTable = require("classes.mixins.AsTable")

TypeError        = require("classes.errors.TypeError")
UnsetError       = require("classes.errors.UnsetError")
RangeError       = require("classes.errors.RangeError")
LengthError      = require("classes.errors.LengthError")
PatternError     = require("classes.errors.PatternError")
InvalidError     = require("classes.errors.InvalidError")
ConstructorError = require("classes.errors.ConstructorError")

Color = Object:init()

    --======PRIVATE FUNCTIONS======--

local blend_modes_lut, blend_modes, internal
local from, to, blend

blend_modes_lut = {
    divide      = true,
    darken      = true,
    screen      = true,
    lighten     = true,
    overlay     = true,
    additive    = true,
    multiply    = true,
    exclusion   = true,
    soft_light  = true,
    difference  = true,
    hard_light  = true,
    subtractive = true
}

blend_modes = table.join(table.keys(blend_modes_lut), ", ", " and ")

--All the different blend modes. Use blend.calculate(mode) to actually
--use them; it does some vector math so that we can blend in amounts
--other than 50/50.
blend = {
    calculate = function(mode, a, b, percentage)
        local result = {}

        percentage = percentage * 2

        --Alpha's don't follow blending mode rules; we'll get some weird behaviours if
        --we do that. Instead, we simply average the two alphas together for a more
        --intuitive understanding of what would happen.
        a = Vector:fromValues(table.unpack(private[a].values, 1, 3)):multiply(percentage)
        b = Vector:fromValues(table.unpack(private[b].values, 1, 3)):multiply(2 - percentage)

        for i, v in a:ipairs() do
            result[i] = blend[mode](a, b):clamp(0, 1)
        end

        return result
    end,
    subtractive = function(a, b)
        return a - b
    end,
    difference = function(a, b)
        return math.abs(b - a)
    end,
    hard_light = function(a, b)
        if a < 0.5 then
            return blend.multiply(2 * a, b)
        end

        return blend.screen(2 * a - 1, b)
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

--All from functions are from <type> to rgb. To go from <type> to <diff_type>,
--you need to do from.<type> then use the output rgb in to.<diff_type>.
from = {
    hsv = function(h, s, v, a)
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
    end,
    hsl = function(h, s, l, a)
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
    end,
    hex = function(hex)
        local r, g, b, a
        
        if hex:startswith("#") then
            hex = hex:sub(2)
        end

        if #hex == 3 then
            r, g, b = hex:match("(%x)(%x)(%x)")
            
            PatternError:assert(r, hex, "(%x)(%x)(%x)")

            r = r:rep(2)
            g = g:rep(2)
            b = b:rep(2)
        end
        
        if #hex == 4 then
            r, g, b, a = hex:match("(%x)(%x)(%x)(%x)")

            PatternError:assert(r, hex, "(%x)(%x)(%x)(%x)")

            r = r:rep(2)
            g = g:rep(2)
            b = b:rep(2)
            a = a:rep(2)
        end
        
        if #hex == 6 then
            r, g, b = hex:match("(%x%x)(%x%x)(%x%x)")
            
            PatternError:assert(r, hex, "(%x%x)(%x%x)(%x%x)")
        end

        if #hex == 8 then
            r, g, b, a = hex:match("(%x%x)(%x%x)(%x%x)(%x%x)")
            
            PatternError:assert(r, hex, "(%x%x)(%x%x)(%x%x)(%x%x)")
        end

        a = a or "FF"

        return tonumber(r, 16) / 255,
               tonumber(g, 16) / 255,
               tonumber(b, 16) / 255,
               tonumber(a, 16) / 255
    end
}

--All to functions are from rgb to <type>. To go from <type> to <diff_type>,
--you need to do from.<type> then use the output rgb in to.<diff_type>.
to = {
    hsv = function(r, g, b, a)
        local s, v, diff, rr, gg, bb

        v    =     math.max(r, g, b)
        diff = v - math.min(r, g, b)
        
        if diff == 0 then return 0, 0, v, a end

        s  = diff / v
        rr = (v - r) / 6 / diff + 1 / 2
        gg = (v - g) / 6 / diff + 1 / 2
        bb = (v - b) / 6 / diff + 1 / 2
        
        if r == v then return math.round(math.clamp(          bb - gg, 0, 1) * 360), s, v, a end
        if g == v then return math.round(math.clamp((1 / 3) + rr - bb, 0, 1) * 360), s, v, a end
        if b == v then return math.round(math.clamp((2 / 3) + gg - rr, 0, 1) * 360), s, v, a end
    end,
    hsl = function(r, g, b, a)
        local min, max, diff, s, l

        min  = math.min(r, g, b)
        max  = math.max(r, g, b)
        diff = max - min

        l = (max + min) * 0.5
        s = diff / (1 - math.abs(2 * l - 1))

        if diff == 0 then return                                                     0, l, s, a end
        if max == r  then return math.round((((g - b) / diff) % 6) * 60):cycle(0, 360), l, s, a end
        if max == g  then return math.round(((b - r) / diff + 2)   * 60):cycle(0, 360), l, s, a end
        if max == b  then return math.round(((r - g) / diff + 4)   * 60):cycle(0, 360), l, s, a end
    end,
    hex = function(r, g, b, a)
        return string.format("%X", r * 255):padleft(2, "0") ..
               string.format("%X", g * 255):padleft(2, "0") ..
               string.format("%X", b * 255):padleft(2, "0") ..
               string.format("%X", a * 255):padleft(2, "0")
    end
}

      --======CONSTRUCTOR======--

---@see Color.fromHSV
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

    red, green, blue, alpha = from.hsv(hue, saturation, value, alpha)

    internal = math.uuid()

    return self {
        red      = red,
        blue     = blue,
        green    = green,
        alpha    = alpha,
        internal = internal
    }
end

---@see Color.fromHSB
function Color:fromHSB(hue, saturation, brightness, alpha)
    TypeError:assert(type(brightness) == "number", "brightness", type(brightness), "number")

    --HSV and HSB are the same thing. The only difference is a change in a single variable name,
    --so we check it here first. That way if it's incorrect, we can have the error message read
    --correctly. Everything else matches names, so we can just use all of the existing logic
    --since the error message will still say `hue` and still contain `fromHSB` in the trace.
    return self:fromHSV(hue, saturation, brightness, alpha)
end

---@see Color.fromHSL
function Color:fromHSL(hue, saturation, lightness, alpha)
    local red, green, blue

    alpha = alpha or 1

    TypeError:assert(type(hue) == "number", "hue", type(hue), "number")
    TypeError:assert(type(alpha) == "number", "alpha", type(alpha), "number")
    TypeError:assert(type(lightness) == "number", "lightness", type(lightness), "number")
    TypeError:assert(type(saturation) == "number", "saturation", type(saturation), "number")

    RangeError:assert(0 <= hue and hue <= 360, hue, "hue", 0, 360)
    RangeError:assert(0 <= alpha and alpha <= 1, alpha, "alpha", 0, 1)
    RangeError:assert(0 <= lightness and lightness <= 1, lightness, "lightness", 0, 1)
    RangeError:assert(0 <= saturation and saturation <= 1, saturation, "saturation", 0, 1)

    --A hue of 360 *is* a hue of zero. Technically it goes from 0 to 359.9999999.
    hue = hue == 360 and 0 or hue

    red, green, blue, alpha = from.hsl(hue, saturation, lightness, alpha)

    internal = math.uuid()

    return self {
        red      = red,
        blue     = blue,
        green    = green,
        alpha    = alpha,
        internal = internal
    }
end

---@see Color.fromRGB
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

---@see Color.fromRGB255
function Color:fromRGB255(red, green, blue, alpha)
    alpha = alpha or 1

    TypeError:assert(type(red) == "number", "red", type(red), "number")
    TypeError:assert(type(blue) == "number", "blue", type(blue), "number")
    TypeError:assert(type(green) == "number", "green", type(green), "number")
    TypeError:assert(type(alpha) == "number", "alpha", type(alpha), "number")

    RangeError:assert(0 <= red and red <= 255, red, "red", 0, 255)
    RangeError:assert(0 <= blue and blue <= 255, blue, "blue", 0, 255)
    RangeError:assert(0 <= green and green <= 255, green, "green", 0, 255)
    RangeError:assert(0 <= alpha and alpha <= 1, alpha, "alpha", 0, 1)

    internal = math.uuid()

    return self {
        red      = red / 255,
        blue     = blue / 255,
        green    = green / 255,
        alpha    = alpha,
        internal = internal
    }
end

---@see Color.fromHex
function Color:fromHex(hex)
    internal = math.uuid()

    TypeError:assert(type(hex) == "string", "hex", type(hex), "string")
    LengthError:assert(3 <= #hex and #hex <= 9, #hex, hex, 3, 9)

    local red, green, blue, alpha = from.hex(hex)

    return self {
        red      = red,
        blue     = blue,
        green    = green,
        alpha    = alpha,
        internal = internal
    }
end

---@see Color.new
function Color:new(opts)
    local p = private[self]
    
    ConstructorError:assert(opts.internal == internal, "Color")
    
    p.values = {
        opts.red,
        opts.green,
        opts.blue,
        opts.alpha
    }

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

---@see Color.apply
function Color:apply()
    love.graphics.setColor(private[self].values)
    
    return self
end

---@see Color.applyBackground
function Color:applyBackground()
    love.graphics.setBackgroundColor(private[self].values)
    
    return self
end

---@see Color.matches
function Color:matches(color)
    TypeError:assert(type(color) == "color", "color", type(color), "color")

    for i, v in ipairs(private[self].values) do
        if private[color].values[i] ~= v then return false end
    end

    return true
end

---@see Color.blend
function Color:blend(color, mode, percentage)
    local p = private[self]

    percentage = percentage or 1

    TypeError:assert(type(mode) == "string", "mode", type(mode), "string")
    TypeError:assert(type(color) == "color", "color", type(color), "color")
    TypeError:assert(type(percentage) == "number", "percentage", type(percentage), "number")
    RangeError:assert(0 <= percentage and percentage <= 1, percentage, "percentage", 0, 1)

    mode = mode:lower()

    InvalidError:assert(blend_modes_lut[mode], mode, "mode", blend_modes)

    for i, v in ipairs(blend.calculate(mode, self, color, percentage or 0.5)) do
        p.values[i] = v
    end

    --Rather than using blend mode rules on alpha values, we just average the two together.
    --Otherwise the behaviour of blend will feel wonky.
    p.values[4] = (p.values[4] + private[color][4]) * 0.5

    p.rgb    = nil
    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.hsl    = nil
    p.rgb255 = nil

    return self
end

---@see Color.clone
function Color:clone()
    local p = private[self]

    internal = math.uuid()

    return self {
        red      = p.values[1],
        blue     = p.values[2],
        green    = p.values[3],
        alpha    = p.values[4],
        internal = internal
    }
end

    --======GETTERS======--

function Color.__get:hex()
    local p = private[self]

    if not p.hex then
        p.hex = to.hex(table.unpack(p.values))
    end

    return p.hex
end

function Color.__get:hsv_hue()
    return self.hsv.hue
end

function Color.__get:hsv_saturation()
    return self.hsv.saturation
end

function Color.__get:hsl_hue()
    return self.hsl.hue
end

function Color.__get:hsl_saturation()
    return self.hsl.saturation
end

function Color.__get:value()
    return self.hsv.value
end

function Color.__get:brightness()
    return self.hsb.brightness
end

function Color.__get:lightness()
    return self.hsl.lightness
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
    return math.round(private[self].values[1] * 255)
end

function Color.__get:green255()
    return math.round(private[self].values[2] * 255)
end

function Color.__get:blue255()
    return math.round(private[self].values[3] * 255)
end

function Color.__get:alpha()
    return private[self].values[4]
end

function Color.__get:rgb()
    local p = private[self]

    if not p.rgb then
        p.rgb = {
            red   = p.values[1],
            blue  = p.values[2],
            green = p.values[3],
            alpha = p.values[4]
        }
    end

    return p.rgb
end

function Color.__get:rgb255()
    local p = private[self]

    if not p.rgb255 then
        p.rgb255 = {
            red   = math.round(p.values[1] * 255),
            blue  = math.round(p.values[2] * 255),
            green = math.round(p.values[3] * 255),
            alpha = p.values[4]
        }
    end

    return p.rgb255
end

function Color.__get:hsl()
    local p = private[self]

    if not p.hsl then
        local hue, saturation, lightness, alpha = to.hsl(table.unpack(p.values))

        p.hsl = {
            hue        = hue,
            alpha      = alpha,
            lightness  = lightness,
            saturation = saturation
        }
    end

    return p.hsl
end

function Color.__get:hsb()
    local p = private[self]

    if not p.hsb then
        local hue, saturation, value, alpha = to.hsv(table.unpack(p.values))

        p.hsv = {
            hue        = hue,
            value      = value,
            alpha      = alpha,
            saturation = saturation
        }

        p.hsb = {
            hue        = hue,
            alpha      = alpha,
            brightness = value,
            saturation = saturation
        }
    end

    return p.hsb
end

function Color.__get:hsv()
    local p = private[self]

    if not p.hsv then
        local hue, saturation, value, alpha = to.hsv(table.unpack(p.values))

        p.hsv = {
            hue        = hue,
            value      = value,
            alpha      = alpha,
            saturation = saturation
        }

        p.hsb = {
            hue        = hue,
            alpha      = alpha,
            brightness = value,
            saturation = saturation
        }
    end

    return p.hsv
end

    --======SETTERS======--

function Color.__set:hex(value)
    local p = private[self]

    TypeError:assert(type(value) == "string", "hex", type(value), "string")
    LengthError:assert(3 <= #value and #value <= 9, #value, hex, 3, 9)

    p.hex    = nil
    p.hsb    = nil
    p.hsl    = nil
    p.hsv    = nil
    p.rgb    = nil
    p.rgb255 = nil

    --Doesn't set p.hex, since we don't know the format of value without calculating, and
    --we're only bothering to set if no calculations are needed.
    p.values = { from.hex(value) }
end

function Color.__set:hsv_hue(value)
    local p, hue, saturation, vvalue, alpha

    p = private[self]

    TypeError:assert(type(value) == "number", "hsv_hue", type(value), "number")
    RangeError:assert(0 <= value and value <= 360, value, "hsv_hue", 0, 360)

    value = value == 360 and 0 or value

    hue, saturation, vvalue, alpha = to.hsv(table.unpack(p.values))

    p.hex    = nil
    p.hsl    = nil
    p.rgb    = nil
    p.rgb255 = nil

    p.hsv = {
        hue        = value,
        value      = vvalue,
        alpha      = alpha,
        saturation = saturation
    }

    p.hsb = {
        hue        = value,
        alpha      = alpha,
        brightness = vvalue,
        saturation = saturation
    }

    p.values = { from.hsv(table.values(p.hsv)) }
end

function Color.__set:hsv_saturation(value)
    local p, hue, saturation, vvalue, alpha

    p = private[self]

    TypeError:assert(type(value) == "number", "hsv_saturation", type(value), "number")
    RangeError:assert(0 <= value and value <= 360, value, "hsv_saturation", 0, 360)

    value = value == 360 and 0 or value

    hue, saturation, vvalue, alpha = to.hsv(table.unpack(p.values))

    p.hex    = nil
    p.hsl    = nil
    p.rgb    = nil
    p.rgb255 = nil

    p.hsv = {
        hue        = hue,
        value      = vvalue,
        alpha      = alpha,
        saturation = value
    }

    p.hsb = {
        hue        = hue,
        alpha      = alpha,
        brightness = vvalue,
        saturation = value
    }

    p.values = { from.hsv(table.values(p.hsv)) }
end

function Color.__set:hsl_hue(value)
    local p, hue, saturation, lightness, alpha

    p = private[self]

    TypeError:assert(type(value) == "number", "hsl_hue", type(value), "number")
    RangeError:assert(0 <= value and value <= 360, value, "hsl_hue", 0, 360)

    value = value == 360 and 0 or value

    hue, saturation, lightness, alpha = to.hsl(table.unpack(p.values))

    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.rgb    = nil
    p.rgb255 = nil

    p.hsl = {
        hue        = value,
        alpha      = alpha,
        lightness  = lightness,
        saturation = saturation
    }

    p.values = { from.hsl(table.values(p.hsl)) }
end

function Color.__set:hsl_saturation(value)
    local p, hue, saturation, lightness, alpha

    p = private[self]

    TypeError:assert(type(value) == "number", "hsl_saturation", type(value), "number")
    RangeError:assert(0 <= value and value <= 360, value, "hsl_saturation", 0, 360)

    value = value == 360 and 0 or value

    hue, saturation, lightness, alpha = to.hsl(table.unpack(p.values))

    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.rgb    = nil
    p.rgb255 = nil

    p.hsl = {
        hue        = hue,
        alpha      = alpha,
        lightness  = lightness,
        saturation = value
    }

    p.values = { from.hsl(table.values(p.hsl)) }
end

function Color.__set:value(value)
    local p, hue, saturation, vvalue, alpha

    p = private[self]

    TypeError:assert(type(value) == "number", "value", type(value), "number")
    RangeError:assert(0 <= value and value <= 360, value, "value", 0, 360)

    value = value == 360 and 0 or value

    hue, saturation, vvalue, alpha = to.hsv(table.unpack(p.values))

    p.hex    = nil
    p.hsl    = nil
    p.rgb    = nil
    p.rgb255 = nil

    p.hsv = {
        hue        = value,
        value      = vvalue,
        alpha      = alpha,
        saturation = saturation
    }

    p.hsb = {
        hue        = value,
        alpha      = alpha,
        brightness = vvalue,
        saturation = saturation
    }

    p.values = { from.hsv(table.values(p.hsv)) }
end

function Color.__set:brightness(value)
    TypeError:assert(type(value) == "number", "brightness", type(value), "number")
    RangeError:assert(0 <= value and value <= 360, value, "brightness", 0, 360)

    self.value = value
end

function Color.__set:lightness(value)
    local p, hue, saturation, lightness, alpha

    p = private[self]

    TypeError:assert(type(value) == "number", "lightness", type(value), "number")
    RangeError:assert(0 <= value and value <= 360, value, "lightness", 0, 360)

    value = value == 360 and 0 or value

    hue, saturation, lightness, alpha = to.hsl(table.unpack(p.values))

    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.rgb    = nil
    p.rgb255 = nil

    p.hsl = {
        hue        = hue,
        alpha      = alpha,
        lightness  = value,
        saturation = saturation
    }

    p.values = { from.hsl(table.values(p.hsl)) }
end

function Color.__set:red(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "red", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "red", 0, 1)

    p.rgb    = nil
    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.hsl    = nil
    p.rgb255 = nil

    p.values[1] = value
end

function Color.__set:green(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "green", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "green", 0, 1)

    p.rgb    = nil
    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.hsl    = nil
    p.rgb255 = nil

    p.values[2] = value
end

function Color.__set:blue(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "blue", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "blue", 0, 1)

    p.rgb    = nil
    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.hsl    = nil
    p.rgb255 = nil

    p.values[3] = value
end

function Color.__set:red255(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "red255", type(value), "number")
    RangeError:assert(0 <= value and value <= 255, value, "red255", 0, 255)

    p.rgb    = nil
    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.hsl    = nil
    p.rgb255 = nil

    p.values[1] = value / 255
end

function Color.__set:green255(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "green255", type(value), "number")
    RangeError:assert(0 <= value and value <= 255, value, "green255", 0, 255)

    p.rgb    = nil
    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.hsl    = nil
    p.rgb255 = nil

    p.values[2] = value / 255
end

function Color.__set:blue255(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "blue255", type(value), "number")
    RangeError:assert(0 <= value and value <= 255, value, "blue255", 0, 255)

    p.rgb    = nil
    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.hsl    = nil
    p.rgb255 = nil

    p.values[3] = value / 255
end

function Color.__set:alpha(value)
    local p = private[self]

    TypeError:assert(type(value) == "number", "alpha", type(value), "number")
    RangeError:assert(0 <= value and value <= 1, value, "alpha", 0, 1)

    p.rgb    = nil
    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.hsl    = nil
    p.rgb255 = nil

    p.values[4] = value
end

function Color.__set:rgb(value)
    local p, red, green, blue, alpha
    
    p = private[self]

    TypeError:assert(type(value) == "table", "rgb", type(value), "table")

    UnsetError:assert(value.red or value.r or value[1], "red/r/[1]", "rgb")
    UnsetError:assert(value.blue or value.b or value[3], "blue/b/[3]", "rgb")
    UnsetError:assert(value.green or value.g or value[2], "green/g/[2]", "rgb")    
    
    red   = value.red or value.r or value[1]
    blue  = value.blue or value.b or value[3]
    green = value.green or value.g or value[2]
    alpha = value.alpha or value.a or value[4] or 1

    TypeError:assert(type(red) == "number", "rgb.red/rgb.r/rgb[1]", type(red), "number")
    TypeError:assert(type(blue) == "number", "rgb.blue/rgb.b/rgb[3]", type(blue), "number")
    TypeError:assert(type(green) == "number", "rgb.green/rgb.g/rgb[2]", type(green), "number")
    TypeError:assert(type(alpha) == "number", "rgb.alpha/rgb.a/rgb[4]", type(alpha), "number")

    RangeError:assert(0 <= red and red <= 1, red, "rgb.red/rgb.r/rgb[1]", 0, 1)
    RangeError:assert(0 <= blue and blue <= 1, blue, "rgb.blue/rgb.b/rgb[3]", 0, 1)
    RangeError:assert(0 <= green and green <= 1, green, "rgb.green/rgb.g/rgb[2]", 0, 1)
    RangeError:assert(0 <= alpha and alpha <= 1, alpha, "rgb.alpha/rgb.a/rgb[4]", 0, 1)

    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.hsl    = nil
    p.rgb255 = nil

    p.values = { red, green, blue, alpha }

    p.rgb = {
        red   = red,
        blue  = blue,
        green = green,
        alpha = alpha
    }
end

function Color.__set:rgb255(value)
    local p, red, green, blue, alpha
    
    p = private[self]

    TypeError:assert(type(value) == "table", "rgb255", type(value), "table")

    UnsetError:assert(value.red or value.r or value[1], "red/r/[1]", "rgb255")
    UnsetError:assert(value.blue or value.b or value[3], "blue/b/[3]", "rgb255")
    UnsetError:assert(value.green or value.g or value[2], "green/g/[2]", "rgb255")    
    
    red   = value.red or value.r or value[1]
    blue  = value.blue or value.b or value[3]
    green = value.green or value.g or value[2]
    alpha = value.alpha or value.a or value[4] or 1

    TypeError:assert(type(red) == "number", "rgb255.red/rgb255.r/rgb255[1]", type(red), "number")
    TypeError:assert(type(blue) == "number", "rgb255.blue/rgb255.b/rgb255[3]", type(blue), "number")
    TypeError:assert(type(green) == "number", "rgb255.green/rgb255.g/rgb255[2]", type(green), "number")
    TypeError:assert(type(alpha) == "number", "rgb255.alpha/rgb255.a/rgb255[4]", type(alpha), "number")

    RangeError:assert(0 <= red and red <= 255, red, "rgb255.red/rgb255.r/rgb255[1]", 0, 255)
    RangeError:assert(0 <= blue and blue <= 255, blue, "rgb255.blue/rgb255.b/rgb255[3]", 0, 255)
    RangeError:assert(0 <= green and green <= 255, green, "rgb255.green/rgb255.g/rgb255[2]", 0, 255)
    RangeError:assert(0 <= alpha and alpha <= 255, alpha, "rgb255.alpha/rgb255.a/rgb255[4]", 0, 255)

    p.rgb = nil
    p.hex = nil
    p.hsb = nil
    p.hsv = nil
    p.hsl = nil

    p.values = { red / 255, green / 255, blue / 255, alpha }

    p.rgb255 = {
        red   = red,
        blue  = blue,
        green = green,
        alpha = alpha
    }
end

function Color.__set:hsl(value)
    local p, hue, saturation, lightness, alpha
    
    p = private[self]

    TypeError:assert(type(value) == "table", "hsl", type(value), "table")

    UnsetError:assert(value.hue or value.h or value[1], "hue/h/[1]", "hsl")
    UnsetError:assert(value.lightness or value.l or value[3], "lightness/l/[3]", "hsl")
    UnsetError:assert(value.saturation or value.s or value[2], "saturation/s/[2]", "hsl")
    
    hue        = value.hue or value.h or value[1]
    alpha      = value.alpha or value.a or value[4] or 1
    lightness  = value.lightness or value.l or value[3]
    saturation = value.saturation or value.s or value[2]

    TypeError:assert(type(hue) == "number", "hsl.hue/hsl.h/hsl[1]", type(hue), "number")
    TypeError:assert(type(alpha) == "number", "hsl.alpha/hsl.a/hsl[4]", type(alpha), "number")
    TypeError:assert(type(lightness) == "number", "hsl.lightness/hsl.l/hsl[3]", type(lightness), "number")
    TypeError:assert(type(saturation) == "number", "hsl.saturation/hsl.s/hsl[2]", type(saturation), "number")

    RangeError:assert(0 <= hue and hue <= 360, hue, "hsl.hue/hsl.h/hsl[1]", 0, 360)
    RangeError:assert(0 <= alpha and alpha <= 1, alpha, "hsl.alpha/hsl.a/hsl[4]", 0, 1)
    RangeError:assert(0 <= lightness and lightness <= 1, lightness, "hsl.lightness/hsl.l/hsl[3]", 0, 1)
    RangeError:assert(0 <= saturation and saturation <= 1, saturation, "hsl.saturation/hsl.s/hsl[2]", 0, 1)

    p.rgb    = nil
    p.hex    = nil
    p.hsb    = nil
    p.hsv    = nil
    p.rgb255 = nil

    p.values = { from.hsl(hue, saturation, lightness, alpha) }

    p.hsl = {
        hue        = hue,
        alpha      = alpha,
        lightness  = lightness,
        saturation = saturation
    }
end

function Color.__set:hsb(value)
    --Since hsb and hsv are the same, we do the "b" error checking first, then pass it over
    --to hsl to do the rest.
    TypeError:assert(type(value) == "table", "hsb", type(value), "table")

    UnsetError:assert(value.brightness or value.b or value[3], "brightness/b/[3]", "hsb")

    local brightness = value.brightness or value.b or value[3]

    TypeError:assert(type(brightness) == "number", "hsb.brightness/hsb.b/hsb[3]", type(brightness), "number")

    RangeError:assert(0 <= brightness and brightness <= 1, brightness, "hsb.brightness/hsb.b/hsb[3]", 0, 1)

    self.hsv = value
end

function Color.__set:hsv(value)
    local p, hue, saturation, vvalue, alpha
    
    p = private[self]

    TypeError:assert(type(value) == "table", "hsv", type(value), "table")

    UnsetError:assert(value.hue or value.h or value[1], "hue/h/[1]", "hsv")
    UnsetError:assert(value.value or value.v or value[3], "value/v/[3]", "hsv")
    UnsetError:assert(value.saturation or value.s or value[2], "saturation/s/[2]", "hsv")
    
    hue        = value.hue or value.h or value[1]
    alpha      = value.alpha or value.a or value[4] or 1
    vvalue     = value.value or value.v or value[3]
    saturation = value.saturation or value.s or value[2]

    TypeError:assert(type(hue) == "number", "hsv.hue/hsv.h/hsv[1]", type(hue), "number")
    TypeError:assert(type(alpha) == "number", "hsv.alpha/hsv.a/hsv[4]", type(alpha), "number")
    TypeError:assert(type(vvalue) == "number", "hsv.value/hsv.v/hsv[3]", type(vvalue), "number")
    TypeError:assert(type(saturation) == "number", "hsv.saturation/hsv.s/hsv[2]", type(saturation), "number")

    RangeError:assert(0 <= hue and hue <= 360, hue, "hsv.hue/hsv.h/hsv[1]", 0, 360)
    RangeError:assert(0 <= alpha and alpha <= 1, alpha, "hsv.alpha/hsv.a/hsv[4]", 0, 1)
    RangeError:assert(0 <= vvalue and vvalue <= 1, vvalue, "hsv.value/hsv.v/hsv[3]", 0, 1)
    RangeError:assert(0 <= saturation and saturation <= 1, saturation, "hsv.saturation/hsv.s/hsv[2]", 0, 1)

    p.rgb    = nil
    p.hex    = nil
    p.hsl    = nil
    p.rgb255 = nil

    p.values = { from.hsv(hue, saturation, vvalue, alpha) }

    p.hsv = {
        hue        = hue,
        alpha      = alpha,
        value      = vvalue,
        saturation = saturation
    }

    p.hsb = {
        hue        = hue,
        alpha      = alpha,
        brightness = vvalue,
        saturation = saturation
    }
end

    --======METAMETHODS======--

function Color:__tostring()
    return self:tostring(table.unpack(private[self].values))
end

Color.__type = "color"

---@type Color.Class
local Class = Object:create(Color, Unpack, Ipairs, AsTable)

return Class