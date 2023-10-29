local tostring = tostring
local format = string.format
local wibox = require("wibox")
local beautiful = require("theme.theme")
local dpi = Dpi
local aspawn = require("awful.spawn")
local pango = require("utils.pango")
local capsule = require("widget.capsule")
local hui = require("utils.thickness")
local common = require("ui.menu.templates.client._common")


local M = {}

M.signals = {
    [1] = "SIGHUP",
    [2] = "SIGINT",
    [3] = "SIGQUIT",
    [4] = "SIGILL",
    [5] = "SIGTRAP",
    [6] = "SIGABRT",
    [7] = "SIGBUS",
    [8] = "SIGFPE",
    [9] = "SIGKILL",
    [10] = "SIGUSR1",
    [11] = "SIGSEGV",
    [12] = "SIGUSR2",
    [13] = "SIGPIPE",
    [14] = "SIGALRM",
    [15] = "SIGTERM",
    [16] = "SIGSTKFLT",
    [17] = "SIGCHLD",
    [18] = "SIGCONT",
    [19] = "SIGSTOP",
    [20] = "SIGTSTP",
    [21] = "SIGTTIN",
    [22] = "SIGTTOU",
    [23] = "SIGURG",
    [24] = "SIGXCPU",
    [25] = "SIGXFSZ",
    [26] = "SIGVTALRM",
    [27] = "SIGPROF",
    [28] = "SIGWINCH",
    [29] = "SIGIO",
    [30] = "SIGPWR",
    [31] = "SIGSYS",
    [34] = "SIGRTMIN",
    [35] = "SIGRTMIN+1",
    [36] = "SIGRTMIN+2",
    [37] = "SIGRTMIN+3",
    [38] = "SIGRTMIN+4",
    [39] = "SIGRTMIN+5",
    [40] = "SIGRTMIN+6",
    [41] = "SIGRTMIN+7",
    [42] = "SIGRTMIN+8",
    [43] = "SIGRTMIN+9",
    [44] = "SIGRTMIN+10",
    [45] = "SIGRTMIN+11",
    [46] = "SIGRTMIN+12",
    [47] = "SIGRTMIN+13",
    [48] = "SIGRTMIN+14",
    [49] = "SIGRTMIN+15",
    [50] = "SIGRTMAX-14",
    [51] = "SIGRTMAX-13",
    [52] = "SIGRTMAX-12",
    [53] = "SIGRTMAX-11",
    [54] = "SIGRTMAX-10",
    [55] = "SIGRTMAX-9",
    [56] = "SIGRTMAX-8",
    [57] = "SIGRTMAX-7",
    [58] = "SIGRTMAX-6",
    [59] = "SIGRTMAX-5",
    [60] = "SIGRTMAX-4",
    [61] = "SIGRTMAX-3",
    [62] = "SIGRTMAX-2",
    [63] = "SIGRTMAX-1",
    [64] = "SIGRTMAX",
}

M.item_template = {
    widget = capsule,
    margins = hui.new { dpi(2), 0 },
    paddings = hui.new { dpi(6), dpi(8) },
    {
        layout = wibox.layout.fixed.horizontal,
        {
            id = "#number",
            widget = wibox.widget.textbox,
            halign = "right",
            forced_width = dpi(24),
        },
        {
            layout = wibox.container.margin,
            left = dpi(8),
            {
                id = "#text",
                widget = wibox.widget.textbox,
            },
        },
    },
    update_callback = function(self, item, menu)
        self.forced_width = item.width or menu.item_width
        self.forced_height = item.height or menu.item_height

        self.enable_overlay = item.enabled

        local styles = item.selected
            and beautiful.mebox.item_styles.selected
            or beautiful.mebox.item_styles.normal
        local style = item.urgent
            and styles.urgent
            or styles.normal
        self:apply_style(style)

        local number_widget = self:get_children_by_id("#number")[1]
        if number_widget then
            number_widget:set_markup(pango.span {
                fgcolor = style.fg,
                fgalpha = "50%",
                tostring(item.number),
            })
        end

        local text_widget = self:get_children_by_id("#text")[1]
        if text_widget then
            text_widget:set_markup(pango.span {
                fgcolor = style.fg,
                item.text or "",
            })
        end
    end,
}

---@return Mebox.new.args
function M.new()
    ---@type Mebox.new.args
    local args = {
        item_width = dpi(144),
        on_show = common.on_show,
        on_hide = common.on_hide,
        border_color = beautiful.common.urgent_bright,
        layout_template = {
            layout = wibox.layout.grid.horizontal,
            forced_num_rows = 8,
            homogeneous = false,
            expand = false,
        },
        items_source = function(menu)
            local client = menu.client --[[@as client]]
            local pid = client.pid

            ---@type MeboxItem.args[]
            local items = {}
            for i = 1, 32 do
                local signal = M.signals[i]
                if signal then
                    items[#items + 1] = {
                        number = i,
                        text = signal,
                        template = M.item_template,
                        callback = function()
                            aspawn(format("kill -%d %d", i, pid))
                        end,
                    }
                end
            end

            return items
        end,
    }

    return args
end

M.shared = M.new()

return M
