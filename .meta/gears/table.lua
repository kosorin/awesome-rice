---@meta gears.table

---@class _gears.table
local S

---Join all tables given as arguments.
---@param ... table # Tables to join.
---@return table # A new table containing all entries from the arguments.
function S.join(...)
end

---Override elements in the target table with values from the source table.
---
---Note that this method doesn't copy entries found in `__index`.
---Nested tables are copied by reference and not recursed into.
---@param target table # The target table. Values from `source` will be copied into this table.
---@param source table # The source table. Its values will be copied into `target`.
---@param raw? boolean # If `true`, values will be assigned with `rawset`. This will bypass metamethods on `target`. Default: `false`
---@return table # The `target` table.
function S.crush(target, source, raw)
end

---Pack all elements with an integer key into a new table.
---
---While both lua and luajit implement `__len` over sparse tables, the standard defines it as an implementation detail.
---
---This function removes any entries with non-numeric keys.
---@param t any[] # A potentially sparse table.
---@return any[] # A packed table with only numeric keys.
function S.from_sparse(t)
end

---Check if a table has an item and return its key.
---@generic K, V
---@param t table<K, V> # The table.
---@param item V # The item to look for in values of the table.
---@return K|nil # The key of the item.
function S.hasitem(t, item)
end

---Get all matching table keys for a matcher function.
---@generic K, V
---@param t table<K, V> # The table.
---@param matcher fun(key: K, value: V): boolean # A function taking the key and value as arguments and returning a boolean.
---@param ordered? boolean # If `true`, only look for continuous numeric keys. Default: `false`
---@param max? integer # The maximum number of entries to find. Default: `nil`
---@return K[]|nil # An ordered table with all the keys or `nil` if none were found.
function S.find_keys(t, matcher, ordered, max)
end

---Find the first key that matches a function.
---@generic K, V
---@param t table<K, V> # The table.
---@param matcher fun(key: K, value: V): boolean # A function taking the key and value as arguments and returning a boolean.
---@param ordered? boolean # If `true`, only look for continuous numeric keys. Default: `false`
---@return K|nil
function S.find_first_key(t, matcher, ordered)
end

---Get a sorted table with all keys from a table.
---@param t table # The table for which the keys to get.
---@return any[]
function S.keys(t)
end

---Get the number of keys in a table, both integer and string indicies.
---This is functionally equivalent, but faster than `gears.table.keys`.
---@param t table # The table for which to count the keys.
---@return integer # The number of keys in the table.
function S.count_keys(t)
end

---Filter a table's keys for certain content type.
---@param t table # The table to retrieve the keys for.
---@param ... string # The types to look for.
---@return table # A filtered table.
function S.keys_filter(t, ...)
end

---Reverse a table.
---@param t any[] # The table to reverse.
---@return table # A reversed table.
function S.reverse(t)
end

---Clone a table.
---@param t table # The table to clone.
---@param deep? boolean # If `true`, recurse into nested tables to create a deep clone. Default: `true`
---@return table # A clone of `t`.
function S.clone(t, deep)
end

---Get the next (or previous) value from a table and cycle if necessary.
---
---If the table contains the same value multiple type (aka, is not a set), the `first_index` has to be specified.
---@param t table # The input table.
---@param value any # The start value. Must be an element of the input table `t`.
---@param step_size? integer # The amount to increment the index by. When this is negative, the function will cycle through the table backwards. Default: `1`
---@param filter? fun(value: any): boolean # An optional filter function. It receives a value from the table as parameter and should return a boolean. If it returns `false`, the value is skipped and `cycle_value` tries the next one. Default: `nil`
---@param start_at? integer # Where to start the lookup from. Default: `1`
---@return integer|nil
function S.cycle_value(t, value, step_size, filter, start_at)
end

---Iterate over a table.
---@param t table # The table to iterate.
---@param filter fun(value: any): boolean # A function that returns true to indicate a positive match.
---@param start? integer # Index to start iterating from. Default: `1`
---@return function # Returns an iterator to cycle through all elements of a table that match a given criteria, starting from the first element or the given index.
function S.iterate(t, filter, start)
end

---Merge items from the source table into the target table.
---
---Note that this only considers the array part of `source` (same semantics as `ipairs`).
---Nested tables are copied by reference and not recursed into.
---@param target table # The target table. Values from `source` will be copied into this table.
---@param source table #The source table. Its values will be copied into `target`.
---@return table # The `target` table.
function S.merge(target, source)
end

---Update the `target` table with entries from the `new` table.
---
---Compared to gears.table.merge, this version is intended to work using both an `identifier` function and a `merger` function.
---This works only for indexed tables.
---
---The main use case is when changing the table reference is not possible or when the `target` contains additional content that must be kept.
---
---Note that calling this function involve a lot of looping and should not be done often.
---@param target table # The table to modify.
---@param new table # The table which contains the new content.
---@param identifier fun(value: any): any # A function which take the table entry (either from the `target` or `new` table) and return an unique identifier. The identifier type isn't important as long as `==` works to compare them.
---@param merger fun(target: table, source: table): table # A function takes the entry to modify as first parameter and the new entry as second. The function must return the merged value. If none is provided, there is no attempt to merge the content.
---@return table output # The target table (for daisy chaining).
---@return table added # The new entries.
---@return table removed # The removed entries.
---@return table updated # The updated entries.
---**Usage:**
---
---    local output, added, removed, updated = gears.table.diff_merge(
---        output, input, function(v) return v.id end, gears.table.crush,
---    )
---
function S.diff_merge(target, new, identifier, merger)
end

---Map a function to a table.
---The function is applied to each value in the table, returning a modified table.
---@param f fun(value: any): any # The function to be applied to each value in the table.
---@param t table # The container table whose values will be operated on.
---@return table
function S.map(f, t)
end

return S
