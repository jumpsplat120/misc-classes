---@meta Cron

---A simple class that fires an [emitter](lua://Emitter.Mixin) event after a defined delay. Events are
---both synchronous and asynchronous.
---@class Cron.Class
---@overload fun() Do not call directly.
CronClass = {}

---@see Cron.Class
---@class Cron : Classy.Object, Emitter.Mixin
---@field delay number The amount of time in seconds between each run of the cron.
---@field time_until number The amount of time remaining in seconds before the next run of the cron.
Cron = {}

---comment
---@param delay any
---@param ... unknown
function CronClass:after(delay, ...) end

---comment
---@param delay any
---@param ... unknown
---@return Cron
function CronClass:every(delay, ...) end

---comment
---@param opts any
function CronClass:new(opts) end

---comment
---@param dt any
function CronClass:update(dt) end

---comment
function Cron:destroy() end

---@overload fun(self: Cron, event: "cron.tick", callback: fun(self: Cron, ...: any), ...: any): Cron
Cron.on = Emitter.on

---@overload fun(self: Cron, event: "cron.tick", callback: fun(self: Cron, ...: any), ...: any): Cron
Cron.onSync = Emitter.onSync