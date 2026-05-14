---@meta Game

--The main game class. Game game game.
---@class Game.Class
---@overload fun(id: any): Game
local GameClass = {}

---Game game game.
---@class Game : Classy.Object, Emitter.Mixin
---@field size number
---@field keys number
---@field time number
---@field width number
---@field debug number
---@field mouse number
---@field height number
---@field loaded number
local Game = {}

function GameClass:new() end

function Game:load() end

function Game:lowmemory() end

function Game:draw() end

function Game:quit() end

function Game:threaderror(thread, error_str) end

function Game:update(dt) end

function Game:directorydropped(path) end

function Game:displayrotated(index, orientation) end

function Game:filedropped(file) end

function Game:focus(focus) end

function Game:mousefocus(focus) end

function Game:resize(width, height) end

function Game:visible(visible) end

function Game:keypressed(key, scancode, is_repeat) end

function Game:keyreleased(key, scancode) end

function Game:textedited(text, start, length) end

function Game:textinput(text) end

function Game:mousemoved(x, y, dx, dy, touchscreen) end

function Game:mousepressed(x, y, button, touchscreen, presses) end

function Game:mousereleased(x, y, button, touchscreen, presses) end

function Game:wheelmoved(x, y) end

function Game:gamepadaxis(joystick, axis, value) end

function Game:gamepadpressed(joystick, button) end

function Game:gamepadreleased(joystick, button) end

function Game:joystickadded(joystick) end

function Game:joystickaxis(joystick, button) end

function Game:joystickhat(joystick, hat, direction) end

function Game:joystickpressed(joystick, button) end

function Game:joystickreleased(joystick, button) end

function Game:joystickremoved(joystick) end

function Game:touchmoved(id, x, y, dx, dy, pressure) end

function Game:touchpressed(id, x, y, dx, dy, pressure) end

function Game:touchreleased(id, x, y, dx, dy, pressure) end