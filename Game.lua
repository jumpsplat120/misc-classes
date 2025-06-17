local Game, Object, Symbol, private
local Vector, Date
local Emitter

Symbol  = require("lib.Classy.Symbol")
Object  = require("lib.Classy")
private = require("lib.Classy.instances")

Vector = require("classes.Vector")
Date   = require("classes.Date")

Emitter = require("classes.mixins.Emitter")

Game = Object:extend()

Game:implement(Emitter)

    --======PRIVATE FUNCTIONS======--

local singleton
local UNKNOWN, LANDSCAPE, FLIPPED_LANDSCAPE, PORTRAIT, FLIPPED_PORTRAIT
local BORDERLESS, EXCLUSIVE

FLIPPED_LANDSCAPE = Symbol("flipped_landscape")
FLIPPED_PORTRAIT  = Symbol("flipped_portrait")
LANDSCAPE = Symbol("landscape")
PORTRAIT  = Symbol("portrait")
UNKNOWN   = Symbol("unknown")

BORDERLESS = Symbol("borderless")
EXCLUSIVE  = Symbol("exculsive")

private[Game] = {
    orientation = {
        [FLIPPED_LANDSCAPE] = true,
        [FLIPPED_PORTRAIT]  = true,
        [LANDSCAPE] = true,
        [PORTRAIT]  = true,
        [UNKNOWN]   = true
    },
    fullscreen = {
        [BORDERLESS] = true,
        [EXCLUSIVE]  = true
    }
}

    --======CONSTRUCTOR======--

function Game:new()
    local p, window
    
    p = private[self]

    if singleton then return singleton end

    singleton = self
    
    p.last_3_frames  = {
        0, 0, 0
    }

    p.last_10_frames = { 
        0, 0, 0, 0, 0,
        0, 0, 0, 0, 0
    }

    p.last_30_frames = { 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    }

    p.last_60_frames = { 
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    }

    window = love.window and { love.window.getMode() } or { 0, 0, { } }

    p.window = {
        fullscreen = {
            state = window[3].fullscreen,
            type  = window[3].type == "desktop" and BORDERLESS or EXCLUSIVE
        },
        refresh_hz = window[3].refreshrate,
        resizeable = window[3].resizeable,
        borderless = window[3].borderless,
        min_size   = Vector:fromValues(window[3].minwidth or 0, window[3].minheight or 0),
        position   = Vector:fromValues(window[3].x or 0, window[3].y or 0),
        centered   = window[3].centered,
        display    = window[3].display,
        visible    = false,
        focused    = false,
        highdpi    = window[3].highdpi,
        vsync      = window[3].vsync == 1,
        msaa       = window[3].msaa,
        size       = Vector:fromValues(window[1], window[2])
    }

    p.mouse = {
        focused = false,
        position = Vector:fromValues(0, 0),
        buttons = {}
    }
    

    p.displays = { }
    p.keys     = { }
    
    p.loaded = false
    p.debug  = false

    p.started = Date:now()
end

    --======METHODS======--

function Game:load()
    local p = private[self]

    if not p.loadrunning then
        p.loadrunning = true

        self:dispatchSync("load.begin", self)
        self:dispatch("load.begin", self)

        return self
    end

    p.loadrunning = nil

    self:dispatchSync("load.end", self)
    self:dispatch("load.end", self)

    p.loaded = true
end

function Game:lowmemory()
    local p = private[self]

    if not p.lowmemoryrunning then
        p.lowmemoryrunning = true

        self:dispatchSync("lowmemory.begin", self)
        self:dispatch("lowmemory.begin", self)

        return self
    end

    p.lowmemory = nil
    
    self:dispatchSync("lowmemory.end", self)
    self:dispatch("lowmemory.end", self)
end

function Game:draw()
    local p = private[self]

    if not p.drawrunning then
        p.drawrunning = true
        
        self:dispatchSync("draw.begin", self)

        return self
    end

    p.drawrunning = nil
    
    self:dispatchSync("draw.end", self)
end

function Game:quit()
    self:dispatchSync("quit.begin", self)
end

function Game:threaderror(thread, error_str)
    local p = private[self]

    if not p.threaderrorrunning then
        p.threaderrorrunning = true

        self:dispatchSync("threaderror.begin", thread, error_str)
        self:dispatch("threaderror.begin", thread, error_str)

        return self
    end

    p.threaderrorrunning = nil
    
    self:dispatchSync("threaderror.end", thread, error_str)
    self:dispatch("threaderror.end", thread, error_str)
end

function Game:update(dt)
    local p = private[self]
    
    if debug then
        table.remove(p.last_3_frames,  1)
        table.remove(p.last_10_frames, 1)
        table.remove(p.last_30_frames, 1)
        table.remove(p.last_60_frames, 1)

        p.last_3_frames[#p.last_3_frames   + 1] = dt
        p.last_10_frames[#p.last_10_frames + 1] = dt
        p.last_30_frames[#p.last_30_frames + 1] = dt
        p.last_60_frames[#p.last_60_frames + 1] = dt
    end

    if not p.updaterunning then
        p.updaterunning = true

        self:dispatchSync("update.begin", dt)

        return self
    end

    p.updaterunning = nil
    
    self:dispatchSync("update.end", dt)
end

function Game:directorydropped(path)
    local p = private[self]

    if not p.directorydroppedrunning then
        p.directorydroppedrunning = true

        self:dispatchSync("directorydropped.begin", path)
        self:dispatch("directorydropped.begin", path)

        return self
    end

    p.directorydroppedrunning = nil
    
    self:dispatchSync("directorydropped.end", path)
    self:dispatch("directorydropped.end", path)
end

function Game:displayrotated(index, orientation)
    local p = private[self]

    if orientation == "landscapeflipped" then p.displays[index] = FLIPPED_LANDSCAPE end
    if orientation == "portraitflipped"  then p.displays[index] = FLIPPED_PORTRAIT  end
    if orientation == "landscape" then p.displays[index] = LANDSCAPE end
    if orientation == "portrait"  then p.displays[index] = PORTRAIT  end
    if orientation == "unknown"   then p.displays[index] = UNKNOWN   end

    if not p.displayrotatedrunning then
        p.displayrotatedrunning = true

        self:dispatchSync("displayrotated.begin", index, orientation)
        self:dispatch("displayrotated.begin", index, orientation)

        return self
    end

    p.displayrotatedrunning = nil
    
    self:dispatchSync("displayrotated.end", index, orientation)
    self:dispatch("displayrotated.end", index, orientation)
end

function Game:filedropped(file)
    local p = private[self]

    if not p.filedroppedrunning then
        p.filedroppedrunning = true

        self:dispatchSync("filedropped.begin", file)
        self:dispatch("filedropped.begin", file)

        return self
    end

    p.filedroppedrunning = nil
    
    self:dispatchSync("filedropped.end", file)
    self:dispatch("filedropped.end", file)
end

function Game:focus(focus)
    local p = private[self]

    p.window.focused = focus

    if not p.focusrunning then
        p.focusrunning = true

        self:dispatchSync("focus.begin", focus)
        self:dispatch("focus.begin", focus)

        return self
    end

    p.focusrunning = nil
    
    self:dispatchSync("focus.end", focus)
    self:dispatch("focus.end", focus)
end

function Game:mousefocus(focus)
    local p = private[self]

    p.mouse.focused = focus

    if not p.mousefocusrunning then
        p.mousefocusrunning = true

        self:dispatchSync("mousefocus.begin", focus)
        self:dispatch("mousefocus.begin", focus)

        return self
    end

    p.mousefocusrunning = nil
    
    self:dispatchSync("mousefocus.end", focus)
    self:dispatch("mousefocus.end", focus)
end

function Game:resize(width, height)
    local p = private[self]
    
    p.window.size:setToValues(width, height)

    if not p.resizerunning then
        p.resizerunning = true

        self:dispatchSync("resize.begin", width, height)
        self:dispatch("resize.begin", width, height)

        return self
    end

    p.resizerunning = nil
    
    self:dispatchSync("resize.end", width, height)
    self:dispatch("resize.end", width, height)
end

function Game:visible(visible)
    local p = private[self]

    p.window.visible = visible

    if not p.visiblerunning then
        p.visiblerunning = true

        self:dispatchSync("visible.begin", visible)
        self:dispatch("visible.begin", visible)

        return self
    end

    p.visiblerunning = nil
    
    self:dispatchSync("visible.end", visible)
    self:dispatch("visible.end", visible)
end

function Game:keypressed(key, scancode, is_repeat)
    local p = private[self]

    if p.keys[scancode] then
        p.keys[scancode].is_repeat = is_repeat
    else
        p.keys[scancode] = {
            is_repeat = is_repeat,
            key       = key,
            when      = Date:now()
        }
    end

    if not p.keypressedrunning then
        p.keypressedrunning = true

        self:dispatchSync("keypressed.begin", key, scancode, is_repeat)
        self:dispatch("keypressed.begin", key, scancode, is_repeat)

        return self
    end

    p.keypressedrunning = nil
    
    self:dispatchSync("keypressed.end", key, scancode, is_repeat)
    self:dispatch("keypressed.end", key, scancode, is_repeat)
end

function Game:keyreleased(key, scancode)
    local p = private[self]

    p.keys[scancode] = nil

    if not p.keyreleasedrunning then
        p.keyreleasedrunning = true

        self:dispatchSync("keyreleased.begin", key, scancode)
        self:dispatch("keyreleased.begin", key, scancode)

        return self
    end

    p.keyreleasedrunning = nil
    
    self:dispatchSync("keyreleased.end", key, scancode)
    self:dispatch("keyreleased.end", key, scancode)
end

function Game:textedited(text, start, length)
    local p = private[self]

    if not p.texteditedrunning then
        p.texteditedrunning = true

        self:dispatchSync("textedited.begin", text, start, length)
        self:dispatch("textedited.begin", text, start, length)

        return self
    end

    p.texteditedrunning = nil
    
    self:dispatchSync("textedited.end", text, start, length)
    self:dispatch("textedited.end", text, start, length)
end

function Game:textinput(text)
    local p = private[self]

    if not p.textinputrunning then
        p.textinputrunning = true

        self:dispatchSync("textinput.begin", text)
        self:dispatch("textinput.begin", text)

        return self
    end

    p.textinputrunning = nil
    
    self:dispatchSync("textinput.end", text)
    self:dispatch("textinput.end", text)
end

function Game:mousemoved(x, y, dx, dy, touchscreen)
    local p = private[self]

    p.mouse.position:setToValues(x, y)

    if not p.mousemovedrunning then
        p.mousemovedrunning = true

        self:dispatchSync("mousemoved.begin", x, y, dx, dy, touchscreen)
        self:dispatch("mousemoved.begin", x, y, dx, dy, touchscreen)

        return self
    end

    p.mousemovedrunning = nil
    
    self:dispatchSync("mousemoved.end", x, y, dx, dy, touchscreen)
    self:dispatch("mousemoved.end", x, y, dx, dy, touchscreen)
end

function Game:mousepressed(x, y, button, touchscreen, presses)
    local p = private[self]

    p.mouse.buttons[button] = {
        position = Vector:fromValues(x, y),
        presses  = presses
    }

    if not p.mousepressedrunning then
        p.mousepressedrunning = true

        self:dispatchSync("mousepressed.begin", x, y, button, touchscreen, presses)
        self:dispatch("mousepressed.begin", x, y, button, touchscreen, presses)

        return self
    end

    p.mousepressedrunning = nil
    
    self:dispatchSync("mousepressed.end", x, y, button, touchscreen, presses)
    self:dispatch("mousepressed.end", x, y, button, touchscreen, presses)
end

function Game:mousereleased(x, y, button, touchscreen, presses)
    local p = private[self]

    p.mouse.buttons[button] = nil

    if not p.mousereleasedrunning then
        p.mousereleasedrunning = true

        self:dispatchSync("mousereleased.begin", x, y, button, touchscreen, presses)
        self:dispatch("mousereleased.begin", x, y, button, touchscreen, presses)

        return self
    end

    p.mousereleasedrunning = nil
    
    self:dispatchSync("mousereleased.end", x, y, button, touchscreen, presses)
    self:dispatch("mousereleased.end", x, y, button, touchscreen, presses)
end

function Game:wheelmoved(x, y)
    local p = private[self]

    if not p.wheelmovedrunning then
        p.wheelmovedrunning = true

        self:dispatchSync("wheelmoved.begin", x, y)
        self:dispatch("wheelmoved.begin", x, y)

        return self
    end

    p.wheelmovedrunning = nil
    
    self:dispatchSync("wheelmoved.end", x, y)
    self:dispatch("wheelmoved.end", x, y)
end

--TODO: All the tracking for gamepad, joystick and touchscreen
function Game:gamepadaxis(joystick, axis, value)
    local p = private[self]

    if not p.gamepadaxisrunning then
        p.gamepadaxisrunning = true

        self:dispatchSync("gamepadaxis.begin", joystick, axis, value)
        self:dispatch("gamepadaxis.begin", joystick, axis, value)

        return self
    end

    p.gamepadaxisrunning = nil
    
    self:dispatchSync("gamepadaxis.end", joystick, axis, value)
    self:dispatch("gamepadaxis.end", joystick, axis, value)
end

function Game:gamepadpressed(joystick, button)
    local p = private[self]

    if not p.gamepadpressedrunning then
        p.gamepadpressedrunning = true

        self:dispatchSync("gamepadpressed.begin", joystick, button)
        self:dispatch("gamepadpressed.begin", joystick, button)

        return self
    end

    p.gamepadpressedrunning = nil
    
    self:dispatchSync("gamepadpressed.end", joystick, button)
    self:dispatch("gamepadpressed.end", joystick, button)
end

function Game:gamepadreleased(joystick, button)
    local p = private[self]

    if not p.gamepadreleasedrunning then
        p.gamepadreleasedrunning = true

        self:dispatchSync("gamepadreleased.begin", joystick, button)
        self:dispatch("gamepadreleased.begin", joystick, button)

        return self
    end

    p.gamepadreleasedrunning = nil
    
    self:dispatchSync("gamepadreleased.end", joystick, button)
    self:dispatch("gamepadreleased.end", joystick, button)
end

function Game:joystickadded(joystick)
    local p = private[self]

    if not p.joystickaddedrunning then
        p.joystickaddedrunning = true

        self:dispatchSync("joystickadded.begin", joystick)
        self:dispatch("joystickadded.begin", joystick)

        return self
    end

    p.joystickaddedrunning = nil
    
    self:dispatchSync("joystickadded.end", joystick)
    self:dispatch("joystickadded.end", joystick)
end

function Game:joystickaxis(joystick, button)
    local p = private[self]

    if not p.joystickaxisrunning then
        p.joystickaxisrunning = true

        self:dispatchSync("joystickaxis.begin", joystick, button)
        self:dispatch("joystickaxis.begin", joystick, button)

        return self
    end

    p.joystickaxisrunning = nil
    
    self:dispatchSync("joystickaxis.end", joystick, button)
    self:dispatch("joystickaxis.end", joystick, button)
end

function Game:joystickhat(joystick, hat, direction)
    local p = private[self]

    if not p.joystickhatrunning then
        p.joystickhatrunning = true

        self:dispatchSync("joystickhat.begin", joystick, hat, direction)
        self:dispatch("joystickhat.begin", joystick, hat, direction)

        return self
    end

    p.joystickhatrunning = nil
    
    self:dispatchSync("joystickhat.end", joystick, hat, direction)
    self:dispatch("joystickhat.end", joystick, hat, direction)
end

function Game:joystickpressed(joystick, button)
    local p = private[self]

    if not p.joystickpressedrunning then
        p.joystickpressedrunning = true

        self:dispatchSync("joystickpressed.begin", joystick, button)
        self:dispatch("joystickpressed.begin", joystick, button)

        return self
    end

    p.joystickhatrunning = nil
    
    self:dispatchSync("joystickpressed.end", joystick, button)
    self:dispatch("joystickpressed.end", joystick, button)
end

function Game:joystickreleased(joystick, button)
    local p = private[self]

    if not p.joystickreleasedrunning then
        p.joystickreleasedrunning = true

        self:dispatchSync("joystickreleased.begin", joystick, button)
        self:dispatch("joystickreleased.begin", joystick, button)

        return self
    end

    p.joystickreleasedrunning = nil
    
    self:dispatchSync("joystickreleased.end", joystick, button)
    self:dispatch("joystickreleased.end", joystick, button)
end

function Game:joystickremoved(joystick)
    local p = private[self]

    if not p.joystickremovedrunning then
        p.joystickremovedrunning = true

        self:dispatchSync("joystickremoved.begin", joystick)
        self:dispatch("joystickremoved.begin", joystick)

        return self
    end

    p.joystickremovedrunning = nil
    
    self:dispatchSync("joystickremoved.end", joystick)
    self:dispatch("joystickremoved.end", joystick)
end

function Game:touchmoved(id, x, y, dx, dy, pressure)
    local p = private[self]

    if not p.touchmovedrunning then
        p.touchmovedrunning = true

        self:dispatchSync("touchmoved.begin", id, x, y, dx, dy, pressure)
        self:dispatch("touchmoved.begin", id, x, y, dx, dy, pressure)

        return self
    end

    p.touchmovedrunning = nil
    
    self:dispatchSync("touchmoved.end", id, x, y, dx, dy, pressure)
    self:dispatch("touchmoved.end", id, x, y, dx, dy, pressure)
end

function Game:touchpressed(id, x, y, dx, dy, pressure)
    local p = private[self]

    if not p.touchpressedrunning then
        p.touchpressedrunning = true

        self:dispatchSync("touchpressed.begin", id, x, y, dx, dy, pressure)
        self:dispatch("touchpressed.begin", id, x, y, dx, dy, pressure)

        return self
    end

    p.touchpressedrunning = nil
    
    self:dispatchSync("touchpressed.end", id, x, y, dx, dy, pressure)
    self:dispatch("touchpressed.end", id, x, y, dx, dy, pressure)
end

function Game:touchreleased(id, x, y, dx, dy, pressure)
    local p = private[self]

    if not p.touchreleasedrunning then
        p.touchreleasedrunning = true

        self:dispatchSync("touchreleased.begin", id, x, y, dx, dy, pressure)
        self:dispatch("touchreleased.begin", id, x, y, dx, dy, pressure)

        return self
    end

    p.touchreleasedrunning = nil
    
    self:dispatchSync("touchreleased.end", id, x, y, dx, dy, pressure)
    self:dispatch("touchreleased.end", id, x, y, dx, dy, pressure)
end
    
    --======GETTERS======--

function Game.__get:debug()
    return private[self].debug
end

function Game.__get:loaded()
    return private[self].loaded
end

function Game.__get:running_for()
    return private[self].started:secondsUntil(Date:now())
end

function Game.__get:keys()
    local result = { }

    for scancode, tbl in pairs(private[self].keys) do
        result[scancode] = {
            is_repeat = tbl.is_repeat,
            key       = tbl.key,
            held_for  = tbl.when:secondsUntil(Date:now())
        }
    end

    return result
end

function Game.__get:width()
    return private[self].window.size.x
end

function Game.__get:height()
    return private[self].window.size.y
end

function Game.__get:size()
    return private[self].window.size
end

--TODO: Make it it's own class with it's own getters? Maybe?
--Something to prevent people from screwing with the internal table it currently exposes
function Game.__get:mouse()
    return private[self].mouse
end

--TODO: All the rest of the getters and setters

    --======SETTERS======--

function Game.__set:debug(value)
    private[self].debug = not not value
end

    --======METAMETHODS======--

function Game:__tostring()
    if self.is_instance then return self:tostringHelper("Singleton") end

    return self:tostringHelper("Class")
end

Game.__type = "game"

return Game