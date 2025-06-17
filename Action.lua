---@type Object
local Object
local Action, private

Object = require("lib.Classy")
private = require("lib.Classy.instances")

Action = Object:extend()

    --======PRIVATE FUNCTIONS======--

local function noop()
    return true
end

--Generate all squares between point A and point B. Pass
--true to as_locations to get realy locations instead of
--strings
local function squares(a, b)
    local normal, modify, result
    
    normal = b:subtract(a):normalize(true)
    modify = a:clone()
    result = {}
    
    if a:distance(b) <= 1 then return result end

    while true do
        modify:add(normal, true)
        
        table.insert(result, modify:clone():round(true))
        
        --We don't include A or B, just the positions bewteen them.
        if result[#result]:matches(b) or result[#result]:matches(a) then
            table.remove(result)

            return result
        end
    end
end

--Return whether a piece is blocked if relevant. Returns the position
--blocked at.
local function blocking(p, piece, to, positions)
    local team = piece.team

    if p.blocked_by_friendlies or p.blocked_by_enemies or p.blocked_by_neutral then
        for _, position in ipairs(squares(piece.location, to)) do
            local cur_piece = positions[tostring(position)]
            
            if cur_piece then
                if p.blocked_by_friendlies and cur_piece.team:isFriendly(team) then
                    return position
                end

                if p.blocked_by_enemies and cur_piece.team:isEnemy(team) then
                    return position
                end

                if p.blocked_by_neutral and cur_piece.team:isNeutral(team) then
                    return position
                end
            end
        end
    end

    return false
end

--Checks the team if relevant
local function checkTeam(affects, piece, found)
    local is_fren, is_bad, is_meh

    if not found then return true end

    is_fren = piece.team:isFriendly(found.team)
    is_bad  = piece.team:isEnemy(found.team)
    is_meh  = piece.team:isNeutral(found.team)
    
    --Affects everthing, so we don't need to check specifics.
    if affects[1] then return true end

    --Enemies and friendlies, but not neutrals.
    if affects[2] then return is_fren or is_bad end

    --Friendlies and neutrals.
    if affects[3] then return is_fren or is_meh end

    --Enemies and neutrals.
    if affects[4] then return is_bad or is_meh end

    --Just friendlies
    if affects[5] then return is_fren end
    
    --Just enemies
    if affects[6] then return is_bad end

    --Just neutrals, no need to check affect
    if affects[7] then return is_meh end

    --There are no rules, so false
    return false
end

    --======CONSTRUCTOR======--

function Action:new(name, vector, options)
    local p = private[self]

    options = options or {}
    
    p.name = name

    p.direction = vector

    --By default, all moves respect direction. Only for some cases, generally
    --vanilla chess (castling in particular) would you not want a piece to
    --respect direction.
    p.respect_direction = options.respect_direction ~= false
    
    p.exclusive = not not options.exclusive
    p.movement  = not not options.movement
    p.attack    = not not options.attack
    p.affects_friendlies    = not not options.affects_friendlies
    p.affects_enemies       = not not options.affects_enemies
    p.affects_neutral       = not not options.affects_neutral
    p.blocked_by_friendlies = not not options.blocked_by_friendlies
    p.blocked_by_enemies    = not not options.blocked_by_enemies
    p.blocked_by_neutral    = not not options.blocked_by_neutral

    p.condition = options.condition or noop
    p.effect    = options.effect
    p.render    = options.render
end

    --======METHODS======--

--Returns every valid location of an action, based on the inital vector provided.
function Action:everyValidLocation(game, piece)
    local p, endpoint, found, blocked, team, positions
    local affects, movement, attack, valids

    p = private[self]
    
    valids = {}

    --If the piece is dead, then there are no valid locations to return.
    if not piece.alive then return valids end
    
    --If this action had a condition it needs to fufill, then check it first.
    if not p:condition(game, piece) then return valids end

    affects = {
        p.affects_friendlies and p.affects_enemies and p.affects_neutral,
        p.affects_friendlies and p.affects_enemies,
        p.affects_friendlies and p.affects_neutral,
        p.affects_enemies and p.affects_neutral,
        p.affects_friendlies,
        p.affects_enemies,
        p.affects_neutral
    }
    
    endpoint = piece.location + (p.respect_direction and p.direction * piece.forward or p.direction)
    positions = p.exclusive and {} or squares(piece.location, endpoint)
    
    --We add the endpoint as a position, since squares doesn't.
    --Otherwise, every move would exclude the endpoint as a valid
    --location.
    table.insert(positions, endpoint)

    movement = p.movement
    attack   = p.attack
    
    --Check every valid piece. Return true if any position is valid,
    --and false if none of them are.
    for _, position in ipairs(positions) do
        found = game.board[tostring(position)]

        blocked = blocking(p, piece, position, game.board)
        team    = checkTeam(affects, piece, found)
        
        if movement and attack then
            --Don't let moveattacks phase through pieces
            --An attack move needs a piece to attackmove into
            --Make sure that the piece is one we can attack
            if not blocked and found and team then
                table.insert(valids, position)
            end
        elseif attack then
            --Don't let attacks phase through pieces
            --An attack move needs a piece to attack
            --Make sure that the piece is one we can attack
            if found and not blocked and team then
                table.insert(valids, position)
            end
        elseif movement then
            --Don't let moves phase through pieces
            --Don't move into occupied squares
            --No need to checkTeam if there's no piece there
            if not found and not blocked then
                table.insert(valids, position)
            end
        end
    end

    if #valids > 0 then
        return p.render and p:render() or valids
    end

    --This is returning an empty table, but we don't need to create a new
    --one for no reason.
    return valids
end

--If the piece has side effects, then that will be fired, and the results of that will
--be returned instead. Otherwise, simply returns the pieces new location, whatever it
--may be. Returns two tables containing the locations and atack_locations (may be the
--the same)
function Action:enact(game, piece)
    local p, locations, new_locations, new_attacks
    
    p = private[self]
    
    locations = self:everyValidLocation(game, piece)

    if p.effect then
        new_locations, new_attacks = p:effect(game, piece)
    end

    if p.attack and p.movement then
        return new_locations or locations, new_attacks or locations
    end

    if p.attack then
        return new_locations, new_attacks or locations
    end
    
    return new_locations or locations, new_attacks
end

    --======GETTERS======--

function Action.__get:name()
    return private[self].name
end

function Action.__get:direction()
    return private[self].direction
end

    --======SETTERS======--
    
    --======METAMETHODS======--

function Action:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.name) end

    return self:tostringHelper("Class")
end

Action.__type = "action"

return Action