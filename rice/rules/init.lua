local ruled = require("ruled")


---@class Rice.Rules
local rules = {}

ruled.client.connect_signal("request::rules", function()
    ruled.client.append_rules(require("rice.rules.global"))
    ruled.client.append_rules(require("rice.rules.apps.1password"))
    ruled.client.append_rules(require("rice.rules.apps.dragon-drop"))
    ruled.client.append_rules(require("rice.rules.apps.freetube"))
    ruled.client.append_rules(require("rice.rules.apps.jetbrains"))
    ruled.client.append_rules(require("rice.rules.apps.localsend"))
    ruled.client.append_rules(require("rice.rules.apps.proton-vpn"))
    ruled.client.append_rules(require("rice.rules.apps.qr"))
    ruled.client.append_rules(require("rice.rules.apps.simplex-chat"))
    ruled.client.append_rules(require("rice.rules.apps.smartgit"))
    ruled.client.append_rules(require("rice.rules.apps.speedcrunch"))
    ruled.client.append_rules(require("rice.rules.apps.spotify"))
    ruled.client.append_rules(require("rice.rules.apps.xephyr"))
    ruled.client.append_rules(require("rice.rules.apps.xev"))
end)

return rules
