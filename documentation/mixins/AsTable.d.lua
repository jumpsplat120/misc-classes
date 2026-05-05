---@meta AsTable

---A mixin that takes [p.values](lua://Classy.private) and unpacks them into a table. Assumes numerically
---sequential items, aka, an "array-like" table.
---@class AsTable.Mixin
---@field table table The getter that unpacks the values. Creates a new table every time.
AsTable = {}