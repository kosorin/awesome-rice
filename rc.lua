require("globals")

require("config")

require("theme.manager").initialize()

require("core")
require("services")
require("ui")

---@diagnostic disable: param-type-mismatch
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 1000)
---@diagnostic enable: param-type-mismatch
