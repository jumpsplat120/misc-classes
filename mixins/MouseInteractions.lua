local Object, private
local MouseInteractions
local Vector

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Vector = require("classes.Vector")

---@type MouseInteractions.Mixin
MouseInteractions = Object:init()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function MouseInteractions:new()
    local p = private[self]

    p.mouse_interactions = {
        previous = {
            hold_down   = false,
            mouse_in    = false,
            down_on     = false,
            dragged_in  = false,
            dragged_out = false,
            position    = Vector:fromValues(0, 0)
        },
        current = {
            hold_down   = false,
            mouse_in    = false,
            down_on     = false,
            dragged_in  = false,
            dragged_out = false,
            position    = Vector:fromValues(0, 0)
        }
    }
end

    --======STATIC======--

    --======METHODS======--

function MouseInteractions:update(dt)
    local p, touching
    
    p        = private[self]
    touching = self:contains(p.mouse_interactions.current.position)

    if touching then
        self:dispatch("mouse.hover", p.mouse_interactions.current.position)
        self:dispatchSync("mouse.hover", p.mouse_interactions.current.position)

        if p.mouse_interactions.previous.hold_down and p.mouse_interactions.current.hold_down then
            self:dispatch("mouse.hold", p.mouse_interactions.current.position)
            self:dispatchSync("mouse.hold", p.mouse_interactions.current.position)
        end
    end

    p.mouse_interactions.previous.down_on  = p.mouse_interactions.current.down_on
    p.mouse_interactions.previous.mouse_in = p.mouse_interactions.current.mouse_in
    p.mouse_interactions.current.mouse_in  = touching

    return self
end

function MouseInteractions:mousepressed(x, y, ...)
    local p, touching
    
    p = private[self]
    
    p.mouse_interactions.current.position:setToValues(x, y)

    touching = self:contains(p.mouse_interactions.current.position)

    p.mouse_interactions.previous.mouse_in = p.mouse_interactions.current.mouse_in
    p.mouse_interactions.current.mouse_in  = touching

    if not touching then return end
    
    self:dispatch("mouse.pressed", x, y, ...)
    self:dispatchSync("mouse.pressed", x, y, ...)
    
    if p.mouse_interactions.current.down_on and p.mouse_interactions.current.down_on + 0.2 >= os.clock() then
        self:dispatch("mouse.doubleclick", x, y, ...)
        self:dispatchSync("mouse.doubleclick", x, y, ...)
    end
    
    p.mouse_interactions.previous.hold_down = false
    p.mouse_interactions.current.hold_down  = true
    p.mouse_interactions.current.down_on    = os.clock()

    return self
end

function MouseInteractions:mousereleased(x, y, ...)
    local p, touching 
    
    p = private[self]

    p.mouse_interactions.current.position:setToValues(x, y)

    touching = self:contains(p.mouse_interactions.current.position)
    
    if touching then
        self:dispatch("mouse.released", x, y, ...)
        self:dispatchSync("mouse.released", x, y, ...)
    end
    
    if p.mouse_interactions.current.dragged_in and touching then
        self:dispatch("mouse.dropin", x, y, ...)
        self:dispatchSync("mouse.dropin",  x, y, ...)
    elseif p.mouse_interactions.current.hold_down and touching then
        self:dispatch("mouse.click",  x, y, ...)
        self:dispatchSync("mouse.click",  x, y, ...)
    elseif p.mouse_interactions.current.hold_down and not touching then
        self:dispatch("mouse.dropout",  x, y, ...)
        self:dispatchSync("mouse.dropout",  x, y, ...)
    end

    p.mouse_interactions.previous.mouse_in = p.mouse_interactions.current.mouse_in
    p.mouse_interactions.current.mouse_in  = touching
    p.mouse_interactions.previous.hold_down = true
    p.mouse_interactions.current.hold_down  = false

    return self
end

function MouseInteractions:mousemoved(x, y, ...)
    local p, touching
    
    p = private[self]

    p.mouse_interactions.current.position:setToValues(x, y)

    touching = self:contains(p.mouse_interactions.current.position)
    
    if touching then
        self:dispatch("mouse.over", x, y, ...)
        self:dispatchSync("mouse.over", x, y, ...)
    end
    
    if p.mouse_interactions.current.hold_down and touching then
        self:dispatch("mouse.drag", x, y, ...)
        self:dispatchSync("mouse.drag", x, y, ...)
    elseif p.mouse_interactions.current.hold_down and not touching and p.mouse_interactions.previous.mouse_in then
        self:dispatch("mouse.dragout", x, y, ...)
        self:dispatchSync("mouse.dragout", x, y, ...)
    elseif p.mouse_interactions.current.hold_down and touching and not p.mouse_interactions.previous.mouse_in then
        self:dispatch("mouse.dragin", x, y, ...)
        self:dispatchSync("mouse.dragin", x, y, ...)
    end

    if not p.mouse_interactions.previous.mouse_in and touching then
        self:dispatch("mouse.entered", p.mouse_interactions.current.position)
        self:dispatchSync("mouse.entered", p.mouse_interactions.current.position)
    elseif p.mouse_interactions.previous.mouse_in and not touching then
        self:dispatch("mouse.left", p.mouse_interactions.current.position)
        self:dispatchSync("mouse.left", p.mouse_interactions.current.position)
    end

    p.mouse_interactions.previous.mouse_in = p.mouse_interactions.current.mouse_in
    p.mouse_interactions.current.mouse_in  = touching

    return self
end

function MouseInteractions:wheelmoved(...)
    if not self:contains(private[self].mouse_interactions.current.position) then return self end

    self:dispatch("mouse.scrollon", ...)
    self:dispatchSync("mouse.scrollon", ...)

    return self
end

    --======GETTERS======--

    --======SETTERS======--

    --======METAMETHODS======--

return MouseInteractions