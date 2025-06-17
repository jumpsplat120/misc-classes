--WILL ONLY WORK AS EXPECTED WITH 5.2 COMPAT
--The biggest issues here are __lt/__le

---@type Object
local Object
local Infinity, Symbol, private, is, TypeError

Object    = require("lib.Classy")
Symbol    = require("lib.Classy.Symbol")
private   = require("lib.Classy.instances")
is        = require("lib.is")
TypeError = require("classes.errors.TypeError")

Infinity = Object:extend()

    --======PRIVATE FUNCTIONS======--

local positive, negative
local POSINF, NEGINF, POSNUM, NEGNUM, ZERO

POSINF = Symbol("positive_infinity")
NEGINF = Symbol("negative_infinity")
POSNUM = Symbol("positive_number")
NEGNUM = Symbol("negative_number")
ZERO   = Symbol("zero")

local function compare(a, b)
    local result = {}

    TypeError:assert(is(a, Infinity) or is(a, "number"), "value", type(a), "number/" .. Infinity)
    TypeError:assert(is(b, Infinity) or is(b, "number"), "value", type(b), "number/" .. Infinity)

    if is(a, Infinity) then
        result[#result + 1] = private[a].positive and POSINF or NEGINF
    else
        if a == 0 then result[#result + 1] = ZERO   end
        if a > 0  then result[#result + 1] = POSNUM end
        if a < 0  then result[#result + 1] = NEGNUM end
    end

    if is(b, Infinity) then
        result[#result + 1] = private[b].positive and POSINF or NEGINF
    else
        if b == 0 then result[#result + 1] = ZERO   end
        if b > 0  then result[#result + 1] = POSNUM end
        if b < 0  then result[#result + 1] = NEGNUM end
    end

    return result
end

local function isnum(value)
    return value == ZERO or value == POSNUM or value == NEGNUM
end

    --======CONSTRUCTOR======--

function Infinity:new(positive)
    local p = private[self]

    p.positive = positive
end

    --======METHODS======--
    
    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function Infinity:__add(value)
    local ab = compare(self, value)

    if ab[1] == POSINF and ab[2] == POSINF then return positive end
    if ab[1] == POSINF and ab[2] == NEGINF then return 0        end
    if ab[1] == NEGINF and ab[2] == POSINF then return 0        end
    if ab[1] == NEGINF and ab[2] == NEGINF then return negative end

    if ab[1] == ZERO or ab[2] == ZERO then return self end 

    if ab[1] == POSINF and isnum(ab[2]) then return positive end
    if ab[1] == NEGINF and isnum(ab[2]) then return negative end
    if isnum(ab[1]) and ab[2] == POSINF then return positive end
    if isnum(ab[1]) and ab[2] == NEGINF then return negative end
end

function Infinity:__sub(value)
    local ab = compare(self, value)

    if ab[1] == POSINF and ab[2] == POSINF then return 0 end
    if ab[1] == NEGINF and ab[2] == NEGINF then return 0 end
    if ab[1] == POSINF and ab[2] == NEGINF then return positive end
    if ab[1] == NEGINF and ab[2] == POSINF then return negative end

    if isnum(ab[1]) and ab[2] == POSINF then return negative end
    if isnum(ab[1]) and ab[2] == NEGINF then return positive end
    if ab[1] == NEGINF and isnum(ab[2]) then return negative end
    if ab[1] == POSINF and isnum(ab[2]) then return positive end
end

function Infinity:__mul(value)
    local ab = compare(self, value)

    if ab[1] == POSINF and ab[2] == POSINF then return positive end
    if ab[1] == NEGINF and ab[2] == NEGINF then return positive end
    if ab[1] == POSINF and ab[2] == NEGINF then return negative end
    if ab[1] == NEGINF and ab[2] == POSINF then return negative end

    if ab[1] == ZERO or ab[2] == ZERO then return 0 end 

    if ab[1] == POSNUM and ab[2] == POSINF then return positive end
    if ab[1] == NEGNUM and ab[2] == POSINF then return negative end
    if ab[1] == NEGNUM and ab[2] == NEGINF then return positive end
    if ab[1] == POSNUM and ab[2] == NEGINF then return negative end

    if ab[1] == POSINF and ab[2] == POSNUM then return positive end
    if ab[1] == NEGINF and ab[2] == POSNUM then return negative end
    if ab[1] == NEGINF and ab[2] == NEGNUM then return positive end
    if ab[1] == POSINF and ab[2] == NEGNUM then return negative end
end

function Infinity:__div(value)
    local ab = compare(self, value)

    if ab[1] == POSINF and ab[2] == POSINF then return positive end
    if ab[1] == POSINF and ab[2] == NEGINF then return negative end
    if ab[1] == NEGINF and ab[2] == POSINF then return negative end
    if ab[1] == NEGINF and ab[2] == NEGINF then return positive end

    if ab[1] == POSINF and ab[2] == POSNUM then return positive end
    if ab[1] == POSINF and ab[2] == NEGNUM then return negative end

    if isnum(ab[1]) then return 0 end
end

function Infinity:__eq(value)
    local ab = compare(self, value)

    return ab[1] == ab[2]
end

function Infinity:__lt(value)
    local ab = compare(self, value)

    if ab[1] == POSINF then return false end

    if ab[1] == NEGINF and ab[2] == NEGINF then return false end

    if ab[1] == NEGINF then return true  end
    if ab[2] == NEGINF then return false end
    if ab[2] == POSINF then return true  end
end

function Infinity:__le(value)
    local ab = compare(self, value)

    if ab[1] == ab[2] then return true end

    return self < value
end

--function Infinity:__mod(value)
--    
--end

--function Infinity:__pow(value)
--
--end

function Infinity:__unm()
    return private[self].positive and negative or positive
end

function Infinity:__tostring()
    return private[self].positive and "∞" or "-∞"
end

Infinity.__type = "infinity"

positive = Infinity(true)
negative = Infinity(false)

return {
    positive = positive,
    negative = negative
}