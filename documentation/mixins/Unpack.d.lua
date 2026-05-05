---@meta Unpack

---Mixin that lets you easily unpack all of the values in [p.values](lua://Classy.private).
---@class Unpack.Mixin

---Method for unpacking values from [p.values](lua://Classy.private). Uses `table.unpack` internally.
---@return ... All the values that existed in `p.values`. If none existed, then returns `nil`.
function Unpack:unpack() end