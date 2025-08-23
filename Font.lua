---@type Object
local Object
local Font, Symbol, private
local TypeError, InvalidError, FileTypeError, ConstructorError, GlyphRenderError
local utf8
local is, TL

Object = require("lib.Classy")
Symbol = require("lib.Classy.Symbol")
private = require("lib.Classy.instances")

GlyphRenderError = require("classes.errors.GlyphRenderError")
ConstructorError = require("classes.errors.ConstructorError")
FileTypeError    = require("classes.errors.FileTypeError")
InvalidError     = require("classes.errors.InvalidError")
TypeError        = require("classes.errors.TypeError")

utf8 = require("utf8")

TL = require("lib.string_template")
is = require("lib.is")

Font = Object:extend()

    --======PRIVATE FUNCTIONS======--

local NORMAL, LIGHT, MONO, NONE
local NEAREST, LINEAR
local symbols, internal

NEAREST = Symbol("nearest")
LINEAR  = Symbol("linear")

NORMAL = Symbol("normal")
LIGHT  = Symbol("light")
MONO   = Symbol("mono")
NONE   = Symbol("none")

private[Font] = {
    hinting = {
        [NORMAL] = true,
        [LIGHT]  = true,
        [MONO]   = true,
        [NONE]   = true
    },
    filter = {
        [NEAREST] = true,
        [LINEAR]  = true
    }
}

symbols = {
    hinting = table.join(table.keys(private[Font].hinting), ", "),
    filter  = table.join(table.keys(private[Font].filter), ", ")
}

local function convertToStrings(i, v)
    if is(v, "number") then return i, utf8.char(v) end
    if is(v, "string") then
        if #v <= 1 then return i, v end
        
        return i, v:split()
    end

    TypeError:throw(TL("args[%{i}]", { i = i }), type(v), "string/number")
end

local function anyTrue(_, a, b)
    return a and b
end

    --======CONSTRUCTOR======--

function Font:fromDefault(size, hinting, dpi)
    hinting = hinting or NORMAL
    size    = size or 12
    dpi     = dpi or love.graphics.getDPIScale()
    
    TypeError:assert(is(hinting, Symbol), "hinting", type(hinting), Symbol)
    TypeError:assert(is(size, "number"), "size", type(size), "number")
    TypeError:assert(is(dpi, "number"), "dpi", type(dpi), "number")

    InvalidError:assert(private[Font].hinting[hinting], hinting, "hinting", symbols.hinting)

    internal = math.uuid()
    
    return Font{
        internal  = internal,
        hinting   = hinting,
        type      = "default",
        size      = size,
        dpi       = dpi
    }
end

function Font:fromTTF(font_path, size, hinting, dpi)
    TypeError:assert(is(font_path, "string"), "font_path", type(font_path), "string")

    hinting = hinting or NORMAL
    size    = size or 12
    dpi     = dpi or love.graphics.getDPIScale()
    
    TypeError:assert(is(hinting, Symbol), "hinting", type(hinting), Symbol)
    TypeError:assert(is(size, "number"), "size", type(size), "number")
    TypeError:assert(is(dpi, "number"), "dpi", type(dpi), "number")

    InvalidError:assert(private[Font].hinting[hinting], hinting, "hinting", symbols.hinting)

    internal = math.uuid()

    return Font{
        font_path = font_path,
        internal  = internal,
        hinting   = hinting,
        type      = "ttf",
        size      = size,
        dpi       = dpi
    }
end

function Font:fromBMF(font_path, image_path)
    TypeError:assert(is(font_path, "string"), "font_path", type(font_path), "string")
    TypeError:assert(is(image_path, "string"), "image_path", type(image_path), "string")

    internal = math.uuid()

    return Font{
        image_path = image_path,
        font_path  = font_path,
        internal   = internal,
        type       = "bmf"
    }
end

function Font:new(opts)
    local p = private[self]

    ConstructorError:assert(is(opts, "table") and opts.internal == internal, Font)

    p.glyphs = {}
    p.kerns  = {}
    p.type   = opts.type
    
    if p.type == "ttf" then
        p.font_path = opts.font_path
        p.hinting   = opts.hinting
        p.size      = opts.size
        p.dpi       = opts.dpi

        p.name = select(-1, table.unpack(p.font_path:split("/"))):before(".")
        p.font = love.graphics.newFont(p.font_path, p.size, p.hinting.id, p.dpi)
    end

    if p.type == "bmf" then
        p.image_path = opts.image_path
        p.font_path  = opts.font_path

        p.name = select(-1, table.unpack(p.font_path:split("/"))):before(".")
        p.font = love.graphics.newFont(p.font_path, p.image_path)
    end

    if p.type == "default" then
        p.hinting = opts.hinting
        p.size    = opts.size
        p.dpi     = opts.dpi

        p.name = "Vera Sans"
        p.font = love.graphics.newFont(p.size, p.hinting.id, p.dpi)
    end
end

    --======METHODS======--

function Font:kerning(a, b)
    local p, concat
    
    p = private[self]
    
    if a == "" then return 0 end
    if b == "" then return 0 end

    if is(a, "number") then a = utf8.char(a) end
    if is(b, "number") then b = utf8.char(b) end

    TypeError:assert(is(a, "string"), "a", type(a), "string/number")
    TypeError:assert(is(b, "string"), "b", type(b), "string/number")

    concat = a .. b

    if p.kerns[concat] then return p.kerns[concat] end

    GlyphRenderError:assert(self:canRenderAll(a), utf8.codepoint(a), p.name)
    GlyphRenderError:assert(self:canRenderAll(b), utf8.codepoint(b), p.name)

    p.kerns[concat] = p.font:getKerning(a, b)

    return p.kerns[concat]
end

function Font:width(text)
    local p = private[self]

    TypeError:assert(is(text, "string"), "text", type(text), "string")
    
    if text == "" then return 0 end
    
    GlyphRenderError:assert(self:canRenderAll(text), text, p.name)

    return private[self].font:getWidth(text)
end

--Take a string, and return a version of it that strips out all unrenderable characters.
function Font:strip(text)
    for char, valid in pairs(self:canRender(text)) do
        if not valid then
            text = text:gsub(char, "")
        end
    end

    return text
end

--Pass in a string or multiple strings, and get a table of which characters can and
--cannot be rendered.
function Font:canRender(...)
    local p = private[self]

    return table.foreach(
        table.imerge(
            table.unpack(
                table.foreach({ ... }, convertToStrings)
        )),
        function(_, v)
            if p.glyphs[v] ~= nil then
                return v, p.glyphs[v]
            end
            
            p.glyphs[v] = p.font:hasGlyphs(v)
            
            return v, p.glyphs[v]
        end
    )
end

--Pass in a string or multiple strings, and returns true only if the entire string
--can be rendered.
function Font:canRenderAll(...)
    return table.reduce(table.values(self:canRender(...)), anyTrue)
end

function Font:fallbacks(...)
    local p, args

    p    = private[self]
    args = { ... }

    for i, font in ipairs(args) do
        local index = TL("args[%{i}]", { i = i })

        TypeError:assert(is(font, Font), index, type(font), Font)
        FileTypeError:assert(font.type == p.type, index, font.type, p.type)
    end

    p.font:setFallbacks(...)

    return self
end

function Font:apply()
    local p, prev
    
    p    = private[self]
    prev = love.graphics.getFont()

    if p.temp         then return self end
    if prev == p.font then return self end

    p.temp = prev

    love.graphics.setFont(p.font)

    return self
end

function Font:remove()
    local p, prev
    
    p    = private[self]
    prev = love.graphics.getFont()

    if not p.temp then return self end
    
    if prev ~= p.font then
        p.temp = nil

        return self
    end

    love.graphics.setFont(p.temp)

    p.temp = nil
    
    return self
end

function Font:clone()
    local p, font
    
    internal = math.uuid()

    p    = private[self]
    font = Font{
        internal = internal,
        type = p.type,
        font_path = p.font_path,
        hinting = p.hinting,
        size = p.size,
        dpi = p.dpi,
        image_path = p.image_path
    }

    for k, _ in pairs(p.glyphs) do
        private[font].glyphs[k] = true
    end

    for k, v in pairs(p.kerns) do
        private[font].kerns[k] = v
    end

    return font
end

    --======GETTERS======--

function Font.__get:size()
    return private[self].size
end

function Font.__get:hinting()
    return private[self].hinting
end

function Font.__get:ascent()
    return private[self].font:getAscent()
end

function Font.__get:descent()
    return private[self].font:getDescent()
end

function Font.__get:baseline()
    return private[self].font:getBaseline()
end

function Font.__get:dpi()
    return private[self].font:getDPIScale()
end

function Font.__get:filter()
    local p, min, max, anisotropy
    
    p = private[self]

    min, max, anisotropy = p.font:getFilter()

    return {
        anisotropy = anisotropy,
        min = min == "nearest" and NEAREST or LINEAR,
        max = max == "nearest" and NEAREST or LINEAR
    }
end

function Font.__get:min_filter()
    local p = private[self]

    local min, _, _ = p.font:getFilter()

    return min
end

function Font.__get:max_filter()
    local p = private[self]

    local _, max, _ = p.font:getFilter()

    return max
end

function Font.__get:filter_anisotropy()
    local p = private[self]

    local _, _, anisotropy = p.font:getFilter()

    return anisotropy
end

function Font.__get:height()
    return private[self].font:getHeight()
end

function Font.__get:line_height()
    return private[self].font:getLineHeight()
end

    --======SETTERS======--

function Font.__set:size(value)
    local p = private[self]

    --TODO: Make this a real error
    if p.type == "bmf" then
        error("Unable to set BMF font size.")
    end

    TypeError:assert(is(value, "number"), "size", type(value), "number")
        
    p.size = value
    p.font = p.type == "ttf" and love.graphics.newFont(p.font_path, p.size, p.hinting.id, p.dpi) or
                                 love.graphics.newFont(p.size, p.hinting.id, p.dpi)
end

function Font.__set:hinting(value)
    local p = private[self]

    if p.type ~= "bmf" then
        TypeError:assert(is(value, "number"), "hinting", type(value), "number")
        
        p.hinting = value
        p.font    = love.graphics.newFont(p.font_path, p.size, p.hinting, p.dpi)
    end
end

function Font.__set:dpi(value)
    local p = private[self]

    if p.type ~= "bmf" then
        TypeError:assert(is(value, "number"), "dpi", type(value), "number")
        
        p.dpi  = value
        p.font = love.graphics.newFont(p.font_path, p.size, p.hinting, p.dpi)
    end
end

function Font.__set:line_height(value)
    local p = private[self]

    TypeError:assert(is(value, "number"), "line_height", type(value), "number")

    p.font:setLineHeight(value)
end

function Font.__set:filter(value)
    TypeError:assert(is(value, "table"), "filter", type(value), "table")

    local result = {}

    table.map(value, function(k, v)
        if k == "min" or k == "max" then
            InvalidError:assert(private[Font].filter[v], v, "filter." .. k, symbols.filter)
            
            result[k] = v
        end

        if k == "anisotropy" then
            TypeError:assert(is(v, "number"), "filter.anisotropy", type(v), "number")

            result[k] = v
        end

        return k, v
    end)

    private[self].filter = result
end

function Font.__set:min_filter(value)
    local p = private[self]

    TypeError:assert(is(value, Symbol), "min_filter", type(value), Symbol)
    InvalidError:assert(private[Font].filter[value], value, "min_filter", symbols.filter)

    if not p.filter then
        local min, max, anisotropy = p.font:getFilter()

        p.filter = {
            anisotropy = anisotropy,
            min = min == "nearest" and NEAREST or LINEAR,
            max = max == "nearest" and NEAREST or LINEAR
        }
    end

    p.filter.min = value

    p.font:setFilter(p.filter.min.id, p.filter.max.id, p.filter.anisotropy)
end

function Font.__set:max_filter(value)
    local p = private[self]

    TypeError:assert(is(value, Symbol), "max_filter", type(value), Symbol)
    InvalidError:assert(private[Font].filter[value], value, "max_filter", symbols.filter)

    if not p.filter then
        local min, max, anisotropy = p.font:getFilter()

        p.filter = {
            anisotropy = anisotropy,
            min = min == "nearest" and NEAREST or LINEAR,
            max = max == "nearest" and NEAREST or LINEAR
        }
    end

    p.filter.max = value

    p.font:setFilter(p.filter.min.id, p.filter.max.id, p.filter.anisotropy)
end

function Font.__set:filter_anisotropy(value)
    local p = private[self]

    TypeError:assert(is(value, "number"), "filter_anisotropy", type(value), "number")

    if not p.filter then
        local min, max, anisotropy = p.font:getFilter()

        p.filter = {
            anisotropy = anisotropy,
            min = min == "nearest" and NEAREST or LINEAR,
            max = max == "nearest" and NEAREST or LINEAR
        }
    end

    p.filter.anisotropy = value

    p.font:setFilter(p.filter.min.id, p.filter.max.id, p.filter.anisotropy)
end

    --======METAMETHODS======--

function Font:__tostring()
    if self.is_instance then return self:tostringHelper(private[self].name) end

    return self:tostringHelper("Class")
end

Font.__type = "font"

return Font