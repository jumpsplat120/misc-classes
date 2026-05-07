---@meta Emitter

---A mixin that adds emits events on objects, which can be listened to. Uses [Async](lua://Async.Class) internally
---to allow for asyncronous events.
---@class Emitter.Mixin
Emitter = {}

---Creates the entries in [private](lua://Classy.private) needed for Emitter to function. Call in it's parent class
---with `Emitter.new(self)`.
function Emitter:new() end

---Asyncronously listen to an event, and run the callback whenever it fires. All of the varargs will be passed to
---the callback after a reference to `self`, and before any args passed by [Emitter:dispatch()](lua://Emitter.dispatch).
---
---Note that Async listeners can only run if [love.update](lua://love.update) will fire at least once after the dispatch
---has been called. For example, `object:dispatch("love.quit")` won't run `object:on("love.quit")` since `love.update`
---doesn't run after [love.quit](lua://love.quit) has fired. If you need such a usescase, use a syncronous listener.
---@generic T
---@param self T
---@param event string The name of the event. Events are case sensitive.
---@param callback function The callback function. The args will change, but will always contain at least a reference to the object emitting the event.
---@param ... any These args will be passed to the callback after the reference to `self`.
---@return T
function Emitter.on(self, event, callback, ...) end

---Asyncronously listen to an event, and run the callback only the first time it fires. All of the varargs will be
---passed to the callback after a reference to `self`, and before any args passed by
---[Emitter:dispatch()](lua://Emitter.dispatch).
---
---Note that Async listeners can only run if [love.update](lua://love.update) will fire at least once after the dispatch
---has been called. For example, `object:dispatch("love.quit")` won't run `object:on("love.quit")` since `love.update`
---doesn't run after [love.quit](lua://love.quit) has fired. If you need such a usescase, use a syncronous listener.
---@generic T
---@param self T
---@param event string The name of the event. Events are case sensitive.
---@param callback function The callback function. The args will change, but will always contain at least a reference to the object emitting the event.
---@param ... any These args will be passed to the callback after the reference to `self`.
---@return T
function Emitter.once(self, event, callback, ...) end

---Syncronously listen to an event, and run the callback whenever it fires. All of the varargs will be passed to
---the callback after a reference to `self`, and before any args passed by
---[Emitter:dispatchSync()](lua://Emitter.dispatchSync).
---@generic T
---@param self T
---@param event string The name of the event. Events are case sensitive.
---@param callback function The callback function. The args will change, but will always contain at least a reference to the object emitting the event.
---@param ... any These args will be passed to the callback after the reference to `self`.
---@return T
function Emitter.onSync(self, event, callback, ...) end

---Syncronously listen to an event, and run the callback only the first time it fires. All of the varargs will be
---passed to the callback after a reference to `self`, and before any args passed by
---[Emitter:dispatchSync()](lua://Emitter.dispatchSync).
---@generic T
---@param self T
---@param event string The name of the event. Events are case sensitive.
---@param callback function The callback function. The args will change, but will always contain at least a reference to the object emitting the event.
---@param ... any These args will be passed to the callback after the reference to `self`.
---@return T
function Emitter.onceSync(self, event, callback, ...) end

---Dispatch an asyncronous event. All listeners that have been defined *before* this method runs will be triggered on
---the next run of [love.update](lua://love.update).
---@generic T
---@param self T
---@param event string The name of the event. Events are case sensitive.
---@param ... any These args will be passed to the callback after the reference to `self` and the args defined in the listener.
---@return T
function Emitter.dispatch(self, event, ...) end

---Dispatch an syncronous event. All listeners that have been defined *before* this method runs will be triggered
---immediately.
---@generic T
---@param self T
---@param event string The name of the event. Events are case sensitive.
---@param ... any These args will be passed to the callback after the reference to `self` and the args defined in the listener.
---@return T
function Emitter.dispatchSync(self, event, ...) end

---Remove a specific listeners from the listener pool. You must pass both the event that is being listened to, and a
---reference to the exact callback function that was used in the listener.
---@generic T
---@param self T
---@param event string The name of the event. Events are case sensitive.
---@param callback function The callback function defined during listener creation.
---@return T
function Emitter.discard(self, event, callback) end