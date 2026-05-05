local Object, private
local Ipairs

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

---@type Ipairs.Mixin
Ipairs = Object:init()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Ipairs:new()
    private[self].ipairs = {}
end

    --======STATIC======--

    --======METHODS======--

function Ipairs:ipairs()
    local p = private[self].ipairs
    
    if p.coroutine and coroutine.status(p.coroutine) == "dead" then
        p.coroutine = nil
    end

    if not p.coroutine then
        p.coroutine = coroutine.create(function()
            for i, v in ipairs(private[self].values or {}) do
                coroutine.yield(i, v)
            end
        end)
    end

    return function()
        local status, i, v = coroutine.resume(p.coroutine)

        return i, v
    end
end

    --======GETTERS======--

    --======SETTERS======--

    --======METAMETHODS======--

function Ipairs:__call()
    local p, status, i, v
    
    p = private[self].ipairs
    
    if p.coroutine and coroutine.status(p.coroutine) == "dead" then
        p.coroutine = nil
    end

    if not p.coroutine then
        p.coroutine = coroutine.create(function()
            for i, v in ipairs(private[self].values or {}) do
                coroutine.yield(i, v)
            end
        end)
    end

    status, i, v = coroutine.resume(p.coroutine)
        
    return i, v
end

return Ipairs