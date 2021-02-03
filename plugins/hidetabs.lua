local core = require "core"
local config = require "core.config"
local Node = require "core.node"

local get_tab_rect = Node.get_tab_rect
local draw_tabs = Node.draw_tabs

function Node:get_tab_rect(...)
  if not config.show_tabs then
    return 0, 0, 0, 0
  else
    return get_tab_rect(self, ...)
  end
end

function Node:draw_tabs(...)
  if config.show_tabs then
    return draw_tabs(self, ...)
  end
end


