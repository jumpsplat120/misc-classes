---@meta Async

---@class Async.Class
---@overload fun(function: callback, ...: any)
local AsyncClass = {}

---@class Async : Classy.Object
local Async = {}

function AsyncClass:new(f, ...) end

function AsyncClass:wait(delay) end

--Runs a function until it returns a truthy value.
function AsyncClass:waitFor(func, ...) end

function AsyncClass:waitForEvent(object, event, timeout, ...) end

function AsyncClass:update(dt) end