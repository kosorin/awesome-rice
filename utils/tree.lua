local tree = {
    key_separator = "\t",
    root_key = "^", -- Just for debugging, can be an empty string
    root_name = "<root>", -- Just for debugging, can be anything
}

local Node = {}

function Node:traverse(method, filter)
    method = method or "pre"

    local function traverse(node, path)
        if not node or (filter and not filter(node, path)) then
            return
        end

        if method == "pre" then
            coroutine.yield(node, path)
        end

        for _, child in ipairs(node.children) do
            table.insert(path, child.name)
            traverse(child, path)
            table.remove(path, #path)
        end

        if method == "post" then
            coroutine.yield(node, path)
        end
    end

    local co = coroutine.create(function() traverse(self, {}) end)
    return function()
        local _, node, path = coroutine.resume(co)
        return node, path
    end
end

function Node:find_parent(predicate, include_self)
    local node = include_self and self or self.parent
    while node do
        local result = predicate(node)
        if result then
            return node, result
        end
        node = node.parent
    end
    return nil
end

function Node:find_child(predicate, include_self)
    for node in self:traverse() do
        if include_self or node ~= self then
            local result = predicate(node)
            if result then
                return node, result
            end
        end
    end
    return nil
end

local Tree = {}

local function expand_key(key, sub_key)
    return key .. tree.key_separator .. sub_key
end

local function create_key(path)
    if not path or #path == 0 then
        return tree.root_key
    end
    return expand_key(tree.root_key, table.concat(path, tree.key_separator))
end

local function create_empty_node(key, name, state)
    local node = {
        parent = nil,
        children = {},
        depth = 0,
        key = key,
        name = name,
        state = state or {},
    }
    return setmetatable(node, { __index = Node })
end

function Tree:get_or_add_node(parent, name, state)
    local key = expand_key(parent.key, name)
    local node = self.nodes[key]
    if node then
        return node, false
    end
    node = create_empty_node(key, name, state)
    if parent then
        node.parent = parent
        node.depth = parent.depth + 1
        table.insert(parent.children, node)
    end
    self.nodes[key] = node
    return node, true
end

function Tree:ensure_path(path)
    local key = create_key(path)
    local node = self.nodes[key]
    if node then
        return node
    end
    node = self.root
    for _, name in ipairs(path) do
        node = self:get_or_add_node(node, name)
    end
    return node
end

function Tree:traverse(method, filter)
    return self.root:traverse(method, filter)
end

function Tree:clone(state_clone, filter)
    local new_tree = tree.new()
    for node, path in self:traverse("post", filter) do
        local new_node = new_tree:ensure_path(path)
        new_node.state = state_clone and (state_clone(node, path) or {}) or node.state
    end
    return new_tree
end

function tree.new()
    local self = {}

    self.root = create_empty_node(tree.root_key, tree.root_name)
    self.nodes = { [self.root.key] = self.root }

    return setmetatable(self, { __index = Tree })
end

return tree
