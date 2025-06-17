---@type Object
local Object
local Team, private
local Vector

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Vector = require("classes.Vector")

Team = Object:extend()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Team:new(name, color)
    local p = private[self]

    p.name = name

    p.friendlies = {}
    p.enemies    = {}

    p.color = color

    --This assumes that forward is z positive, that right is x positive, and up is y positive.
    --To flip the direction (usually just to "the other side" of the board) you can just
    --multiply this by negative one. If, for some reason, you want a forward that isn't up
    --or down, you can modify this vector, but moves are created with the up/down paradigm in
    --mind. They *might* work otherwise, but I wouldn't count on it.
    p.direction = Vector:fromValues(1, 1, 1)
end

    --======METHODS======--

--TODO: Error checking
function Team:addFriendly(team)
    local p = private[self]

    --TODO: Make error for this
    if p.enemies[team] then error("Team is already an enemy team.") end

    p.friendlies[team] = true

    return self
end

--TODO: Error checking
function Team:addEnemy(team)
    local p = private[self]

    if p.friendlies[team] then error("Team is already a friendly team.") end

    p.enemies[team] = true

    return self
end

--TODO: Error checking
function Team:removeFriendly(team)
    private[self].friendlies[team] = nil

    return self
end

--TODO: Error checking
function Team:removeEnemy(team)
    private[self].enemy[team] = nil

    return self
end

--TODO: Error checking
function Team:isFriendly(team)
    local p = private[self]

    if p.true_good then return true end

    return not not p.friendlies[team]
end

--TODO: Error checking
function Team:isEnemy(team)
    local p = private[self]

    if p.true_evil then return true end
    
    return not not p.enemies[team]
end

--TODO: Error checking
function Team:isNeutral(team)
    local p = private[self]

    if p.friendlies[team] ~= nil  then return false end
    if p.enemies[team]    ~= nil  then return false end
    if p.true_good or p.true_evil then return false end

    return true
end

function Team:clone()
    local p, clone

    p = private[self]
    clone = Team(p.name, p.color:clone())

    for i, friend in ipairs(p.friendlies) do
        private[clone].friendlies[i] = friend
    end

    for i, enemy in ipairs(p.enemies) do
        private[clone].enemies[i] = enemy
    end
        
    return clone
end
    
    --======GETTERS======--

function Team.__get:true_evil()
    return private[self].true_evil
end

function Team.__get:true_good()
    return private[self].true_good
end

function Team.__get:color()
    return private[self].color
end

function Team.__get:forward()
    return private[self].direction
end

    --======SETTERS======--
    
function Team.__set:true_evil(value)
    local p = private[self]

    --TODO: make this a real error
    if p.true_good then error("Can't be true evil and true good at the same time.") end

    p.true_evil = value
end

function Team.__set:true_good(value)
    local p = private[self]

    if p.true_evil then error("Can't be true evil and true good at the same time.") end

    p.true_good = value
end

--TODO: Add error checking
function Team.__set:color(value)
    private[self].color = value
end

    --======METAMETHODS======--

function Team:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.name) end

    return self:tostringHelper("Class")
end

Team.__type = "team"

return Team