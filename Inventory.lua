---@type Object
local Object
local Inventory, private, Symbol
local TypeError, MissingError, InvalidError, ParseError, RangeError
local is

Object  = require("lib.Classy")
private = require("lib.Classy.instances")
Symbol  = require("lib.Classy.Symbol")

InvalidError = require("classes.errors.InvalidError")
MissingError = require("classes.errors.MissingError")
ParseError   = require("classes.errors.ParseError")
RangeError   = require("classes.errors.RangeError")
TypeError    = require("classes.errors.TypeError")

is = require("lib.is")

Inventory = Object:extend()

    --======PRIVATE FUNCTIONS======--

local FULL, EMPTY, PARTIAL
local peripherals, states, valid_states_str

peripherals = peripheral

PARTIAL = Symbol("partial")
EMPTY   = Symbol("empty")
FULL    = Symbol("full")

states = {
    [PARTIAL] = true,
    [EMPTY]   = true,
    [FULL]    = true
}

valid_states_str = table.join(table.keys(states), "/")

Inventory.PARTIAL = PARTIAL
Inventory.EMPTY   = EMPTY
Inventory.FULL    = FULL

    --======CONSTRUCTOR======--

function Inventory:new(inventory)
    local p, types

    assert(peripherals, "Can not create an Inventory instance when the peripheral API isn't available.")

    TypeError:assert(is(inventory, "string"), "inventory", type(inventory), "string")

    types = peripherals.getType(inventory)

    --Allows a user to pass in "minecraft:hopper" or "inventory" if they don't care where it is.
    if not types then
        types = peripherals.getType(peripherals.find(inventory))
    end

    ParseError:assert(is(types, "table"), "inventory", "inventory")
    TypeError:assert(table.find(types, "inventory"), "inventory", table.join(types, "/"), "inventory")

    p = private[self]

    p.inventory = inventory
    p.size      = inventory.size()
end

    --======METHODS======--

function Inventory:slots(slot)
    local p, item, result

    TypeError:assert(is(slot, "number") or is(slot, "nil"), "slot", type(slot), "number/nil")

    p = private[self]

    result = {}

    for i = slot or 1, slot or p.inventory.size(), 1 do
        item = p.inventory.getItemDetail(i)

        if not item then
            result[i] = {
                name      = "minecraft:air",
                count     = 0,
                maximum   = 64,
                remaining = 64
            }
        else
            result[i] = item

            result[i].remaining = item.maxCount - item.count
        end
    end

    return result
end

--Returns the amount of an item an inventory has in itself.
function Inventory:amount(item)
    local result = 0

    TypeError:assert(is(item, "string"), "item", type(item), "string")

    for _, item in ipairs(self:slots()) do
        if item.name == item then
            result = result + item.count
        end
    end

    return result
end

function Inventory:waitUntil(state, ms)
    local p, has_empty, has_full, has_partial
    
    p = private[self]

    TypeError:assert(is(state, Symbol), "state", type(state), Symbol)
    TypeError:assert(is(ms, "number") or is(ms, "nil"), "ms", type(ms), "number/nil")
    InvalidError:assert(states[state], state, "state", valid_states_str)

    ms = ms and math.max(ms, 1) or 10

    while true do
        for _, item in ipairs(self:slots()) do
            if item.name == "minecraft:air" then
                has_empty = true
            elseif item.remaining == 0 then
                has_full = true
            else
                has_partial = true

                break
            end
        end

        if has_full  and not has_empty and not has_partial and state == FULL  then return end
        if has_empty and not has_full  and not has_partial and state == EMPTY then return end

        has_items   = false
        has_empty   = false
        has_partial = false

        sleep(ms)
    end
end

--Returns true if an itemstack can fit into an inventory. A very simple check;
--does not account for nbt data or the like. Simply compares item names and remaining space
function Inventory:canFit(item)
    TypeError:assert(is(item, "table"), "item", type(item), "item")
    MissingError:assert(is(item.name, "string"), "name", "item")
    MissingError:assert(is(item.count, "number"), "count", "item")

    for _, slot in ipairs(self:slots()) do
        if slot.name == "minecraft:air" then return true end
        if slot.name == item.name and slot.remaining >= item.count then return true end
    end

    return false
end

function Inventory:find(item)
    TypeError:assert(is(item, "string"), "item", type(item), "string")

    for i, item in ipairs(self:slots()) do
        if item.name == item then return i end
    end

    return 0
end

function Inventory:push(inventory, from_slot, limit, to_slot)
    local p = private[self]

    TypeError:assert(is(inventory, Inventory), "inventory", type(inventory), Inventory)
    TypeError:assert(is(from_slot, "number"), "from_slot", type(from_slot), "number")
    TypeError:assert(is(limit, "number") or is(limit, "nil"), "limit", type(limit), "number/nil")
    TypeError:assert(is(to_slot, "number") or is(to_slot, "nil"), "to_slot", type(to_slot), "number/nil")
    RangeError:assert(from_slot:between(1, p.size), from_slot, "from_slot", 1, p.size)
    
    if to_slot then
        RangeError:assert(to_slot:between(1, inventory.size), to_slot, "to_slot", 1, inventory.size)
    end

    return p.inventory.pushItems(inventory.name, from_slot, limit, to_slot)
end

function Inventory:pull(inventory, from_slot, limit, to_slot)
    local p = private[self]

    TypeError:assert(is(inventory, Inventory), "inventory", type(inventory), Inventory)
    TypeError:assert(is(from_slot, "number"), "from_slot", type(from_slot), "number")
    TypeError:assert(is(limit, "number") or is(limit, "nil"), "limit", type(limit), "number/nil")
    TypeError:assert(is(to_slot, "number") or is(to_slot, "nil"), "to_slot", type(to_slot), "number/nil")
    RangeError:assert(from_slot:between(1, p.size), from_slot, "from_slot", 1, p.size)
    
    if to_slot then
        RangeError:assert(to_slot:between(1, inventory.size), to_slot, "to_slot", 1, inventory.size)
    end

    return p.inventory.pullItems(inventory.name, from_slot, limit, to_slot)
end

    --======GETTERS======--

function Inventory.__get:PARTIAL()
    return PARTIAL
end

function Inventory.__get:EMPTY()
    return EMPTY
end

function Inventory.__get:FULL()
    return FULL
end

function Inventory.__get:state()
    local has_empty, has_full, has_partial

    for _, item in ipairs(self:slots()) do
        if item.name == "minecraft:air" then
            has_empty = true
        elseif item.remaining == 0 then
            has_full = true
        else
            has_partial = true

            break
        end
    end

    if has_partial then return PARTIAL end

    if has_full and not has_empty then return FULL end

    return EMPTY
end

--TODO: Does this value change? Maybe we can just cache it once,
--rather than calling it every time.
function Inventory.__get:name()
    return peripherals.getName(private[self].inventory)
end

function Inventory.__get:size()
    return private[self].size
end

    --======SETTERS======--
    
    --======METAMETHODS======--

function Inventory:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

Inventory.__type = "Inventory"

return Inventory