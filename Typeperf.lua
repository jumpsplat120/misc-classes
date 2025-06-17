---@type Object
local Object
local Process, Typeperf, Event, private

ffi = require("ffi")

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Event   = require("classes.Event")
Process = require("classes.Process")

Typeperf = Object:extend()

private[Typeperf] = {}

    --======PRIVATE FUNCTIONS======--

local singleton = false

    --======CONSTRUCTOR======--

function Typeperf:new(poll_rate, ...)
    assert(not singleton, "Typeperf; you can only have one instance of Typeperf running.")

    if not singleton then singleton = true end

    local p = private[self]

    p.poll_rate  = poll_rate or 1
    p.tmpname    = os.tmpname()
    p.iterations = 0
    p.timer      = 0
    p.keys       = {}
    p.counters   = ""

    for _, key in ipairs({...}) do
        p.keys[#p.keys + 1] = {
            key
                :gsub("%%", "%%%%")
                :gsub("%(%*%)", "%(%.%*%)")
                :gsub("%(", "%%(")
                :gsub("%)", "%%)")
                :gsub("%-", "%%-")
                :gsub([[\\]], ""),
            key
        }

        p.counters = p.counters .. '"' .. key .. '" ' 
    end

    p.process = Process("typeperf " .. p.counters .. "-o " .. p.tmpname .. " -si " .. p.poll_rate)

    Event:on("love.quit", self.quit, self)
    Event:on("love.load", self.load, self)
    Event:on("love.update", self.update, self)
end

    --======STATIC======--

    --======METHODS======--

function Typeperf:load()
    local p = private[self]

    p.process.use_show_window = true
    p.process.show_window     = "hide"

    p.process:execute()
end

function Typeperf:update(dt)
    local p, err, timestamp, line, values
    
    p = private[self]

    p.timer = p.timer + dt

    if not (p.timer > p.poll_rate) then return self end

    if not p.handle then p.handle, err = io.open(p.tmpname, "r") end
    
    if err then print(err) end

    if not p.handle then return end

    if not p.lookup_table then
        local lines = p.handle:read("*l"):gsub('"', ""):split(",")

        p.lookup_table = {}

        for i, entry in ipairs(lines) do
            local machine, object, counter = table.unpack(entry:gsub([[\\]], ""):split("\\"))
            
            if i ~= 1 then
                local match

                for _, tbl in ipairs(p.keys) do
                    if entry:match(tbl[1]) then
                        match = tbl[2]
                        break
                    end
                end

                p.lookup_table[#p.lookup_table + 1] = {
                    machine = machine,
                    counter = counter,
                    object  = object,
                    key     = match
                }
            end
        end

        return
    end

    line = p.handle:read("*l")
    
    if not line then return end

    values = {}

    for i, entry in ipairs(line:gsub('"', ""):split(",")) do
        if i == 1 then
            timestamp = entry
        else
            local lut = p.lookup_table[i - 1]

            if not values[lut.key] then
                values[lut.key] = {
                    machine = lut.machine,
                    counter = lut.counter,
                    values  = {}
                }
            end

            values[lut.key].values[lut.object] = entry
        end
    end

    for key, entry in pairs(values) do
        Event:dispatch("typeperf.line_added", timestamp, entry.values, entry.machine, entry.counter, key:after("\\"):before("\\"), key)
    end
    
    p.timer = 0

    p.iterations = p.iterations + 1

    if p.iterations < 1000 then return end

    self:flush()

    p.iterations = 0
end

function Typeperf:quit()
    local p = private[self]

    if p.handle then
        p.handle:close()

        p.handle = nil
    end

    os.remove(p.tmpname)

    p.process:close()

    p.process = nil
end

function Typeperf:flush()
    local p = private[self]

    self:quit()

    p.process = Process("typeperf " .. p.counters .. "-o " .. p.tmpname .. " -si " .. p.poll_rate)

    self:load()
end

    --======GETTERS======--

function Typeperf.__get:poll_rate()
    return private[self].poll_rate
end

    --======SETTERS======--

function Typeperf.__set:poll_rate(value)
    --no negative
    --no zero
    --only number
    private[self].poll_rate = value
end

    --======METAMETHODS======--

function Typeperf:__tostring()
    if self.is_instance then
        return self:tostringHelper()
    else
        return self:tostringHelper("Class")
    end
end

Typeperf.__type = "Typeperf"

return Typeperf