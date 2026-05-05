local Object, private
local Pairs

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

---@type Pairs.Mixin
Pairs = Object:init()

    --======PRIVATE FUNCTIONS======--

    --======CONSTRUCTOR======--

function Pairs:new()
    private[self].pairs = {}
end

    --======STATIC======--

    --======METHODS======--

function Pairs:pairs()
    local p = private[self].pairs
    
    if p.coroutine and coroutine.status(p.coroutine) == "dead" then
        p.coroutine = nil
    end

    if not p.coroutine then
        p.coroutine = coroutine.create(function()
            for k, v in pairs(private[self].values or {}) do
                coroutine.yield(k, v)
            end
        end)
    end

    return function()
        local status, k, v = coroutine.resume(p.coroutine)

        return k, v
    end
end

    --======GETTERS======--

    --======SETTERS======--

    --======METAMETHODS======--

function Pairs:__call()
    local p, status, k, v
    
    p = private[self].pairs
    
    if p.coroutine and coroutine.status(p.coroutine) == "dead" then
        p.coroutine = nil
    end

    if not p.coroutine then
        p.coroutine = coroutine.create(function()
            for k, v in pairs(private[self].values or {}) do
                coroutine.yield(k, v)
            end
        end)
    end

    status, k, v = coroutine.resume(p.coroutine)
        
    return k, v
end

return Pairs