local Error = require("classes.Error")

return Error("state_mismatch", "Provided state (%s) does not match expected state (%s). Possible MITM attack.")