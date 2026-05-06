---@meta Game

---@class Game.Class : Classy.Object, Emitter.Mixin
Game = {}

function Game:new() end

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

function Game.__get:debug()
function Game.__get:loaded()
function Game.__get:running_for()
function Game.__get:keys()
function Game.__get:width()
function Game.__get:height()
function Game.__get:size()
function Game.__get:mouse()