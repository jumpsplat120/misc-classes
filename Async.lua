local Object, private
local Async

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Async = Object:init()

    --======PRIVATE FUNCTIONS======--

local threads = {}

    --======CONSTRUCTOR======--

function Async:new(f, ...)
    local co = coroutine.create(function(...)
        local success, err = xpcall(f, debug.traceback, ...)

        if not success then error(err, 0) end
    end)

    private[self] = nil

    threads[co] = {
        args  = { ... },
        timer = 0
    }

    return true
end

    --======METHODS======--

function Async:wait(delay)
    local co = coroutine.running()

    if not co         then return end
    if not threads[co] then return end

    threads[co].timer = delay

    coroutine.yield(co)
end

--Runs a function until it returns a truthy value.
function Async:waitFor(func, ...)
    local co, output

    co = coroutine.running()

    if not co          then return end
    if not threads[co] then return end

    while true do
        output = func(...)
        
        if output then break end

        coroutine.yield(co)
    end
    
    return output
end

function Async:waitForEvent(object, event, timeout, ...)
    local co, output

    co = coroutine.running()

    if not co          then return end
    if not threads[co] then return end
    
    if timeout then
        threads[co].timer = timeout
    end

    object:once(event, function(...) output = { ... } end, ...)

    while not output do
        if timeout and threads[co].timer <= 0 then
            return "timeout"
        end

        coroutine.yield(co)
    end

    return table.unpack(output)
end

function Async:update(dt)
    for co, data in pairs(threads) do
        if coroutine.status(co) == "dead" then
            threads[co] = nil
        elseif data.timer > 0 then
            data.timer = data.timer - dt
        else
            local success, output = coroutine.resume(co, table.unpack(data.args or {}))

            --Rethrow the captured error, which will contain the actual stacktrace from
            --inside the coroutine. We throw a table so that love.errorhandler knows not
            --to just debug.traceback it again. This should only happen for raw asserts
            --and errors inside the coroutine. We use error to set the level, which you
            --can't do with assert.
            if not success then
                error({ output }, 0)
            end
        end
    end
end

    --======GETTERS======--

    --======SETTERS======--

    --======METAMETHODS======--

function Async:__tostring()
    return self:tostring(table.count(lookup))
end

Async.__type = "async"

---@type Async.Class
local Class = Object:create(Async)

return Class