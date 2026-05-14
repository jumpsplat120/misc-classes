local Object, private
local ANSIColor
local vararg
local MalformedStringError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

vararg = require("lib.varargs")

MalformedStringError = require("classes.errors.MalformedStringError")

ANSIColor = Object:init()

    --======PRIVATE FUNCTIONS======--

local singleton

    --======CONSTRUCTOR======--

function ANSIColor:new()
    if singleton then return singleton end

    singleton = self
end

    --======METHODS======--

    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function ANSIColor:__call(...)
    local pos, colors, output, value, err

    pos    = 1
    err    = "have a less-than-or-equal amount of opening tags to closing tags"
    output = {}
    colors = { "\27[0m" }

    --Take all values, and convert them to strings, the way that `print` does.
    for _, v in vararg(...) do
        table.insert(output, tostring(v))
    end

    value  = table.concat(output, "\t")
    output = {}

    --Scan through the string, matching opening and closing tags, moving the
    --pos search up to whatever is relevant. This lets us do stacked colors,
    --which gsub or gmatch would not allow us to do.
    while true do
        local open, close

        open  = { value:find("{(b?)#(%x%x)(%x%x)(%x%x)}", pos) }
        close = { value:find("{#/}", pos) }

        --No more color codes found.
        if not (open[1] or close[1]) then
            table.insert(output, value:sub(pos))

            break
        end
        
        --There's a closing tag, but nothing to close.
        MalformedStringError:assert(not (close[1] and #colors == 0), value, err)

        --There's an opening tag, but no following closing tag.
        MalformedStringError:assert(not (open[1] and not close[1]), value, err)
        
        if (open[1] or math.huge) < close[1] then
            table.insert(colors, string.format("\27[%s;2;%s;%s;%sm",
                open[3] == "b" and 48 or 38,
                tonumber(open[4], 16),
                tonumber(open[5], 16),
                tonumber(open[6], 16)
            ))

            table.insert(output, value:sub(pos, open[1] - 1))
            table.insert(output, colors[#colors])

            pos = open[2] + 1
        else
            table.remove(colors)
            table.insert(output, value:sub(pos, close[1] - 1))
            table.insert(output, colors[#colors])

            pos = close[2] + 1
        end
    end

    print(table.join(output, ""))
end

function ANSIColor:__tostring()
    local p = private[self]

    return self:tostring("singleton")
end

ANSIColor.__type = "ansi_color"

---@type ANSIColor.Class
local Class = Object:create(ANSIColor)

return Class