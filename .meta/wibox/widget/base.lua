---@meta wibox.widget.base

---@alias widget_layout_result { _widget: wibox.widget, _width: number, _height: number, _matrix: gears.matrix }

---@class _wibox.widget.base
local S

---Create a widget from a declarative description.
---@param template widget_template # A table containing the widgets disposition.
---@return wibox.widget
function S.make_widget_declarative(template)
end

---Create a widget from an undetermined value.
---
---The value can be:
--- - A widget (in which case nothing new is created)
--- - A declarative construct
--- - A constructor function
--- - A metaobject
---@param value widget_value # The value.
---@param ... any # Arguments passed to the contructor (if any).
---@return wibox.widget|nil # The new widget or `nil` in case of failure.
function S.make_widget_from_value(value, ...)
end

---Create an empty widget skeleton.
---@param proxy? wibox.widget # If this is set, the returned widget will be a proxy for this widget. It will be equivalent to this widget. This means it looks the same on the screen.
---@param name? string # Name of the widget. If not set, it will be set automatically via `gears.object.modulename`.
---@param args? { enable_properties?: boolean, class?: table }
---@return wibox.widget
function S.make_widget(proxy, name, args)
end

---Generate an empty widget which takes no space and displays nothing.
---@return wibox.widget
function S.empty_widget()
end

---Fit a widget for the given available width and height.
---
---This calls the widget's `:fit` callback and caches the result for later use.
---Never call `:fit` directly, but always through this function!
---@param parent wibox.widget # The parent widget which requests this information.
---@param context widget_context # The context in which we are fit.
---@param widget wibox.widget # The widget to fit (this uses `widget:fit(context, width, height)`).
---@param width number # The available width for the widget.
---@param height number # The available height for the widget.
---@return number width # The width that the widget wants to use.
---@return number height # The height that the widget wants to use.
function S.fit_widget(parent, context, widget, width, height)
end

---Lay out a widget for the given available width and height.
---
---This calls the widget's `:layout()` callback and caches the result for later use.
---Never call `:layout()` directly, but always through this function!
---
---However, normally there shouldn't be any reason why you need to use this function.
---@param parent wibox.widget # The parent widget which requests this information.
---@param context widget_context # The context in which we are laid out.
---@param widget wibox.widget # he widget to layout (this uses `widget:layout(context, width, height)`).
---@param width number # The available width for the widget.
---@param height number # The available height for the widget.
---@return widget_layout_result[] # The result from the widget's `:layout()` callback.
function S.layout_widget(parent, context, widget, width, height)
end

---Create widget placement information. This should be used in a widget's `:layout()` callback.
---@param widget wibox.widget # The widget that should be placed.
---@param mat gears.matrix # A matrix transforming from the parent widget's coordinate system. For example, use matrix.create_translate(1, 2) to draw a widget at position (1, 2) relative to the parent widget.
---@param width number # The width of the widget in its own coordinate system. That is, after applying the transformation matrix.
---@param height number # The height of the widget in its own coordinate system. That is, after applying the transformation matrix.
---@return widget_layout_result # An opaque object that can be returned from `:layout()`.
function S.place_widget_via_matrix(widget, mat, width, height)
end

---Create widget placement information. This should be used for a widget's `:layout()` callback.
---@param widget wibox.widget # The widget that should be placed.
---@param x number # The x coordinate for the widget.
---@param y number # The y coordinate for the widget.
---@param width number # The width of the widget in its own coordinate system. That is, after applying the transformation matrix.
---@param height number # The height of the widget in its own coordinate system. That is, after applying the transformation matrix.
---@return widget_layout_result # An opaque object that can be returned from `:layout()`.
function S.place_widget_at(widget, x, y, width, height)
end

---Do some sanity checking on a widget. This function raises an error if the widget is not valid.
---@param widget wibox.widget
function S.check_widget(widget)
end

---Common implementation of the `:set_widget()` method exposed by many other widgets.
---
---Use this if your widget has no custom logic when setting the widget.
---@param self wibox.widget
---@param widget wibox.widget
---
---**Usage:**
---
---    rawset(my_custom_widget, "set_widget", wibox.widget.base.set_widget_common)
---
function S.set_widget_common(self, widget)
end

return S
