---------------------------------------------------------------------------
-- @author Antonio Terceiro
-- @copyright 2009, 2011-2012, 2023 Antonio Terceiro, Alexander Yakushev, SkyyySi, me ;)
---------------------------------------------------------------------------

local ipairs = ipairs
local pairs = pairs
local table = table
local string = string
local gfilesystem = require("gears.filesystem")
local beautiful = require("beautiful")
local lgi = require("lgi")
local gio = lgi.Gio
local glib = lgi.GLib
local gdebug = require("gears.debug")
local gpcall = require("gears.protected_call").call


local desktop_utils = {}

-- NOTE: This icons/desktop files module was written according to the
-- following freedesktop.org specifications:
-- Icons: http://standards.freedesktop.org/icon-theme-spec/icon-theme-spec-0.11.html
-- Desktop files: http://standards.freedesktop.org/desktop-entry-spec/desktop-entry-spec-1.0.html

-- Options section

--- Terminal which applications that need terminal would open in.
-- @param[opt="xterm"] string
desktop_utils.terminal = "xterm"

--- The default icon for applications that don't provide any icon in
-- their .desktop files.
-- @param[opt] string
desktop_utils.default_icon = nil

--- Name of the WM for the OnlyShowIn entry in the .desktop file.
-- @param[opt="awesome"] string
desktop_utils.wm_name = "awesome"

-- Maps keys in desktop entries to suitable getter function.
-- The order of entries is as in the spec.
-- https://standards.freedesktop.org/desktop-entry-spec/latest/ar01s05.html
local keys_getters
do
    local function get_string(kf, key)
        return kf:get_string("Desktop Entry", key)
    end

    local function get_strings(kf, key)
        return kf:get_string_list("Desktop Entry", key, nil)
    end

    local function get_localestring(kf, key)
        return kf:get_locale_string("Desktop Entry", key, nil)
    end

    local function get_localestrings(kf, key)
        return kf:get_locale_string_list("Desktop Entry", key, nil, nil)
    end

    local function get_boolean(kf, key)
        return kf:get_boolean("Desktop Entry", key)
    end

    keys_getters = {
        Type = get_string,
        Version = get_string,
        Name = get_localestring,
        GenericName = get_localestring,
        NoDisplay = get_boolean,
        Comment = get_localestring,
        Icon = get_localestring,
        Hidden = get_boolean,
        OnlyShowIn = get_strings,
        NotShowIn = get_strings,
        DBusActivatable = get_boolean,
        TryExec = get_string,
        Exec = get_string,
        Path = get_string,
        Terminal = get_boolean,
        Actions = get_strings,
        MimeType = get_strings,
        Categories = get_strings,
        Implements = get_strings,
        Keywords = get_localestrings,
        StartupNotify = get_boolean,
        StartupWMClass = get_string,
        URL = get_string,
    }

    --- Default to `get_string` if no getter was defined above
    setmetatable(keys_getters, {
        __index = function(self, key)
            return rawget(self, key) or get_string
        end,
    })
end

local all_icon_sizes = {
    "scalable",
    "128x128",
    "96x96",
    "72x72",
    "64x64",
    "48x48",
    "36x36",
    "32x32",
    "24x24",
    "22x22",
    "16x16",
    "symbolic",
}

local all_icon_types = {
    "actions",
    "animations",
    "apps",
    "categories",
    "devices",
    "emblems",
    "emotes",
    "mimetypes",
    "panel",
    "places",
    "status",
}

--- Enum of supported icon exts.
local supported_icon_file_exts = { svg = 1, png = 2, xpm = 3, }

--- Get a list of icon lookup paths, uncached.
-- @treturn table A list of directories, without trailing slash.
function desktop_utils.get_icon_lookup_paths_uncached()
    local function ensure_args(t, paths)
        if type(paths) == "string" then paths = { paths } end
        return t or {}, paths
    end

    local function add_if_readable(t, paths)
        t, paths = ensure_args(t, paths)

        for _, path in ipairs(paths) do
            if gfilesystem.dir_readable(path) then
                table.insert(t, path)
            end
        end
        return t
    end

    local function add_with_dir(t, paths, dir)
        t, paths = ensure_args(t, paths)
        dir = { nil, dir }

        for _, path in ipairs(paths) do
            dir[1] = path
            table.insert(t, glib.build_filenamev(dir))
        end
        return t
    end

    local icon_lookup_path = {}
    local theme_priority = { "hicolor" }
    if beautiful.icon_theme then table.insert(theme_priority, 1, beautiful.icon_theme) end

    local paths = add_with_dir({}, glib.get_home_dir(), ".icons")
    add_with_dir(paths, {
        glib.get_user_data_dir(), -- $XDG_DATA_HOME, typically $HOME/.local/share
        table.unpack(glib.get_system_data_dirs()), -- $XDG_DATA_DIRS, typically /usr/{,local/}share
    }, "icons")
    add_with_dir(paths, glib.get_system_data_dirs(), "pixmaps")

    local icon_theme_paths = {}
    for _, theme_dir in ipairs(theme_priority) do
        add_if_readable(icon_theme_paths, add_with_dir({}, paths, theme_dir))
    end

    local app_in_theme_paths = {}
    for _, icon_theme_directory in ipairs(icon_theme_paths) do
        for _, size in ipairs(all_icon_sizes) do
            for _, icon_type in ipairs(all_icon_types) do
                table.insert(app_in_theme_paths, glib.build_filenamev { icon_theme_directory, size, icon_type })
                table.insert(app_in_theme_paths, glib.build_filenamev { icon_theme_directory, icon_type, size })
            end
        end
    end
    add_if_readable(icon_lookup_path, app_in_theme_paths)

    return add_if_readable(icon_lookup_path, paths)
end

local icon_lookup_paths_cache
--- Get a list of icon lookup paths.
-- @treturn table A list of directories, without trailing slash.
function desktop_utils.get_icon_lookup_paths()
    if not icon_lookup_paths_cache then
        icon_lookup_paths_cache = desktop_utils.get_icon_lookup_paths_uncached()
    end

    return icon_lookup_paths_cache
end

--- Remove CR newline from the end of the string.
-- @tparam string s The string to trim
-- @staticfct menubar.utils.rtrim
-- @treturn string The trimmed string.
function desktop_utils.rtrim(s)
    if not s then return end
    if string.byte(s, #s) == 13 then
        return string.sub(s, 1, #s - 1)
    end
    return s
end

--- Lookup an icon in different folders of the filesystem.
-- @tparam string icon_file Short or full name of the icon.
-- @treturn string|boolean Full name of the icon, or false on failure.
-- @staticfct menubar.utils.lookup_icon_uncached
function desktop_utils.lookup_icon_uncached(icon_file)
    if not icon_file or icon_file == "" then
        return false
    end

    local icon_file_ext = icon_file:match(".+%.(.*)$")
    if icon_file:sub(1, 1) == "/" and supported_icon_file_exts[icon_file_ext] then
        -- If the path to the icon is absolute do not perform a lookup [nil if unsupported ext or missing]
        return gfilesystem.file_readable(icon_file) and icon_file or nil
    else
        -- Look for the requested file in the lookup path
        for _, directory in ipairs(desktop_utils.get_icon_lookup_paths()) do
            local possible_file = directory .. "/" .. icon_file
            -- Check to see if file exists if requested with a valid extension
            if supported_icon_file_exts[icon_file_ext] and gfilesystem.file_readable(possible_file) then
                return possible_file
            else
                -- Find files with any supported extension if icon specified without, eg: "firefox"
                for ext, _ in pairs(supported_icon_file_exts) do
                    local possible_file_new_ext = possible_file .. "." .. ext
                    if gfilesystem.file_readable(possible_file_new_ext) then
                        return possible_file_new_ext
                    end
                end
            end
        end
        -- No icon found
        return false
    end
end

local lookup_icon_cache = {}
--- Lookup an icon in different folders of the filesystem (cached).
-- @param icon Short or full name of the icon.
-- @return full name of the icon.
-- @staticfct menubar.utils.lookup_icon
function desktop_utils.lookup_icon(icon, default_icon)
    if not icon then
        return default_icon or desktop_utils.default_icon
    end
    if not lookup_icon_cache[icon] and lookup_icon_cache[icon] ~= false then
        lookup_icon_cache[icon] = desktop_utils.lookup_icon_uncached(icon)
    end
    return lookup_icon_cache[icon] or default_icon or desktop_utils.default_icon
end

--- Parse a .desktop file.
-- @param file The .desktop file.
-- @return A table with file entries.
-- @staticfct menubar.utils.parse_desktop_file
function desktop_utils.parse_desktop_file(file)
    local program = { show = true, file = file }

    -- Parse the .desktop file.
    -- We are interested in [Desktop Entry] group only.
    local keyfile = glib.KeyFile()
    if not keyfile:load_from_file(file, glib.KeyFileFlags.NONE) then
        return nil
    end

    -- In case [Desktop Entry] was not found
    if not keyfile:has_group("Desktop Entry") then
        return nil
    end

    for _, key in pairs(keyfile:get_keys("Desktop Entry")) do
        local getter = keys_getters[key]
        program[key] = getter(keyfile, key)
    end

    -- By default, only the identifier of each action is added to `program`.
    -- This will replace those actions with a (localized) table holding the
    -- "actual" action data, including its Exec and Icon.
    -- See https://specifications.freedesktop.org/desktop-entry-spec/desktop-entry-spec-latest.html#extra-actions
    if program.Actions then
        program.actions_table = {}

        for _, action in pairs(program.Actions) do
            local cur_action = "Desktop Action " .. action
            program.actions_table[action] = {}

            for _, key in pairs(keyfile:get_keys(cur_action)) do
                program.actions_table[action][key] = keyfile:get_locale_string(cur_action, key)
            end
        end
    end

    -- In case the (required) "Name" entry was not found
    if not program.Name or program.Name == "" then return nil end

    -- Don't show program if NoDisplay attribute is true
    if program.NoDisplay then
        program.show = false
    else
        -- Only check these values is NoDisplay is true (or non-existent)

        -- Only show the program if there is no OnlyShowIn attribute
        -- or if it contains wm_name or wm_name is empty
        if desktop_utils.wm_name ~= "" then
            if program.OnlyShowIn then
                program.show = false -- Assume false until found
                for _, wm in ipairs(program.OnlyShowIn) do
                    if wm == desktop_utils.wm_name then
                        program.show = true
                        break
                    end
                end
            else
                program.show = true
            end
        end

        -- Only need to check NotShowIn if the program is being shown
        if program.show and program.NotShowIn then
            for _, wm in ipairs(program.NotShowIn) do
                if wm == desktop_utils.wm_name then
                    program.show = false
                    break
                end
            end
        end
    end

    -- Look up for a icon.
    if program.Icon then
        program.icon_path = desktop_utils.lookup_icon(program.Icon)
    end

    -- Make the variable lower-case like the rest of them
    if program.Categories then
        program.categories = program.Categories
    end

    if program.Exec then
        -- Substitute Exec special codes as specified in
        -- http://standards.freedesktop.org/desktop-entry-spec/1.1/ar01s06.html
        if not program.Name then
            program.Name = "[" .. file:match("([^/]+)%.desktop$") .. "]"
        end
        local cmdline = program.Exec:gsub("%%c", program.Name)
        cmdline = cmdline:gsub("%%[fuFU]", "")
        cmdline = cmdline:gsub("%%k", program.file)
        if program.icon_path then
            cmdline = cmdline:gsub("%%i", "--icon " .. program.icon_path)
        else
            cmdline = cmdline:gsub("%%i", "")
        end
        if program.Terminal then
            cmdline = desktop_utils.terminal .. " -e " .. cmdline
        end
        program.cmdline = cmdline
    end

    return program
end

do
    local function get_readable_path(file)
        return file:get_path() or file:get_uri()
    end

    local function parser(file, programs)
        -- Except for "NONE" there is also NOFOLLOW_SYMLINKS
        local query = gio.FILE_ATTRIBUTE_STANDARD_NAME .. "," .. gio.FILE_ATTRIBUTE_STANDARD_TYPE
        local enum, err = file:async_enumerate_children(query, gio.FileQueryInfoFlags.NONE)
        if not enum then
            gdebug.print_warning(get_readable_path(file) .. ": " .. tostring(err))
            return
        end
        local files_per_call = 100 -- Actual value is not that important
        while true do
            local list, enum_err = enum:async_next_files(files_per_call)
            if enum_err then
                gdebug.print_error(get_readable_path(file) .. ": " .. tostring(enum_err))
                return
            end
            for _, info in ipairs(list) do
                local file_type = info:get_file_type()
                local file_child = enum:get_child(info)
                if file_type == "REGULAR" then
                    local path = file_child:get_path()
                    if path then
                        local success, program = pcall(desktop_utils.parse_desktop_file, path)
                        if not success then
                            gdebug.print_error("Error while reading '" .. path .. "': " .. program)
                        elseif program then
                            table.insert(programs, program)
                        end
                    end
                elseif file_type == "DIRECTORY" then
                    parser(file_child, programs)
                end
            end
            if #list == 0 then
                break
            end
        end
        enum:async_close()
    end

    --- Parse a directory with .desktop files recursively.
    -- @tparam string directory The directory path.
    -- @tparam function callback Will be fired when all the files were parsed
    -- with the resulting list of menu entries as argument.
    -- @tparam table callback.programs Paths of found .desktop files.
    -- @staticfct menubar.utils.parse_directory
    -- @noreturn
    function desktop_utils.parse_directory(directory, callback)
        gio.Async.start(gpcall)(function()
            local result = {}
            parser(gio.File.new_for_path(directory), result)
            callback(result)
        end)
    end
end

return desktop_utils
