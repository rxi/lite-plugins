local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"


-- Keeps the line and column number where cursor was while switching
-- between split panes. It is useful when working on a large
-- text file in multiple panes.


local function new_weak_table()
  return setmetatable({ }, { __mode = "v" })
end


local function dv()
  return core.active_view
end


local view_states = { }


local function find_in_view_state(view_state, node)
  for k, v in pairs(view_state) do
    if v.node == node then
      return k
    end
  end

  return -1
end


local function save_view_state()
  local node = core.root_view:get_active_node()
  local idx = node:get_view_idx(dv())
  local line, col = dv().doc:get_selection(false)

  local view_state = view_states[idx]
  if view_state == nil then
    view_state = { }
  end

  local ind = find_in_view_state(view_state, node)

  local state
  if ind > -1 then
    state = view_state[ind]
    state.line = line
    state.col = col

    view_state[ind] = nil
  else
    state = new_weak_table()
    state.node = node
    state.line = line
    state.col = col
  end

  table.insert(view_state, state)
  view_states[idx] = view_state
end


local function restore_view_state()
  local node = core.root_view:get_active_node()
  local idx = node:get_view_idx(dv())

  local view_state = view_states[idx]
  if view_state then
    local ind = find_in_view_state(view_state, node)
    if ind > -1 then
      local state = view_state[ind]
      local line = state.line
      local col = state.col

      dv().doc:set_selection(line, col)
      dv():scroll_to_line(line, true)
    end
  end
end


for _, dir in ipairs { "left", "right", "up", "down" } do
  command.add(nil, {
    ["stateful-switch:switch-to-" .. dir] = function ()
      save_view_state()
      command.perform("root:switch-to-" .. dir)
      restore_view_state()
    end
  })
end


keymap.add({
  ["alt+j"] = "stateful-switch:switch-to-left",
  ["alt+l"] = "stateful-switch:switch-to-right",
  ["alt+i"] = "stateful-switch:switch-to-up",
  ["alt+k"] = "stateful-switch:switch-to-down"
})

