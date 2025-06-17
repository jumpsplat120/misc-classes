---@type Object
local Object
local Piece, private
local Rectangle, Vector, Color, Game
local Emitter
local TL

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Game      = require("classes.Game")
Color     = require("classes.Color")
Vector    = require("classes.Vector")
Rectangle = require("classes.Rectangle")

Emitter = require("classes.mixins.Emitter")

TL = require("lib.string_template")

Piece = Object:extend()

Piece:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local event, setsprite, draw, invis, white, game

game = Game()

function event(_, event, self, ...)
    self:dispatchSync(event, ...)
end

function setsprite(p, add)
    local x, y, sx, sy, ox, oy

    x, y   = p.position:unpack()
    ox, oy = p.origin:unpack()
    sx, sy = p.scale:unpack()

    p.spritebatch.colored:setColor(
        p.color.red,
        p.color.green,
        p.color.blue,
        p.color.alpha
    )
    
    if add then
        p.spritebatch.colored:add(x, y, 0, sx, sy, ox / sx, oy / sy)

        return p.spritebatch.uncolored:add(x, y, 0, sx, sy, ox / sx, oy / sy)
    end

    p.spritebatch.colored:set(p.sprite_id, x, y, 0, sx, sy, ox / sx, oy / sy)
    p.spritebatch.uncolored:set(p.sprite_id, x, y, 0, sx, sy, ox / sx, oy / sy)
end

function shaderdraw(p, camera)
    love.graphics.draw(p.spritebatch.uncolored, camera:translateValues(0, 0))
end

function draw(p, camera)
    local canvas, shader, blendmode
    if p.shader then
        canvas, shader, blendmode = p.shader.effect.draw(shaderdraw, p, camera)
    end

    if canvas then
        white:apply()
        p.shader.color:apply()
        love.graphics.draw(canvas)
        p.shader.color:remove()
        white:remove()

        --Reset to original blendmode/shader/color
        love.graphics.setBlendMode(blendmode)
        love.graphics.setShader(shader)
    end

    love.graphics.draw(p.spritebatch.colored, camera:translateValues(0, 0))
end

invis = Color:fromRGB(0, 0, 0, 0)
white = Color:fromRGB(1, 1, 1, 1)

    --======CONSTRUCTOR======--

function Piece:new(name, icon, team, size)
    local p, dx, dy
    
    p = private[self]

    p.size = size
    p.name = name
    p.icon = icon
    p.team = team

    p.hitbox = Rectangle(0, 0, size, size)

    p.location = Vector:fromValues(0, 0, 0)
    p.position = p.hitbox.position
    p.origin   = p.hitbox.origin

    p.color   = p.team.color
    p.forward = p.team.forward

    p.image = love.graphics.newImage(TL("assets/pieces/%{icon}.png", { icon = icon }))

    dx, dy = p.image:getDimensions()
    
    p.scale = Vector:fromValues(p.size / dx, p.size / dy)

    p.update_position = true
    p.alive           = true
    
    p.previous_positions = {}
    p.captures           = {}
    p.passives           = {}
    p.actions            = {}
    
    --There's two versions, one is used for the shader (it needs to be white, otherwise
    --black pieces just end up fully black), and the other one is for drawing on top.
    p.spritebatch = {
        uncolored = love.graphics.newSpriteBatch(p.image),
        colored   = love.graphics.newSpriteBatch(p.image)
    }
    
    p.hitbox:onSync("doubleclick", event, "doubleclick", self)
    p.hitbox:onSync("fullclick", event, "fullclick", self)
    p.hitbox:onSync("mouseover", event, "mouseover", self)
    p.hitbox:onSync("mousedown", event, "mousedown", self)
    p.hitbox:onSync("holddown", event, "holddown", self)
    p.hitbox:onSync("mouseout", event, "mouseout", self)
    p.hitbox:onSync("mousein", event, "mousein", self)
    p.hitbox:onSync("dropout", event, "dropout", self)
    p.hitbox:onSync("mouseup", event, "mouseup", self)
    p.hitbox:onSync("dragout", event, "dragout", self)
    p.hitbox:onSync("dropin", event, "dropin", self)
    p.hitbox:onSync("dragin", event, "dragin", self)
    p.hitbox:onSync("hover", event, "hover", self)
    p.hitbox:onSync("drag", event, "drag", self)
end

    --======METHODS======--

--Draw should ONLY be called by the prototypical pieces. For example, if you
--are drawing pawn, then you only do `game.proto.pawn`, not every piece that is a pawn.
function Piece:draw(camera)
    local p = private[self]
    
    draw(p, camera)
    
    return self
end

--Allows you to draw a specific sprite. Useful if the sprite ordering is specific.
--NOTE: You will likely be drawing the sprite twice. Be aware of this in regards 
--to shaders where that sort of thing can be noticed.
function Piece:drawSpecific(camera)
    local p = private[self]

    p.spritebatch.colored:setDrawRange(p.sprite_id, 1)
    p.spritebatch.uncolored:setDrawRange(p.sprite_id, 1)

    draw(p, camera)

    p.spritebatch.colored:setDrawRange()
    p.spritebatch.uncolored:setDrawRange()
end

--TODO: Error checking
function Piece:addShader(shader)
    local p = private[self]

    p.shader = shader

    return self
end

function Piece:update(dt)
    local p = private[self]

    if not p.alive then return end

    p.hitbox:update(dt)
    
    --If we're actively updating the position, then the location is being
    --transformed into drawable position info. If not, then the location
    --and position can be unaligned (for example, when dragging a piece
    --around on the board, or animating it's position)
    if p.update_position then
        p.position.x =  p.location.x * p.size
        p.position.y = -p.location.z * p.size
    end

    --If the non prototypical piece had their position, origin, location
    -- or team accessed, then we assume there's been a change, and update
    --that sprite in the spritebatch.
    if p.needs_redraw then
        setsprite(p)

        p.needs_redraw = false
    end
end

function Piece:mousepressed(...)
    local p = private[self]

    if not p.alive then return end
    
    p.hitbox:mousepressed(...)
end

function Piece:mousereleased(...)
    local p = private[self]

    if not p.alive then return end

    p.hitbox:mousereleased(...)
end

function Piece:wheelmoved(...)
    local p = private[self]

    if not p.alive then return end

    p.hitbox:wheelmoved(...)
end

function Piece:mousemoved(...)
    local p = private[self]

    if not p.alive then return end

    p.hitbox:mousemoved(...)
end

function Piece:addAction(action)
    local p = private[self]
    
    p.actions[action] = true

    return self
end

function Piece:addPassive(passive)
    local p = private[self]
    
    p.passives[passive] = true
    
    return self
end

--Capture another piece without an action.
function Piece:capture(piece)
    local p = private[self]

    table.insert(p.captures, piece)
    
    game.board[tostring(piece.location)] = nil

    piece.alive       = false
    piece.captured_by = self
    
    game:dispatchSync("capture_piece", self, piece)

    return self
end

function Piece:getValidActions(game)
    local p, valid_actions

    p = private[self]
    
    valid_actions = {}

    for action, _ in pairs(p.actions) do
        if #action:everyValidLocation(game, self) > 0 then
            table.insert(valid_actions, action)
        end
    end
    
    return valid_actions
end

function Piece:undoPreviousAction()
    local p, move
    
    p = private[self]
    
    move = table.remove(p.previous_positions)

    game:dispatchSync("undo_piece_action.begin", self, move.action)

    game.board[tostring(p.location)] = nil

    p.location:setToVector(move.location)

    game.board[tostring(p.location)] = self

    for _, captured in ipairs(move.captures) do
        captured.alive = true

        game.board[tostring(captured.location)] = captured
    end

    game:dispatchSync("undo_piece_action.end", self, move.action)

    return self
end

function Piece:doAction(game, action, position)
    local p, new_locations, attack_locations, move
    
    p = private[self]

    game:dispatchSync("piece_action.begin", self, action, position)

    new_locations, attack_locations = action:enact(game, self)
    
    move = {
        location = p.location:clone(),
        action   = action,
        turn     = game.turn,
        captures = {}
    }
    
    if attack_locations then
        local piece
        
        for _, location in ipairs(attack_locations) do
            piece = game.board[tostring(location)]
            
            if piece then
                self:capture(piece)

                table.insert(move.captures, piece)
            end
        end
    end

    if new_locations then
        for _, location in ipairs(new_locations) do
            if location:matches(position) then
                game:dispatchSync("piece_movement.begin", self)

                game.board[tostring(p.location)] = nil

                p.location:setToVector(location)

                game.board[tostring(location)] = self

                game:dispatchSync("piece_movement.begin", self)

                break
            end
        end
    end

    table.insert(p.previous_positions, move)

    game:dispatchSync("piece_action.end", self, action, position)

    return self
end

function Piece:doPassives(game)
    local p = private[self]
    
    for passive, _ in pairs(p.passives) do
        if passive:isValid(game, self) then
            game:dispatchSync("piece_passive.begin", self, passive)

            passive:enact(game, self)

            table.insert(p.previous_positions, {
                position = p.location:clone(),
                passive  = passive,
                turn     = game.turn
            })

            game:dispatchSync("piece_passive.end", self, passive)
        end
    end

    return self
end

--Realistically, you should only ever clone the prototypical piece, as
--cloning other pieces may have unforseen consequences. I'm trying to account
--for those behaviours here, but better to be safe than sorry. Clone prototypically,
--then account for any edge cases yourself, if you need to do so.
function Piece:clone()
    local p, pc, clone

    p     = private[self]
    clone = Piece(p.name, p.icon, p.team, p.size)

    pc = private[clone]

    pc.location:setToVector(p.location)
    pc.position:setToVector(p.position)
    pc.forward:setToVector(p.forward)
    pc.origin:setToVector(p.origin)

    pc.update_position = p.update_position
    pc.alive           = p.alive

    for i, v in ipairs(p.previous_positions) do
        pc.previous_positions[i] = {
            position = v.position:clone(),
            action   = v.action,
            turn     = v.turn
        }
    end
    
    for i, v in ipairs(p.captures) do
        pc.captures[i] = v
    end

    for k, v in pairs(p.passives) do
        pc.passives[k] = v
    end
    
    for k, v in pairs(p.actions) do
        pc.actions[k] = v
    end

    pc.sprite_id   = setsprite(p, true)
    pc.spritebatch = p.spritebatch

    return clone
end

    --======GETTERS======--

function Piece.__get:location()
    local p = private[self]

    p.needs_redraw = true

    return p.location
end

function Piece.__get:position()
    local p = private[self]

    p.needs_redraw = true

    return p.position
end

function Piece.__get:origin()
    local p = private[self]

    p.needs_redraw = true

    return p.origin
end

function Piece.__get:size()
    return private[self].size
end

function Piece.__get:actions()
    return table.keys(private[self].actions)
end

function Piece.__get:team()
    local p = private[self]
    
    p.needs_redraw = true

    return p.team
end

function Piece.__get:forward()
    return private[self].forward
end

function Piece.__get:moves()
    return private[self].previous_positions
end

function Piece.__get:update_position()
    return private[self].update_position
end

function Piece.__get:alive()
    return private[self].alive
end

function Piece.__get:name()
    return private[self].name
end

function Piece.__get:color()
    return private[self].image.color
end

function Piece.__get:captured_by()
    return private[self].captured_by
end

    --======SETTERS======--

function Piece.__set:update_position(value)
    private[self].update_position = not not value
end

function Piece.__set:alive(value)
    local p = private[self]

    p.alive = not not value

    p.color = p.alive and p.team.color or invis

    setsprite(p)
end

--TODO: Error checking, and also, do we want to point to another
--table like this?
function Piece.__set:moves(value)
    private[self].previous_positions = value
end

--TODO: Add error checking
function Piece.__set:team(value)
    local p = private[self]
    
    p.team    = value
    p.color   = p.team.color
    p.forward = p.team.forward

    setsprite(p)
end

--TODO: Add error checking
function Piece.__set:captured_by(value)
    private[self].captured_by = value
end


    --======METAMETHODS======--

function Piece:__tostring()
    local p = private[self]

    if self.is_instance then return self:tostringHelper(p.name) end

    return self:tostringHelper("Class")
end

Piece.__type = "piece"

return Piece