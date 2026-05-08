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

    --======CONSTRUCTOR======--

--Assumes that the transform is identity. So a `rotate(math.pi)` is a half turn, not a
--turn from 0 to math.pi.
function Animation:new(transform)
    local p = private[self]

    Emitter.new(self)

    p.time      = 0
    p.copy      = transform:clone()
    p.transform = transform

    p.step  = 1
    p.steps = { {} }
end

    --======METHODS======--

function Animation:update(dt)
    local p, step, adjust
    
    p = private[self]

    if not p.playing then return end

    step = p.steps[p.step]

    p.time = p.time + dt * p.speed
    
    for i, v in ipairs(step) do        
        if p.time >= step.seconds then
            if p.step == #p.steps then
                self:dispatch("animation.finish")
                self:dispatchSync("animation.finish")
               
                p.playing = false
            else
                self:dispatch("animation.step", p.step)
                self:dispatchSync("animation.step", p.step)
                
                p.step = p.step + 1
            end

            p.time = 0
            
            if v.type == "custom" then
                v.callback(p.transform, 1, dt, p.speed, step.seconds)
            else
                --On the final "frame" of an animation, we need to see how much more distance
                --we need to move to fully reach v.value. If not, we will always be a smidge
                --off, since we stop before that final movement. However, we also can't stop
                --one frame after, since we will overshoot by a smidge. We don't typecheck
                --here because we'd need to clone v.value anyways, if it's a vector.
                p.transform[v.type](p.transform, v.value - v.current)

                if type(v.current) == "vector" then
                    v.current = v.inital:clone()
                else
                    v.current = v.inital
                end
            end
            
            break
        end

        if v.type == "custom" then
            v.callback(p.transform, v.easing(p.time / step.seconds), dt, p.speed, step.seconds)
        else
            p.transform[v.type](p.transform, v.value * v.easing(p.time / step.seconds) - v.current)
            
            --While vectors do have overloads, and we *can* just use v.current + adjust to
            --include numbers and vectors alike, by checking first we can avoid having to
            --create a new vector every update frame.
            if type(v.current) == "vector" then
                v.current:setToVector(v.value * v.easing(p.time / step.seconds))
            else
                v.current = v.value * v.easing(p.time / step.seconds)
            end
        end
    end
end

--Translate `distance`, optionally with some sort of
--easing. `distance` is not the endpoint, but how far the thing needs to travel.
--So if `distance` is 5, 5, then if the transform is 0, 0, it ends at 5, 5, but
--if the transform is 15, 17, then it ends at 20, 22.
function Animation:translate(distance, easing)
    local p = private[self]

    easing = easing or Easings:linear()

    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")
    TypeError:assert(type(distance) == "vector", "distance", type(distance), "vector")
    VectorSizeError:assert(distance.size == 2, distance.size, 2)

    table.insert(p.steps[p.step], {
        type    = "translate",
        value   = distance,
        easing  = easing,
        inital  = distance:clone():setToValue(0),
        current = distance:clone():setToValue(0),
    })

    return self
end

function Animation:rotate(angle, easing)
    local p = private[self]

    easing = easing or Easings:linear()
    
    TypeError:assert(type(angle) == "number", "angle", type(angle), "number")
    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")

    table.insert(p.steps[p.step], {
        type    = "rotate",
        value   = angle,
        easing  = easing,
        inital  = 0,
        current = 0
    })

    return self
end

function Animation:scale(size, easing)
    local p = private[self]

    easing = easing or Easings:linear()

    TypeError:assert(type(size) == "vector", "size", type(size), "vector")
    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")
    VectorSizeError:assert(size.size == 2, size.size, 2)

    table.insert(p.steps[p.step], {
        type    = "scale",
        value   = size,
        easing  = easing,
        inital  = size:clone():setToValue(1),
        current = size:clone():setToValue(1)
    })

    return self
end

function Animation:shear(skew, easing)
    local p = private[self]

    easing = easing or Easings:linear()

    TypeError:assert(type(skew) == "vector", "skew", type(skew), "vector")
    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")
    VectorSizeError:assert(skew.size == 2, skew.size, 2)

    table.insert(p.steps[p.step], {
        type    = "shear",
        value   = skew,
        easing  = easing,
        inital  = size:clone():setToValue(0),
        current = size:clone():setToValue(0)
    })

    return self
end

function Animation:custom(callback, easing)
    local p = private[self]

    easing = easing or Easings:linear()

    TypeError:assert(type(easing) == "easing", "easing", type(easing), "easing")
    TypeError:assert(type(callback) == "function", "callback", type(callback), "function")

    table.insert(p.steps[p.step], {
        type     = "custom",
        easing   = easing,
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

    --Add `seconds` value so we have a reference of how long each step of the animation
    --should take.
    p.steps[p.step].seconds = seconds

    --Then, increase step index, and create a new table to add more operations to.
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
end

function Animation:restart()
    private[self].step = 1

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

    p.speed = speed
    p.playing = true
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

--Resets the animation progress.
function Animation:reset(transform)
    local p = private[self]

    p.step = 1
    p.time = 0

    p.transform.matrix = transform.matrix or p.copy.matrix
    
    return self
end

--Stops the animation exactly where it is, to be resumed with play at a
--later point.
function Animation:pause()
end

--Stops the animation, stepping the animation forward to the start of the
--next step, or backwards towards the start of the previous step, whichever
--is closer.
function Animation:stop()
end

    --======GETTERS======--
    
    --======SETTERS======--
    
    --======METAMETHODS======--

function Animation:__tostring()
    local p = private[self]

    return self:tostring()
end

Animation.__type = "animation"

---@type Animation.Class
local Class = Object:create(Animation, Emitter, Drawable)

return Class