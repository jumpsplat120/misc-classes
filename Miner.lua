local Miner, private, Symbol
local Inventory, Turtle
local TypeError, InvalidError
local is

private = require("lib.Classy.instances")
Symbol  = require("lib.Classy.Symbol")

Inventory = require("classes.Inventory")
Turtle    = require("classes.Turtle")

InvalidError = require("classes.errors.InvalidError")
TypeError    = require("classes.errors.TypeError")

is = require("lib.is")
TL = require("lib.string_template")

Miner = Turtle:extend()

    --======PRIVATE FUNCTIONS======--

local _, directions, valid_directions_str
local FORWARD, BACKWARD, LEFT, RIGHT, UP, DOWN
local optionallyFuel

_ = Turtle()

--We gotta expose the Symbols from Turtle, since that's what's accessible
--on a miner, and therefore that's what we wanna check when doing error correction.
BACKWARD = _.BACKWARD
FORWARD  = _.FORWARD
RIGHT    = _.RIGHT
LEFT     = _.LEFT
DOWN     = _.DOWN
UP       = _.UP

directions = {
    [BACKWARD] = true,
    [FORWARD]  = true,
    [RIGHT]    = true,
    [LEFT]     = true,
    [DOWN]     = true,
    [UP]       = true
}

valid_directions_str = table.join(table.keys(directions), "/")

function optionallyFuel(self, cost, inventory, options)
    if self.fuel.amount < cost and options.refuel_from_inv then
        self:refuel()
    end

    --If we still don't have enough, we check the chest.
    if self.fuel.amount < cost and options.refuel_from_chest then
        self:fuelFromInventory(inventory, cost)
    end

    --If we still don't have enough, return.
    if self.fuel.amount < cost and not options.start_with_deficit then
        self:dispatchSync("error", "tunnel", "Not enough fuel. Shutting down.", options)

        return false
    end

    return true
end

    --======CONSTRUCTOR======--

function Miner:new()
    Turtle.new(self)
end

--Scans a provided inventory for any item that can be burned as fuel in a turtle.
--Returns a table of the items that can be burned.
function Miner:scanForBurnables(inventory)
    local p, success, amount, result, unique

    TypeError:assert(is(inventory, Inventory), "inventory", type(inventory), Inventory)

    p = private[self]

    result = {}
    unique = {}

    if self:find("minecraft:air") == 0 then
        self:dispatchSync("error", "scanForBurnables", "Miner has no empty slots to scan with.")

        return result
    end

    --Get each unique item in the chest, rather then every single item. This way
    --we don't spend time checking the same thing multiple times.
    for _, item in ipairs(inventory:slots()) do
        if item.name ~= "minecraft:air" then
            unique[#unique + 1] = item
        end
    end

    for _, item in ipairs(unique) do
        amount = self:take(item, inventory, 1)

        if amount ~= 1 then
            self:dispatchSync("error", "scanForBurnables", "Failed to take item from inventory.", item, inventory)

            return result
        end

        self:select(self:find(item))

        success, data = p.turtle.refuel(0)

        if success then
            result[#result + 1] = item 
        end

        self:push(item, inventory, 1)
    end

    return result
end

--Mines out a pillar (a 1 by 3). Accounts for falling blocks by moving into the space.
--Resets position if reset is true.
function Miner:pillar(reset)
    repeat self:mine(FORWARD)
    until  self:move(FORWARD)

    self:mine(UP, DOWN)

    if reset then self:move(BACKWARD) end

    return self
end

--Mines out a slab (3 by 3). Uses pillar, and therefore accounts for falling blocks.
--If reset is provided, resets to the side of the slab that the miner started on.
--Moves from left to right, unless reverse is true. Starting position is assumed to be
--either middle left or middle right of the slab, facing the direction you want to mine.
function Miner:slab(reset, reverse)
    self
        :pillar()
        :turn(reverse and LEFT or RIGHT)
        :pillar()
        :pillar()
    
    if reset then
        self:move(BACKWARD, 2)
        self:turn(reverse and RIGHT or LEFT)
        self:move(BACKWARD)
    end

    self:turn(reverse and RIGHT or LEFT)

    return self
end

--Mines a 3 by 3 tunnel length blocks long. There is no error checking on the options themselves. Options are as follows:
-- * length - how long the tunnel should be. Default 10 blocks.
-- * lit - Whether to light the tunnel. Places a torch every 7 blocks. Defaults to true, and will halt if there are not enough torches.
-- * side_paths - whether to mine out side tunnels. By default, false, and takes a subtable for options.
--   * length - The length of the side paths. By default, 8 blocks.
--   * lit - Whether there is a torch at the end of the side paths. By default, true.
--   * blocked - Whether to block off the side_paths after mining them. By default, false.
-- * refuel_from_chest - If the turtle should return to the chest to refuel, if there's not enough to finish a run. Default true.
-- * refuel_from_inv - If the turtle should use it's mined resources to refuel. Default true.
-- * grab_torches - If there's not enough torches, grab them from the chest. Default true, but only applicable if lit is true.
-- * filter - Expects a 2Dtable. Each inner table should be an item, and the max amount allowed in the turtle's inventory. Items that are mined that go over that amount are dropped on the floor (such as excess cobblestone.) Anything not in the filter is always kept.
-- * deposit - Whether the turtle should deposit when full. If this is false, it will return to it's starting position, and end the mining run. Default true. NOTE: Will end the mining run if there is no space in the chest to deposit.
-- * start_with_deficit - Will start the mining process even if there's not enough fuel for the estimated entire trip. Defaults false.
--If grab_torches, refuel_from_chest, or deposit are marked true, then an inventory *must* be passed. Otherwise, it is optional.
function Miner:tunnel(options, inventory)
    local amount, torches, distance, reverse, cost

    TypeError:assert(is(options, "table") or is(options, "nil"), "options", type(options), "table/nil")
    TypeError:assert(is(inventory, Inventory) or is(inventory, "nil"), "inventory", type(inventory), tostring(Inventory) .. "/nil")

    options = options or {}

    options.length = options.length or 10
    
    options.refuel_from_chest = options.refuel_from_chest or true
    options.refuel_from_inv   = options.refuel_from_inv   or true
    options.grab_torches      = options.grab_torches      or true
    options.deposit           = options.deposit           or true
    options.lit               = options.lit               or true

    --Each moved square is one fuel. Each slab takes 3 fuel, and the return trip takes one fuel
    --per slab, for a total of four fuel per slab.
    if not optionallyFuel(self, options.length * 4, inventory, options) then
        return self
    end

    amount  = self:amount("minecraft:torch")
    torches = math.floor(options.length / 7)

    --Since a tunnel is placed every 4 blocks, we add that cost to the torch amount
    --*if* we are doing side tunnels and they are supposed to be lit.
    if options.side_paths and options.side_paths.lit then
        torches = torches + math.floor(options.length / 4)
    end

    --Calculate whether we have enough torches, and grab as needed.
    if amount < torches and options.grab_torches then
        self:pull("minecraft:torch", inventory, torches - amount)
    end

    --Recalculate, and if we don't have enough, return.
    if self:amount("minecraft:torch") < torches then
        self:dispatchSync("error", "tunnel", "Not enough torches. Shutting down.", options)

        return self
    end

    --Time to start!--

    distance = self:move(FORWARD, options.length)

    --We just travelled out the full distance, and there was apparently nothing to mine. Return.
    if distance == options.length then
        self:move(BACKWARD, options.length)

        return self
    end

    --The "main" loop
    for i = distance, options.length, 1 do
        self:slab(false, reverse)

        reverse = not reverse

        --Place torch every seven blocks.
        if i % 7 == 0 and options.lit then
            self:turn(reverse and LEFT or RIGHT)

            self:place(UP, "minecraft:torch")

            self:turn(reverse and RIGHT or LEFT)
        end

        --If we're full or close to it, we need to return, and deposit our stuff.
        if self.inventory_fullness >= 0.9 and options.deposit then
            torches = self:amount("minecraft:torch")

            if not self:returnToBase(reverse, i) then
                self:dispatchSync("error", "tunnel", "Failed to return to base during deposit run. Shutting down.")

                return self
            end

            --GOTCHA: This value can be modified, since it's just attached to the class!
            if inventory.state == Inventory.FULL then
                self:dispatchSync("error", "tunnel", "Unable to deposit resources as inventory is full. Shutting down.")

                return self
            end

            --Before we empty our inventory, we need to recalculate our fuel costs, and refuel from
            --the inventory (if true). The first part is the slab cost, and the second part is the
            --cost to travel back out, and then back again for the final return.
            if not optionallyFuel(self, (i - options.length) * 3 + i + options.length, inventory, options) then
                return self
            end

            if not self:emptyInto(inventory) then
                self:dispatchSync("error", "tunnel", "Unable to deposit all resources. Shutting down.")

                return self
            end

            --Since we dropped off the torches, we wanna pull those back out.
            if self:pull("minecraft:torch", inventory, torches) ~= torches then
                self:dispatchSync("error", "tunnel", "Failed to retrieve torches from chest during deposit process. Shutting down.")

                return self
            end

            --Finally, return to where we were. Should be a free path, so we just go
            --for it.
            self:move(FORWARD, i)

            --We actually don't need to go back to our original side. Instead, we can
            --just say we're on the left now. It'll make the torches look odd sometimes,
            --but this saves two units of fuel and a smidge of time.
            reverse = false
        end

        --TODO: This is where side paths will be. We should add this
        --to the fuel calculations as well. This comes after depositing
        --since we'll do a slab, then check, then tunnel one and two and
        --reset. We could *technically* lose some blocks like that if the
        --tunnels are very long, but it's unlikely. Maybe check more often?
        --idk.
        if i % 4 == 0 and options.side_paths then
        end
    end
end

--Takes an inventory, and pulls out all items that can be used as fuel. Attempts to burn them
--until the fuel amount is reached. Returns true if successfully reached fuel amount.
function Miner:fuelFromInventory(inventory, fuel)
    local burnables, returns

    TypeError:assert(is(inventory, Inventory), "inventory", type(inventory), Inventory)
    TypeError:assert(is(fuel, "number"), "fuel", type(fuel), "number")

    burnables = self:scanForBurnables(inventory)

    --TODO: Is returning needed? If the robit is full on fuel, will it burn
    --erroneously, or will it save it?
    for _, burnable in ipairs(burnables) do
        self:pull(burnable, inventory)
        self:refuel()

        if self.fuel.amount >= fuel then
            returns = burnable

            break
        end
    end

    if returns then self:push(returns, inventory) end

    return self.fuel.amount >= fuel
end

function Miner:returnToBase(side, distance)
    TypeError:assert(is(distance, "number"), "distance", type(distance), "number")

    if side then
        self:turn(RIGHT)

        if self:move(BACKWARD, 2) ~= 2 then
            self:dispatch("error", "returnToBase", "Failed to return to base.")

            return false
        end

        self:turn(LEFT)
    end

    if self:move(BACKWARD, distance) ~= distance then
        self:dispatch("error", "returnToBase", "Failed to return to base.")

        return false
    end

    return true
end

    --======METHODS======--
    
    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function Miner:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper() end

    return self:tostringHelper("Class")
end

Miner.__type = "miner"

return Miner