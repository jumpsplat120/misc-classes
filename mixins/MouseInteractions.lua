local Object, private
local MouseInteractions, Vector

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Vector = require("classes.Vector")

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
        self:dispatchSync("hover", p.mouse_interactions.current.position)
        self:dispatch("hover", p.mouse_interactions.current.position)

        if p.mouse_interactions.previous.hold_down and p.mouse_interactions.current.hold_down then
            self:dispatchSync("holddown", p.mouse_interactions.current.position)
            self:dispatch("holddown", p.mouse_interactions.current.position)
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
    
    self:dispatchSync("mousedown", x, y, ...)
    self:dispatch("mousedown", x, y, ...)
    
    if p.mouse_interactions.current.down_on and p.mouse_interactions.current.down_on + 0.2 >= os.clock() then
        self:dispatchSync("doubleclick", x, y, ...)
        self:dispatch("doubleclick", x, y, ...)
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
        self:dispatchSync("mouseup", x, y, ...)
        self:dispatch("mouseup", x, y, ...)
    end
    
    if p.mouse_interactions.current.dragged_in and touching then
        self:dispatchSync("dropin",  x, y, ...)
        self:dispatch("dropin", x, y, ...)
    elseif p.mouse_interactions.current.hold_down and touching then
        self:dispatchSync("fullclick",  x, y, ...)
        self:dispatch("fullclick",  x, y, ...)
    elseif p.mouse_interactions.current.hold_down and not touching then
        self:dispatchSync("dropout",  x, y, ...)
        self:dispatch("dropout",  x, y, ...)
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
        self:dispatchSync("mouseover", x, y, ...)
        self:dispatch("mouseover", x, y, ...)
    end
    
    if p.mouse_interactions.current.hold_down and touching then
        self:dispatchSync("drag", x, y, ...)
        self:dispatch("drag", x, y, ...)
    elseif p.mouse_interactions.current.hold_down and not touching and p.mouse_interactions.previous.mouse_in then
        self:dispatchSync("dragout", x, y, ...)
        self:dispatch("dragout", x, y, ...)
    elseif p.mouse_interactions.current.hold_down and touching and not p.mouse_interactions.previous.mouse_in then        
        self:dispatchSync("dragin", x, y, ...)
        self:dispatch("dragin", x, y, ...)
    end

    if not p.mouse_interactions.previous.mouse_in and touching then
        self:dispatchSync("mousein", p.mouse_interactions.current.position)
        self:dispatch("mousein", p.mouse_interactions.current.position)
    elseif p.mouse_interactions.previous.mouse_in and not touching then
        self:dispatchSync("mouseout", p.mouse_interactions.current.position)
        self:dispatch("mouseout", p.mouse_interactions.current.position)
    end

    p.mouse_interactions.previous.mouse_in = p.mouse_interactions.current.mouse_in
    p.mouse_interactions.current.mouse_in  = touching

    return self
end

function MouseInteractions:wheelmoved(...)
    if not self:contains(private[self].mouse_interactions.current.position) then return self end

    self:dispatchSync("scroll", ...)
    self:dispatch("scroll", ...)

    return self
end

    --======GETTERS======--

    --======SETTERS======--

    --======METAMETHODS======--

return MouseInteractions