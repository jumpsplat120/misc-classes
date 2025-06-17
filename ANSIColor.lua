---@type Object
local Object
local ANSIColor, private, is, TL
local TypeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

TL = require("lib.string_template")
is = require("lib.is")

TypeError = require("classes.errors.TypeError")

ANSIColor = Object:extend()

    --======PRIVATE FUNCTIONS======--

local singleton, esc, fg, bg, ctrl

fg   = 38
bg   = 48
ctrl = "\28"
esc  = "\27"

    --======CONSTRUCTOR======--

function ANSIColor:new()
    if singleton then return singleton end

    singleton = self
end

    --======METHODS======--      

function ANSIColor:parseString(value)
    local clear, output
    
    TypeError:assert(is(value, "string"), "value", type(value), "string")

    clear  = value:gsub("{(b?)#(%x%x)(%x%x)(%x%x)}(.-){#/}", ctrl):split(ctrl)
    output = {}
    
    output[#output + 1] = table.remove(clear, 1)
    
    for pos, r, g, b, text in value:gfind("{(b?)#(%x%x)(%x%x)(%x%x)}(.-){#/}") do
        output[#output + 1] = TL(
            "%{esc}[%{pos == 'b' and bg or fg};2;"   ..
            "%{tonumber(r, 16)};%{tonumber(g, 16)};" .. 
            "%{tonumber(b, 16)}m%{text}%{esc}[0m", {
                text = text,
                esc = esc,
                pos = pos,
                r = r,
                g = g,
                b = b,
                fg = fg,
                bg = bg
            })
        
        output[#output + 1] = table.remove(clear, 1)
    end

    return table.join(output, "")
end


function ANSIColor:parseTable(...)
    assert("Under construction.")
end

    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function ANSIColor:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper("singleton") end

    return self:tostringHelper("Class")
end

ANSIColor.__type = "ansi_color"

return ANSIColor