local Object, private
local Async

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Async = Object:init()

    --======PRIVATE FUNCTIONS======--

local threads, lookup

--`threads` is all of the relevant coroutines, which we iterate over when updating.
threads = {}

--`lookup` lets us check if the currently running coroutine is an Async one, without
--needing to iterate over all of threads every time.
lookup  = {}

    --======CONSTRUCTOR======--

function Async:new(f, ...)
    local co = coroutine.create(function(...)
        local success, err = xpcall(f, debug.traceback, ...)

        if not success then error(err, 0) end
    end)

    threads[#threads + 1] = {
        co    = co,
        args  = { ... },
        timer = 0
    }

    lookup[co]    = true
    private[self] = nil

    return true
end

    --======METHODS======--

function Async:wait(delay)
    local co = coroutine.running()

    if not co         then return end
    if not lookup[co] then return end

    threads[lookup[co]].timer = delay

    coroutine.yield(co)
end

--Runs a function until it returns a truthy value.
function Async:waitFor(func, ...)
    local co, output

    co = coroutine.running()

    if not co         then return end
    if not lookup[co] then return end

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

    if not co         then return end
    if not lookup[co] then return end
    
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
    --Iterate over threads backwards, so we can remove dead ones. Update any time
    --values if needed. Any function that is ready gets called. Order doesn't matter
    --since these are *Async* functions, and therefore run asyncronously. That means
    --each coroutine is theoretically indepenent from the next, even if that's not
    --literally true.
    for i = #threads, 1, -1 do
        if coroutine.status(threads[i].co) == "dead" then
            lookup[threads[i].co] = nil

            table.remove(threads, i)
        elseif threads[i].timer > 0 then
            threads[i].timer = threads[i].timer - dt
        else
            local success, output = coroutine.resume(threads[i].co, table.unpack(threads[i].args or {}))

            --Rethrow the captured error, which will contain the actual stacktrace from
            --inside the coroutine. We throw a table so that love.errorhandler knows not
            --to just debug.traceback it again. This should only happen for raw asserts
            --and errors inside the coroutine.
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
    return self:tostring(#threads)
end

Async.__type = "async"

return Object:create(Async)