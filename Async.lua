local Object, private
local Async

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Async = Object:init()

    --======PRIVATE FUNCTIONS======--

local threads, lookup

threads = {}
lookup  = {}

    --======CONSTRUCTOR======--

function Async:new(f, ...)
    local co = coroutine.create(f)

    threads[#threads + 1] = {
        co   = co,
        args = { ... },
        time = 0
    }

    lookup[co] = #threads
    
    private[self] = nil

    return true
end

    --======METHODS======--

function Async:wait(delay)
    local co = coroutine.running()

    if not co         then return end
    if not lookup[co] then return end

    threads[lookup[co]].time = delay

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
    
    if timeout then threads[lookup[co]].time = timeout end

    object:once(event, function(...) output = { ... } end, ...)

    while not output do
        if timeout and threads[lookup[co]].time <= 0 then return "timeout" end

        coroutine.yield(co)
    end

    return table.unpack(output)
end

function Async:update(dt)
    local running, discard

    running = {}
    discard = {}

    --Iterate over threads in order they were declared
    --Add dead coroutines to discard table to remove later
    --Update time value if needed
    --If ready to run, add to run table
    for i, tbl in ipairs(threads) do
        if coroutine.status(tbl.co) == "dead" then
            discard[#discard + 1] = { tbl.co, i }
        elseif tbl.time > 0 then
            tbl.time = tbl.time - dt
        else
            running[#running + 1] = tbl.co
        end
    end

    --Reverse discard table so we can remove numeric incides without issues
    --Remove coroutine from lookup table
    for _, tbl in ipairs(table.reverse(discard)) do
        lookup[tbl[1]] = nil
        
        table.remove(threads, tbl[2])
    end

    --Update lookup to have new thread index
    for i, tbl in ipairs(threads) do
        lookup[tbl.co] = i
    end

    --Finally, actually run each coroutine that needs to be run.Catch errors and rethrow them.
    for _, co in ipairs(running) do
        assert(coroutine.resume(co, table.unpack(threads[lookup[co]].args or {})))
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