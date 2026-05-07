local Object, private
local Animation
local Emitter, Drawable

Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Emitter  = require("classes.mixins.Emitter")
Drawable = require("classes.mixins.Drawable")

Animation = Object:init()

    --======PRIVATE FUNCTIONS======--

local easings, pow, sqrt, sin, cos, pi
local c1, c2, c3, c4, c5, n1, d1

sqrt = math.sqrt
pow  = math.pow
sin  = math.sin
cos  = math.cos
pi   = math.pi
c1   = 1.70158
c2   = c1 * 1.525
c3   = c1 + 1
c4   = 2 * pi / 3
c5   = 2 * pi / 4.5
n1   = 7.5625
d1   = 2.75

easings = {
    linear = function(x)
        return x
    end,
    quadIn = function(x)
        return x * x
    end,
    quadOut = function(x)
        local minus = 1 - x

        return 1 - minus * minus
    end,
    quadInOut = function(x)
        if x < 0.5 then
            return 2 * x * x
        end

        return 1 - pow(-2 * x + 2, 2) / 2
    end,
    cubicIn = function(x)
        return x * x * x
    end,
    cubicOut = function(x)
        return 1 - pow(1 - x, 3)
    end,
    cubicInOut = function(x)
        if x < 0.5 then
            return 4 * x * x * x
        end

        return 1 - pow(-2 * x + 2, 3) / 2
    end,
    quartIn = function(x)
        return x * x * x * x
    end,
    quartOut = function(x)
        return 1 - pow(1 - x, 4)
    end,
    quartInOut = function(x)
        if x < 0.5 then
            return 8 * x * x * x * x
        end

        return 1 - pow(-2 * x + 2, 4) / 2
    end,
    quintIn = function(x)
        return x * x * x * x * x
    end,
    quintOut = function(x)
        return 1 - pow(1 - x, 5)
    end,
    quintInOut = function(x)
        if x < 0.5 then
            return 16 * x * x * x * x * x
        end

        return 1 - pow(-2 * x + 2, 5) / 2
    end,
    sineIn = function(x)
        return 1 - cos((x * pi) / 2)
    end,
    sineOut = function(x)
        return sin((x * pi) / 2);
    end,
    sineInOut = function(x)
        return -(cos(pi * x) - 1) / 2
    end,
    expoIn = function(x)
        if x == 0 then return 0 end

        return pow(2, 10 * x - 10)
    end,
    expoOut = function(x)
        if x == 1 then return 1 end

        return 1 - pow(2, -10 * x)
    end,
    expoInOut = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end
        
        if x < 0.5 then
            return pow(2, 20 * x - 10) / 2
        end

        return (2 - pow(2, -20 * x + 10)) / 2
    end,
    circIn = function(x)
        return 1 - sqrt(1 - pow(x, 2))
    end,
    circOut = function(x)
        return sqrt(1 - pow(x - 1, 2))
    end,
    circInOut = function(x)
        if x < 0.5 then
            return (1 - sqrt(1 - pow(2 * x, 2))) / 2
        end

        return (sqrt(1 - pow(-2 * x + 2, 2)) + 1) / 2
    end,
    backIn = function(x)
        return c3 * x * x * x - c1 * x * x
    end,
    backOut = function(x)
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    end,
    backInOut = function(x)
        if x < 0.5 then
            return (pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
        end

        return (pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
    end,
    elasticIn = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end

        return -pow(2, 10 * x - 10) * sin((x * 10 - 10.75) * c4)
    end,
    elasticOut = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end

        return pow(2, -10 * x) * sin((x * 10 - 0.75) * c4) + 1
    end,
    elasticInOut = function(x)
        if x == 0 then return 0 end
        if x == 1 then return 1 end

        if x < 0.5 then
            return -(pow(2, 20 * x - 10) * sin((20 * x - 11.125) * c5)) / 2
        end

        return (pow(2, -20 * x + 10) * sin((20 * x - 11.125) * c5)) / 2 + 1
    end,
    bounceIn = function(x)
        return 1 - easings.bounceOut(1 - x)
    end,
    bounceOut = function(x)
        if x < 1 / d1 then
            return n1 * x * x
        end

        if x < 2 / d1 then
            x = x - 1.5

            return n1 * (x / d1) * x + 0.75
        end

        if x < 2.5 / d1 then
            x = x - 2.25

            return n1 * (x / d1) * x + 0.9375
        end

        x = x - 2.625

        return n1 * (x / d1) * x + 0.984375
        
    end,
    bounceInOut = function(x)
        if x < 0.5 then
            return (1 - easings.bounceOut(1 - 2 * x)) / 2
        end

        return (1 + easings.bounceOut(2 * x - 1)) / 2
    end
}

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
    local p, adjust
    
    p = private[self]

    if not p.playing then return end

    p.time = p.time + dt * p.speed
    
    for i, v in ipairs(p.steps[p.step]) do
        if p.time >= p.steps[p.step].seconds then
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
            
            --On the final "frame" of an animation, we need to see how much more distance
            --we need to move to fully reach v.value. If not, we will always be a smidge
            --off, since we stop before that final movement. However, we also can't stop
            --one frame after, since we will overshoot by a smidge. We don't typecheck
            --here because we'd need to clone v.value anyways, if it's a vector.
            p.transform[v.type](p.transform, v.value - v.current)
            
            break
        end
        
        --TODO: If an animation is reset in the middle of running, how can we automatically
        --have it restart from zero? Do we need to track the changes made during the animation
        --and do them backwards? Or do we keep track of the state of the original transform
        --actually it's probably that one. Clone it on creation, when reset, just set the
        --transform back to that.
        adjust = v.value * easings[v.easing](dt * p.speed / p.steps[p.step].seconds)
        
        --While vectors do have overloads, and we can just use v.current + adjust to
        --include numbers and vectors alike, by checking first we can avoid having to
        --create a new vector every update frame.
        if type(v.current) == "vector" then
            v.current:add(adjust)
        else
            v.current = v.current + adjust
        end
        
        p.transform[v.type](p.transform, adjust)
    end
end

--Translate `distance`, optionally with some sort of
--easing. `distance` is not the endpoint, but how far the thing needs to travel.
--So if `distance` is 5, 5, then if the transform is 0, 0, it ends at 5, 5, but
--if the transform is 15, 17, then it ends at 20, 22.
function Animation:translate(distance, easing)
    local p = private[self]

    table.insert(p.steps[p.step], {
        type = "translate",
        value = distance,
        current = distance:clone():setToValue(0),
        easing = easing or "linear"
    })

    return self
end

function Animation:rotate(angle, easing)
    local p = private[self]

    table.insert(p.steps[p.step], {
        type = "rotate",
        value = angle,
        current = 0,
        easing = easing or "linear"
    })

    return self
end

function Animation:scale(size, easing)
    local p = private[self]

    table.insert(p.steps[p.step], {
        type = "scale",
        value = size,
        current = size:clone():setToValue(0),
        easing = easing or "linear"
    })

    return self
end

function Animation:shear(skew, easing)
    local p = private[self]

    table.insert(p.steps[p.step], {
        type = "shear",
        value = skew,
        current = size:clone():setToValue(0),
        easing = easing or "linear"
    })

    return self
end

function Animation:custom(callback, easing)
end

--This method is run to say that all of the previous steps should be
--done together, and the following is a new set of movements. `seconds` defines
--how many seconds the previous step should take.
function Animation:next(seconds)
    local p = private[self] 

    p.steps[p.step].seconds = seconds
    p.step = p.step + 1

    p.steps[p.step] = {}

    return self
end

--To be called after defining all of the moves in an animation. `seconds` defines
--how many seconds the previous step should take.
function Animation:finish(seconds)
    local p = private[self] 

    --Run through all the steps, cache the endpoints, so that stop will jump to
    --the appropriate locations, and so we can reverse.
    p.steps[p.step].seconds = seconds

    p.step = 1
end

--Reset the state of the animation, such that the transform is set
--back to it's original position, and that the step is set back to 1.
function Animation:reset()
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
function Animation:reverse()
end

--Create a copy of the animation.
function Animation:clone()
end

--Resets the animation progress.
function Animation:reset()
    local p = private[self]

    p.step = 1
    p.time = 0

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