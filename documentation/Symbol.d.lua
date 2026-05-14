---@meta Symbol

---Creates a symbol. While passing an `id` makes the symbol more human readable, it's not required.
---
---If no `id` is passed, then it will attempt to call `math.uuid`, if it exists. If it does not, then it
---simply generates a random float between zero and one to use as the id.
---@class Symbol.Class
---@overload fun(id: any): Symbol
local SymbolClass = {}

---A way to have a non unique value, like a string, represented by something unique.
---@class Symbol : Classy.Object
---@field id string Entirely meant for human readability, and otherwise has no function.
local Symbol = {}