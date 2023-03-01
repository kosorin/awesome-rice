require("globals")

local config = require("config")

local awful_utils = require("awful.util")
local desktop_utils = require("utils.desktop")
awful_utils.shell = config.apps.shell
desktop_utils.terminal = config.apps.terminal

local theme_manager = require("theme.manager")
theme_manager.initialize()

require("core")
require("services")
require("ui")

---@diagnostic disable: param-type-mismatch
collectgarbage("setpause", 110)
collectgarbage("setstepmul", 1000)
---@diagnostic enable: param-type-mismatch
