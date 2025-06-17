---@type Object
local Object
local Turtle, private, Symbol
local Inventory
local Emitter
local TypeError, InvalidError, RangeError
local is

Object  = require("lib.Classy")
private = require("lib.Classy.instances")
Symbol  = require("lib.Classy.Symbol")

Inventory = require("classes.Inventory")

Emitter = require("classes.mixins.Emitter")

InvalidError = require("classes.errrors.InvalidError")
RangeError   = require("classes.errrors.RangeError")
TypeError    = require("classes.errrors.TypeError")

is = require("lib.is")

Turtle = Object:extend()

Turtle:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local singleton, directions, opposites, valid_directions_str, left_right_str
local FORWARD, BACKWARD, LEFT, RIGHT, UP, DOWN
local position

BACKWARD = Symbol("backward")
FORWARD  = Symbol("forward")
RIGHT    = Symbol("right")
LEFT     = Symbol("left")
DOWN     = Symbol("down")
UP       = Symbol("up")

directions = {
    [BACKWARD] = true,
    [FORWARD]  = true,
    [RIGHT]    = true,
    [LEFT]     = true,
    [DOWN]     = true,
    [UP]       = true
}

opposites = {
    [BACKWARD] = FORWARD,
    [FORWARD]  = BACKWARD,
    [RIGHT]    = LEFT,
    [LEFT]     = RIGHT,
    [DOWN]     = UP,
    [UP]       = DOWN
}

valid_directions_str = table.join(table.keys(directions), "/")
left_right_str = table.join({ LEFT, RIGHT }, "/")

--Return the position of an inventory relative to the turtle.
function position(p, inventory)
    local name, up, forward, down

    name = inventory.name

    up      = p.peripheral.wrap("top")
    down    = p.peripheral.wrap("bottom")
    forward = p.peripheral.wrap("front")

    if up and name == p.peripheral.getName(up) then
        return "up"
    end

    if down and name == p.peripheral.getName(down) then
        return "down"
    end

    if forward and name == p.peripheral.getName(forward) then
        return ""
    end
end

    --======CONSTRUCTOR======--

function Turtle:new()
    local p = private[self]

    if singleton then return singleton end

    singleton = self

    assert(turtle, "Can not create the turtle singleton when the turtle API isn't available.")
    assert(peripheral, "Can not create the turtle singleton when the peripheral API isn't available.")

    p.offset = {
        x = 0,
        y = 0,
        z = 0
    }

    p.steps = {}

    p.facing     = FORWARD
    p.turtle     = turtle
    p.peripheral = peripheral
end

    --======METHODS======--

--Tries to retraces it's steps.
function Turtle:retrace()
    local p, axis, offset, success
    
    p = private[self]

    for _, step in ipairs(table.reverse(p.steps)) do
        axis   = step[1]
        offset = step[2]

        if axis == "z" then
            self:face(offset == 1 and RIGHT or LEFT)

            success = self:move(offset == 1 and BACKWARD or FORWARD)
        end

        if axis == "x" then
            self:face(offset == 1 and FORWARD or BACKWARD)

            success = self:move(offset == 1 and BACKWARD or FORWARD)
        end

        if axis == "y" then
            success = self:move(offset == 1 and DOWN or UP)
        end

        if not success then
            break
        end
    end

    p.steps = {}

    return success
end

--Returns the distance travelled. Dispatches an error if not successful.
function Turtle:move(direction, length)
    local success, data, p, func, axis, offset, distance

    TypeError:assert(is(direction, Symbol), "direction", type(direction), Symbol)
    TypeError:assert(is(length, "number") or is(length, "nil"), "length", type(length), "number/nil")
    InvalidError:assert(directions[direction], direction, "direction", valid_directions_str)

    p = private[self]

    --We don't do an or tern, since a length of zero would be changed to a length of 1.
    if not is(length, "number") then
        length = 1
    end

    if length == 0 then
        return true
    end

    if length < 0 then
        length = length * -1

        direction = opposites[direction]
    end

    if direction == LEFT then
       self:turn(LEFT)

        func   = p.turtle.forward
        axis   = "z"
        offset = -1
    end

    if direction == RIGHT then
        self:turn(RIGHT)

        func   = p.turtle.forward
        axis   = "z"
        offset = 1
    end

    if direction == FORWARD then
        func   = p.turtle.forward
        axis   = "x"
        offset = 1
    end

    if direction == BACKWARD then
        func   = p.turtle.back
        axis   = "x"
        offset = -1
    end

    if direction == UP then
        func   = p.turtle.up
        axis   = "y"
        offset = 1
    end

    if direction == DOWN then
        func   = p.turtle.down
        axis   = "x"
        offset = -1
    end

    for i = 1, length, 1 do
        success, data = func()

        if not success then
            self:dispatchSync("error", "move", data)

            break
        end

        distance = i

        p.offset[axis] = p.offset[axis] + offset
        
        p.steps[#p.steps + 1] = { axis, offset } 
    end

    return distance
end

function Turtle:face(direction)
    local p, order, current, desired, delta

    TypeError:assert(is(direction, Symbol), "direction", type(direction), Symbol)
    InvalidError:assert(directions[direction], direction, "direction", valid_directions_str)

    p = private[self]

    if p.facing == direction then
        return true
    end

    if direction == UP or direction == DOWN then
        return true
    end

    order = {
        FORWARD,
        LEFT,
        BACKWARD,
        RIGHT
    }

    current = table.find(order, p.facing)  - 1
    desired = table.find(order, direction) - 1
    delta   = desired - current

    if delta == 1 or delta == -3 then
        p.turtle.turnLeft()
    end

    if delta == 2 or delta == -2 then
        p.turtle.turnLeft()
        p.turtle.turnLeft()
    end

    if delta == 3 or delta == -1 then
        p.turtle.turnRight()
    end

    if delta == -1 then
        p.turtle.turnRight()
    end

    return true
end

--Place in all six directions. Dispatches an error if fails to place block, and
--returns false, otherwise returns true.
function Turtle:place(direction, item, message)
    local p, slot, success, data

    TypeError:assert(is(item, "string"), "item", type(item), "string")
    TypeError:assert(is(message, "string") or is(message, "nil"), "message", type(message), "string/nil")
    TypeError:assert(is(direction, Symbol), "direction", type(direction), Symbol)
    InvalidError:assert(directions[direction], direction, "direction", valid_directions_str)

    p    = private[self]
    slot = self:find(item)

    if slot == 0 then
        self:dispatchSync("error", "place", "No item found.", item)

        return false
    end

    self:select(slot)

    if direction == FORWARD then
        success, data = p.turtle.place(message)
    end

    if direction == UP then
        success, data = p.turtle.placeUp(message)
    end

    if direction == DOWN then
        success, data = p.turtle.placeDown(message)
    end

    if direction == LEFT then
        self:turn(LEFT)

        success, data = p.turtle.place(message)

        self:turn(RIGHT)
    end

    if direction == RIGHT then
        self:turn(RIGHT)

        success, data = p.turtle.place(message)

        self:turn(LEFT)
    end

    if direction == BACKWARD then
        self:turn(LEFT):turn(LEFT)

        success, data = p.turtle.place(message)

        self:turn(LEFT):turn(LEFT)
    end

    if not success then
        self:dispatchSync("error", "place", data, item)
    end

    return success
end

function Turtle:turn(direction)
    local p, order

    TypeError:assert(is(direction, Symbol), "direction", type(direction), Symbol)
    InvalidError:assert(direction == LEFT or direction == RIGHT, direction, "direction", left_right_str)

    p = private[self]

    order = {
        FORWARD,
        LEFT,
        BACKWARD,
        RIGHT
    }

    p.facing = order[table.find(order, p.facing) + (direction == LEFT and 1 or -1)]

    p.turtle[TL("turn%{direction}", { direction = tostring(direction):title() })]()

    return self
end

function Turtle:inspect(direction)
    local success, data, p
    
    TypeError:assert(is(direction, Symbol), "direction", type(direction), Symbol)
    InvalidError:assert(directions[direction], direction, "direction", valid_directions_str)

    p = private[self]

    if direction == LEFT then
        self:turn(LEFT)

        success, data = p.turtle.inspect()

        self:turn(RIGHT)
    end

    if direction == RIGHT then
        self:turn(RIGHT)

        success, data = p.turtle.inspect()

        self:turn(LEFT)
    end

    if direction == BACKWARD then
        self:turn(BACKWARD)

        success, data = p.turtle.inspect()

        self:turn(BACKWARD)
    end

    if direction == UP then
        success, data = p.turtle.inspectUp()
    end

    if direction == DOWN then
        success, data = p.turtle.inspectDown()
    end

    if success then return data end

    return {
        name = "minecraft:air"
    }
end

function Turtle:slots(slot)
    local item, result
    
    TypeError:assert(is(slot, "number") or is(slot, "nil"), "slot", type(slot), "number/nil")

    result = {}

    for i = slot or 1, slot or 12, 1 do
        item = turtle.getItemDetail(i, true)

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

function Turtle:select(slot)
    TypeError:assert(is(slot, "number"), "slot", type(slot), "number")
    RangeError:assert(slot:between(1, 12), slot, "slot", 1, 12)

    private[self].turtle.select(slot)

    return self
end

function Turtle:blockExists(direction, block)
    TypeError:assert(is(direction, Symbol), "direction", type(direction), Symbol)
    TypeError:assert(is(block, "string"), "block", type(block), "string")
    InvalidError:assert(directions[direction], direction, "direction", valid_directions_str)

    return self:inspect(direction).name == block
end

--Attempts to refuel using every item in the turtle's inventory. If a slot is provided,
--then only refuels using that slot. Returns a float representing the percentage of
--the turtle's current fuel (0.25 is a quarter full, for example.)
function Turtle:refuel(slot)
    local success, _, item, fuel

    TypeError:assert(is(slot, "number") or is(slot, "nil"), "slot", type(slot), "number/nil")
    
    fuel = self.fuel

    if fuel.limit == fuel.amount then
        return 1
    end

    for i = slot or 1, slot or 16, 1 do
        turtle.select(i)
        
        success, _ = turtle.refuel(0)

        if success then
            item = turtle.getItemDetail()

            self:dispatchSync("item_burned", item)

            success, msg = turtle.refuel()

            fuel = self.fuel

            if fuel.amount == fuel.limit then
                break
            end
        end
    end

    return fuel.limit / fuel.amount
end

--Returns true if the turtle succesfully empties it's inventory, and false otherwise.
--Emits an error event on a failure with a message explaining why it failed.
function Turtle:emptyInto(inventory)
    local p, failed

    TypeError:assert(is(inventory, Inventory), "inventory", type(inventory), Inventory)

    p = private[self]
    
    failed = {}

    for i, item in ipairs(self:slots()) do
        if item.count > 0 then
            if inventory:canFit(item) then
                self:dispatchSync("depositing", item, inventory)

                turtle.select(i)
                turtle.drop()
            else
                failed[#failed + 1] = item
            end
        end
    end

    if #failed > 0 then
        self:dispatchSync("error", "emptyInto", "Failed to deposit items.", failed)

        return false
    end

    return true
end

--Returns the amount of an item a turtle has contained in it's inventory.
function Turtle:amount(item)
    local result = 0

    TypeError:assert(is(item, "string"), "item", type(item), "string")

    for _, item in ipairs(self:slots()) do
        if item.name == item then
            result = result + item.count
        end
    end

    return result
end

function Turtle:find(item)
    TypeError:assert(is(item, "string"), "item", type(item), "string")

    for i, item in ipairs(self:slots()) do
        if item.name == item then return i end
    end

    return 0
end

--Takes items from an inventory, up to amount, and returns the amount of items taken.
--By default, takes as much as possible.
function Turtle:pull(item, inventory, amount)
    local p, slot, turtle_slot, count, drop, location, suck, success, _

    TypeError:assert(is(item, "string"), "item", type(item), "string")
    TypeError:assert(is(amount, "number") or is(amount, "nil"), "amount", type(amount), "number/nil")
    TypeError:assert(is(inventory, Inventory), "inventory", type(inventory), Inventory)

    count    = 0
    amount   = amount or 768 --A full turtle inventory
    location = position(p, inventory)
    drop     = p.turtle["drop" .. location]
    suck     = p.turtle["suck" .. location]

    while true do
        slot = inventory:find(item)

        if slot == 0 then
            return count
        end

        --If it's not in the first slot, we need to do some juggling.
        if slot ~= 1 then
            --Step 1, figure out which slot in the turtle is empty
            turtle_slot = self:find("minecraft:air")

            if turtle_slot == 0 then
                self:dispatchSync("error", "take", "Unable to take items as turtle inventory is full.")

                return count
            end

            --Step 2, suck whatever is in the first slot of the inventory into the
            --turtle
            suck()

            --Step 3, Move the item from it's original slot in the inventory to the first slot in itself.
            inventory:push(inventory, slot, nil, 1)

            --Step 4, Drop the item we took to make room, back into the inventory. It should
            --have an empty slot, because we just made one, and that empty slot shouldn't be
            --slot one, cause we just moved something there.
            p.turtle.select(turtle_slot)
            drop()

            --Step 5, suck up the item from slot 1 into the turtle.
            success, _ = suck(math.clamp(amount - count, 1, 64))

            --GOTCHA: Nothing about this process is atomic, and it can fail at multiple points.
            --Most failures will be some case of the inventory changing during the process.
            --As long as the inventory is fully static, this should be fine, but it's worth
            --being aware of.
        else
            suck(math.clamp(amount - count, 1, 64))
        end

        count = self:amount(item)

        --If have the max requested, then we can break.
        if count == amount then return count end

        --If there's no more room in the turtle, we can break.
        if self:find("minecraft:air") == 0 then return count end

        --And finally, if we fail to drop for some reason, we break.
        if not success then return count end
    end
end

--Pushes items from the turtles inventory, up to amount, and returns the amount pushed.
--By default, pushes as much as possible.
function Turtle:push(item, inventory, amount)
    local p, slot, count, drop, before, success, _

    TypeError:assert(is(item, "string"), "item", type(item), "string")
    TypeError:assert(is(amount, "number") or is(amount, "nil"), "amount", type(amount), "number/nil")
    TypeError:assert(is(inventory, Inventory), "inventory", type(inventory), Inventory)

    p = private[self]

    count  = 0
    amount = amount or 768 --A full turtle inventory
    drop   = p.turtle["drop" ..  position(p, inventory)]

    while true do
        slot = self:find(item)

        if slot == 0 then
            return count
        end
        
        before = self:amount(item)

        p.turtle.select(slot)

        success, _ = drop(math.clamp(amount - count, 1, 64))

        count = count + (before - self:amount(item))

        --If we've pushed the full amount, we break.
        if count == amount then return count end

        --if there's no room in the inventory, we break.
        if inventory:find("minecraft:air") == 0 then return count end

        --And finally, if we fail to drop for some reason, we break.
        if not success then return count end
    end
end

--Pass in an arbitrary amount of directions, and mine them.
--Will do rotating and what not automatically.
function Turtle:mine(...)
    local p, args, name, turn

    args = { ... }

    for i, arg in ipairs(args) do
        name = TL("args[%{i}]", { i = i })

        TypeError:assert(is(arg, Symbol), name, type(arg), Symbol)
        InvalidError:assert(directions[arg], name, "direction", valid_directions_str)

        args[arg] = true
    end

    if args[FORWARD] then
        p.turtle.dig()
    end

    if args[UP] then
        p.turtle.digUp()
    end

    if args[DOWN] then
        p.turtle.digDown()
    end

    --If we need to turn 180, then we ultimately need to do a full 360,
    --otherwise, we only do a turn left, or turn right to save time.
    if args[BACKWARD] or (args[LEFT] and args[RIGHT]) then       
        turn = {
            LEFT,
            BACKWARD,
            RIGHT
        }

        for i = 1, 3, 1 do
            self:turn(LEFT)

            if args[turn[i]] then 
                p.turtle.dig()
            end
        end

        self:turn(LEFT)
    elseif args[LEFT] and not args[RIGHT] then
        self:turn(LEFT)

        p.turtle.dig()

        self:turn(RIGHT)
    elseif args[RIGHT] and not args[LEFT] then
        self:turn(RIGHT)

        p.turtle.dig()

        self:turn(LEFT)
    end

    return self
end

    --======GETTERS======--

function Turtle.__get:BACKWARD()
    return BACKWARD
end

function Turtle.__get:FORWARD()
    return FORWARD
end

function Turtle.__get:RIGHT()
    return RIGHT
end

function Turtle.__get:LEFT()
    return LEFT
end

function Turtle.__get:DOWN()
    return DOWN
end

function Turtle.__get:UP()
    return UP
end

function Turtle.__get:fuel()
    local p = private[self]

    return {
        level    = p.turtle.getFuelLevel(),
        capacity = p.turtle.getFuelLimit()
    }
end

function Turtle.__get:inventory_fullness()
    local result = 0

    for _, item in ipairs(self:slots()) do
        result = result + item.count / item.maximum
    end

    --A full inventory would be 12, which is 1 (100%) for
    --each slot. So all we have to do is divide the final
    --value by 12 to get the total percentage.
    return result / 12
end

    --======SETTERS======--
    
    --======METAMETHODS======--

function Turtle:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

Turtle.__type = "turtle"

return Turtle