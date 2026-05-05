---@meta Ipairs

---A mixin that lets an object internally call `ipairs` on [p.values](lua://Classy.private) using a coroutine.
---This allows the user to place the object straight into a `for ... in` loop, and have it iterate over it's
---internal values without needing to first create a new, seperate table. 
---@class Ipairs.Mixin
Ipairs = {}

---The method version of the `ipairs` iterator. Classes that implement Ipairs.Mixin can use the object itself,
---as it overloads `__call`, but you may also use this method to make your code more clear and explicit in
---it's function. This method is also available if, for some reason, you wish to implement both 
---[Pairs.Mixin](lua://Pairs.Mixin) and Ipairs.Mixin at the same time.
---@return function #A function that resumes the coroutine each time it is called. If the coroutine dies, then it's discard and a new one is created.
function Ipairs:ipairs() end