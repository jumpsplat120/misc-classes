local Error = require("classes.Error")

return Error("set_out_of_bounds", "Attempted to set a value (%s) out of bounds. Index must be between %s and %s but you tried %s.")