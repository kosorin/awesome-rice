local binding = require("core.binding")
local mod = binding.modifier
local btn = binding.button
local bindbox = require("widget.bindbox")


---@class Rice.Bindings
local bindings = {}

bindbox.main:add_group(require("rice.bindings.apps.feh"))
bindbox.main:add_group(require("rice.bindings.apps.mpv"))
bindbox.main:add_groups {
    {
        name = "System",
    },
    {
        name = "Awesome",
    },
    {
        name = "Launcher",
    },
    {
        name = "Screen",
    },
    {
        name = "Layout",
        { modifiers = { mod.super, mod.control }, "space", description = "Layout switcher" },
    },
    {
        name = "Tag",
        groups = {
            {
                name = "Client",
            },
        },
    },
    {
        name = "Client",
        { modifiers = { mod.alt }, "Tab", description = "Client switcher" },
        groups = {
            {
                name = "State",
            },
            {
                name = "Layer",
            },
        },
    },
    {
        name = "Action",
    },
    {
        name = "Volume",
    },
    {
        name = "Media",
    },
    {
        name = "Screenshot",
    },
}

binding.add_global_range(require("rice.bindings.global"))
binding.add_client_range(require("rice.bindings.client"))

return bindings
