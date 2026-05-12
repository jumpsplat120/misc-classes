local Object, private
local Animation
local Easings
local Emitter, Drawable
local TypeError, PositiveError, VectorSizeError

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Easings = require("classes.Easings")

Emitter  = require("classes.mixins.Emitter")
Drawable = require("classes.mixins.Drawable")

TypeError = require("classes.errors.TypeError")
PositiveError = require("classes.errors.PositiveError")
VectorSizeError = require("classes.errors.VectorSizeError")

Animation = Object:init()

    --======PRIVATE FUNCTIONS======--

local shear, scale, rotate, translate
local lerp

lerp = Easings:linear()

--Explination for math
--Assume that `finish` is a value of 15, and we are 30% of the way through a
--transformation. That means we want to be 4.5 units away from the data.intital
--(usually zero, but not always, such as in the case of scale). However, the
--transform is relevative to it's current positional, so we need to subtract
--that 4.5 from however far we've already transformed. Assuming we transformed 4
--units already, then weekday actually only want to move 0.5 more. Thus, our
--final result.

function shear(self, data, progress)
    local expected = (data.finish - data.start):multiply(progress):add(data.start)

    private[self].transform:shear(expected - data.value)

    data.value:setToVector(progress == 1 and data.start or expected)
end

function scale(self, data, progress)
    local expected = (data.finish - data.start):multiply(progress):add(data.start)

    private[self].transform:scale(expected - data.value)

    data.value:setToVector(progress == 1 and data.start or expected)
end

function rotate(self, data, progress)
    local expected = data.start + (data.finish - data.start) * progress

    private[self].transform:rotate(expected - data.value)

    data.value = progress == 1 and data.start or expected
end

function translate(self, data, progress)
    local expected = (data.finish - data.start):multiply(progress):add(data.start)

    private[self].transform:translate(expected - data.value)

    data.value:setToVector(progress == 1 and data.start or expected)
end

    --======CONSTRUCTOR======--

--Assumes that the transform is identity. So a `rotate(math.pi)` is a half turn, not a
--turn from 0 to math.pi.
function Animation:new(transform)
    local p = private[self]

    Emitter.new(self)

    p.emit      = true
    p.time      = 0
    p.copy      = transform:clone()
    p.transform = transform

    p.step  = 1
    p.steps = { {} }
end

    --======METHODS======--

function Animation:update(dt)
    local p, step, final
    
    p = private[self]

    if not p.playing then return end

    step = p.steps[p.step]
    
    p.time = math.min(p.time + dt * p.speed, step.seconds)
    
    for _, data in ipairs(step) do
        data.callback(self, data, (data.easing or lerp)(p.time / step.seconds))
    end

    if p.time >= step.seconds then
        p.time = 0

        if p.step == #p.steps then
            p.step    = 1
            p.playing = false

            p.copy.matrix = p.transform.matrix

            if p.emit then
                self:dispatch("animation.finish")
                self:dispatchSync("animation.finish")
            end
        else
            p.step = p.step + 1

            if p.emit then
                self:dispatch("animation.step", p.step - 1)
                self:dispatchSync("animation.step", p.step - 1)
            end
        end
    end

    return self
end

function Animation:shear(skew, easing)
    local p = private[self]

    TypeError:assert(type(skew) == "vector", "skew", type(skew), "vector")
    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")
    VectorSizeError:assert(skew.size == 2, skew.size, 2)

    table.insert(p.steps[p.step], {
        start    = skew:clone():setToValue(0),
        value    = skew:clone():setToValue(0),
        easing   = easing,
        finish   = skew,
        callback = shear
    })

    return self
end

function Animation:scale(size, easing)
    local p = private[self]

    TypeError:assert(type(size) == "vector", "size", type(size), "vector")
    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")
    VectorSizeError:assert(size.size == 2, size.size, 2)

    table.insert(p.steps[p.step], {
        start    = size:clone():setToValue(1),
        value    = size:clone():setToValue(1),
        easing   = easing,
        finish   = size,
        callback = scale
    })

    return self
end

function Animation:rotate(angle, easing)
    local p = private[self]
    
    TypeError:assert(type(angle) == "number", "angle", type(angle), "number")
    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")

    table.insert(p.steps[p.step], {
        start    = 0,
        value    = 0,
        easing   = easing,
        finish   = angle,
        callback = rotate
    })

    return self
end

--Translate `distance`, optionally with some sort of
--easing. `distance` is not the endpoint, but how far the thing needs to travel.
--So if `distance` is 5, 5, then if the transform is 0, 0, it ends at 5, 5, but
--if the transform is 15, 17, then it ends at 20, 22.
function Animation:translate(distance, easing)
    local p = private[self]

    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")
    TypeError:assert(type(distance) == "vector", "distance", type(distance), "vector")
    VectorSizeError:assert(distance.size == 2, distance.size, 2)

    table.insert(p.steps[p.step], {
        start    = distance:clone():setToValue(0),
        value    = distance:clone():setToValue(0),
        easing   = easing,
        finish   = distance,
        callback = translate
    })

    return self
end

function Animation:custom(callback, easing)
    local p = private[self]

    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")
    TypeError:assert(type(callback) == "function", "callback", type(callback), "function")
    
    table.insert(p.steps[p.step], {
        callback = callback
    })

    return self
end

--This method is run to say that all of the previous steps should be
--done together, and the following is a new set of movements. `seconds` defines
--how many seconds the previous step should take.
function Animation:next(seconds)
    local p = private[self] 

    TypeError:assert(type(seconds) == "number", "seconds", type(seconds), "number")
    PositiveError:assert(seconds >= 0, seconds)

    p.steps[p.step].seconds = seconds

    p.step = p.step + 1

    p.steps[p.step] = {}

    return self
end

--To be called after defining all of the moves in an animation. `seconds` defines
--how many seconds the previous step should take.
function Animation:finish(seconds)
    local p = private[self] 

    p.steps[p.step].seconds = seconds

    p.step = 1

    return self
end

function Animation:restart()
    local p = private[self]

    p.time = 0
    p.step = 1

    return self
end

--Starts an animation, playing from whatever step it is currently on.
--Every time the animation reaches a new step (defined by calling `next`
--when building the animation), a "step" event is fired, with the step
--index that just finished. When the animation finishes, a "finished" event is fired. Events
--are async and sync. The speed value is optional, and acts as a multiplier
--to the animations playback speed. A speed of 2 will make the animation
--play twice as fast, and a speed of 0.5 will make it play half as fast.
function Animation:play(speed)
    local p = private[self]

    p.speed   = speed
    p.playing = true

    return self
end

--Reverse the animation track, such that when you begin playing it, it
--starts at the last defined step, and ends at the first.
--TODO: Can we reverse by just doing `-value` from the endpoint of the
--animation? All the basic transformation stuff would work, but how
--would callback work? Do we need an "invert" callback? Should callbacks
--be defined such that going from 0 to -1 is the inverse of going from
--0 to 1? :shrug:
function Animation:reverse()
end

--Create a copy of the animation.
function Animation:clone()
end

--Stops the animation exactly where it is, to be resumed with play at a
--later point.
function Animation:pause()
    private[self].playing = false

    return self
end

--Stops the animation, stepping the animation forward to the start of the
--next step, or backwards towards the start of the previous step, whichever
--is closer. You can force a direction with `direction`.
function Animation:stop(direction)
    local p, step, progress

    p = private[self]

    if not p.playing then return self end

    step = p.steps[p.step]

    p.emit = false
    p.time = direction == "backwards" and 0 or
             direction == "forwards" and 1 or
             p.time <= step.seconds * 0.5 and 0 or 1

    self:update(0)

    p.emit    = true
    p.playing = false

    self:dispatch("animation.stop", p.step)
    self:dispatchSync("animation.stop", p.step)
    
    return self
end

    --======GETTERS======--

function Animation.__get:step()
    return private[self].step
end

    --======SETTERS======--

function Animation.__set:step(value)
    local p = private[self]

    p.emit = false

    while private[self].step ~= value do
        p.time = 1

        self:update(0)
    end

    p.emit = true

    private[self].step = value
    private[self].time = 0
end

    --======METAMETHODS======--

function Animation:__tostring()
    local p = private[self]

    return self:tostring()
end

Animation.__type = "animation"

---@type Animation.Class
local Class = Object:create(Animation, Emitter, Drawable)

return Class