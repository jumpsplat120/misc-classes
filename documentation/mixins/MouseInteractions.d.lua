---@meta MouseInteractions

---Adds mouse related functionality to a class. MouseInteractions has certain requirements to be able to function;
---the class must have a `contains` method that returns a boolean after passing in a [vector](lua://Vector.Class),
---and the class must also mixin [Emitter](lua://Emitter.Mixin). The `contains` method should return `true` whenever
---the vector (mouse position) is "contained" within a shape, for MouseInteractions to function as expected.
---@class MouseInteractions.Mixin
MouseInteractions = {}

---Creates the entries in [private](lua://Classy.private) needed for MouseInteractions to function. Call in it's
---parent class with `MouseInteractions.new(self)`.
function MouseInteractions:new() end

---Hook that must be called within [love.update](lua://love.update). *All* params from the love callback should be
---passed through, as they are used for calculation, then passed through to relevant dispatched events.
---@generic T
---@param self T
---@param dt number Time since the last update in seconds.
---@return T
function MouseInteractions.update(self, dt) end

---Hook that must be called within [love.mousepressed](lua://love.mousepressed). *All* params from the love callback
---should be passed through, as they are used for calculation, then passed through to relevant dispatched events.
---@generic T
---@param self T
---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button, and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
---@return T
function MouseInteractions.mousepressed(self, x, y, button, istouch, presses) end

---Hook that must be called within [love.mousereleased](lua://love.mousereleased). *All* params from the love callback
---should be passed through, as they are used for calculation, then passed through to relevant dispatched events.
---@generic T
---@param self T
---@param x number Mouse x position, in pixels.
---@param y number Mouse y position, in pixels.
---@param button number The button index that was pressed. 1 is the primary mouse button, 2 is the secondary mouse button, and 3 is the middle button. Further buttons are mouse dependent.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@param presses number The number of presses in a short time frame and small area, used to simulate double, triple clicks.
---@return T
function MouseInteractions.mousereleased(self, x, y, button, istouch, presses) end

---Hook that must be called within [love.mousemoved](lua://love.mousemoved). *All* params from the love callback
---should be passed through, as they are used for calculation, then passed through to relevant dispatched events.
---@generic T
---@param self T
---@param x number The mouse position on the x-axis.
---@param y number The mouse position on the y-axis.
---@param dx number The amount moved along the x-axis since the last time love.mousemoved was called.
---@param dy number The amount moved along the y-axis since the last time love.mousemoved was called.
---@param istouch boolean True if the mouse button press originated from a touchscreen touch-press.
---@return T
function MouseInteractions.mousemoved(self, x, y, dx, dy, istouch) end

---Hook that must be called within [love.wheelmoved](lua://love.wheelmoved). *All* params from the love callback
---should be passed through, as they are used for calculation, then passed through to relevant dispatched events.
---@generic T
---@param self T
---@param x number Amount of horizontal mouse wheel movement. Positive values indicate movement to the right.
---@param y number Amount of vertical mouse wheel movement. Positive values indicate upward movement.
---@return self T
function MouseInteractions.wheelmoved(self, x, y) end