local Object = require("lib.Classy")
local private = require("lib.Classy.instances")

local Swizzle = Object:extend()

local floor,insert = math.floor, table.insert

local swizzle_lut = { ["0"] = 1, ["1"] = 2, ["2"] = 3, ["3"] = 4, ["4"] = 5, ["5"] = 6, ["6"] = 7, ["7"] = 8,
                      ["8"] = 9, ["9"] = 10, a = 11, b = 12, c = 13, d = 14, e = 15, f = 16, g = 17, h = 18,
                      i = 19, j = 20, k = 21, l = 22, m = 23, n = 24, o = 25, p = 26, q = 27, r = 28, s = 29,
                      t = 30, u = 31, v = 32, w = 33, x = 35, y = 36, z = 37 }

---Take a number, and return a string value representing that number convereted from it's base. Will do the opposite of tonumber.
---Converts to non decimal values by flooring. Specifically modified for swizzle building so don't use it wholesale in other
---things.
---@param number number the number you want to convert.
---@param base number the original base you're converting from.
---@return string #the string result of the new number you made.
local function fromBase(number, base)
    number = floor(number)
    if not base or base == 10 then return tostring(number) end
    local digits, t, sign = "0123456789abcdefghijklmnopqrstuvwxyz", {}, ""
    if number < 0 then
        sign = "-"
        number = -number
    end
    repeat
        local d = (number % base) + 1
        number = floor(number / base)
        insert(t, 1, digits:sub(d, d))
    until number == 0
    return sign .. table.concat(t, "")
end

---Build out the swizzle matrix, an x by y sized matrix of swizzle masks. Each swizzle mask is
---will be y big, and go up to x. So, for example, a 2x3 swizzle matrix would look like
---```
---matrix = {{1, 1, 1}, {1, 1, 2}, {1, 2, 1}, {1, 2, 2},
---          {2, 1, 1}, {2, 1, 2}, {2, 2, 1}, {2, 2, 2}}
---```
---@param x number How many "characters" you want in your matrix. This is the numeric index of the masks. Max of 36.
---@param y number the "length" of the matrix. How long you want each mask to be. Must be greater than 0.
local function buildSwizzleMatrix(x, y)
    local result = {}

    for i = 1, x ^ y, 1 do
        local str, j = fromBase(i - 1, x), 1
        str = ("0"):rep(y - #str) .. str
        result[i] = {}

        for chr in str:gmatch(".") do
            result[i][j] = swizzle_lut[chr]
            j = j + 1
        end
    end

    return result
end

---Build out the swizzle lookup table according to the passed matrix and key_set. That will include every swizzle pattern once,
---from single character patterns up to larger patterns.
---@param matrix table specifically formatted matrix, built from the buildSwizzleMatrix function.
---@param key_set table<number,table<number,string>> 2d table, with characters. ex: {{"r", "g", "b", "a"}}
---@return table #the master swizzle lookup. Used for building out the various swizzle getters.
local function buildSwizzleLookup(matrix, key_set)
    local result = {}
    for _, mask in ipairs(matrix) do
        for _, set in ipairs(key_set) do
            local prev_str, prev_tbl  = "", {}
            for _, val in ipairs(mask) do
                local key = prev_str .. set[val]

                --add new value
                result[key] = {}
                for j, v in ipairs(prev_tbl) do result[key][j] = v end
                result[key][#prev_tbl + 1] = val

                --save new values as old values
                prev_str = key
                for j, v in ipairs(result[key]) do prev_tbl[j] = v end
            end
        end
    end

    return result
end

--documentation is dynamically generated and placed in this table. Right before exporting the Swizzle mixin, the documentation
--is printed to the console. If that's not something you want, simply comment out the print loop. The types unfortuntately, can
--not be generated, so anywhere that the documentation type is needed, is instead the pattern <SwizzleType>, and anywhere you need
--the type, but like, casual (ie, lowercase) is the pattern <Swizzletype>. Lastly, the documentation class table, <SwizzleClass>.
--Find and replace.
local documentation = {}

--To change the swizzle setup, adjust the matrix and the keys.
--key_pattern must be formatted as {<table of letters you want for swizzle>, <table of different letters you want for swizzle>}
--swizzle matrix first arg should match the amount of characters in key_pattern. so if key_pattern has 4 letters, first arg of
--buildSwizzleMatrix should be a 4. The second arg is up to you, however long you want to be able to swizzle. Be aware that
--the formula for how many patterns is ((x ^ y) + (x ^ y - 1) + (x ^ y - 2) + ... + (x ^ 1)) * #key_patterns
for key, value in pairs(buildSwizzleLookup(buildSwizzleMatrix(4, 4), {{"r", "g", "b", "a"}, {"x", "y", "z", "w"}})) do
    Swizzle.__get[key] = function(self)
        local p, tbl, err = private[self], {}, "Failed to get '" .. key .. "' from " .. self.__type .. "; "
        
        assert(p.size, err .. "missing private size field.")
        assert(p.values, err .. "missing private values field.")
        assert(p.size >= #key, err .. "size is to small for swizzle pattern. - '" .. tostring(p.size) .. " < " .. tostring(#key))
        
        local values = {unpack(p.values)}
        for i, j in ipairs(value) do tbl[i] = values[j] end
        
        return #tbl == 1 and tbl[1] or getmetatable(self)(tbl)
    end

    Swizzle.__set[key] = function(self, val)
        local tv, p, err
        
        p = private[self]
        err = "Failed to set '" .. key .. "' for " .. self.__type .. "; "
        tv  = type(val)

        assert(p.size, err .. "missing private size field.")
        assert(p.values, err .. "missing private values field.")
        assert(p.size >= #key, err .. "size is to small for swizzle pattern. - '" .. tostring(p.size) .. " < " .. tostring(#key))
        assert(tv == "number" or tv == "table", err .. "'value' was not of type 'table' or 'number' - '" .. type(val) .. "'.")

        val = tv == "number" and { val } or val

        for i, j in ipairs(value) do p.values[j] = val[i] end
    end
    
    if #key == 1 then
        documentation[#documentation + 1] = { [[
---Getter for swizzle pattern ]] .. key .. [[. Should not be called directly.
---@return number #A number based on the swizzle pattern.
function <SwizzleClass>.__get:]] .. key .. [[() end
]],
"---@field " .. key .. " Returns a single number based on the swizzle pattern, or, allows you to set a value into that spot of the <Swizzletype>." }
    else
        documentation[#documentation + 1] = { [[
---Getter for swizzle pattern ]] .. key .. [[. Should not be called directly.
---@return <SwizzleType> #A <Swizzletype> of the swizzle pattern.
function <SwizzleClass>.__get:]] .. key .. [[() end
]],
"---@field " .. key .. " <SwizzleType> Returns a <Swizzletype> based on the swizzle pattern, or, allows you to set values into those spots of the <Swizzletype>. Takes a <Swizzletype>." }
    end
end

Swizzle.__type = "swizzle"

--Comment this out if you don't want to print out swizzle documentation.
--for _, v in ipairs(documentation) do print(v[1]) end
--for _, v in ipairs(documentation) do print(v[2]) end

return Swizzle