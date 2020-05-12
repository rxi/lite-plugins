-- Markers plugin for lite text editor
-- by Petri Häkkinen

local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local style = require "core.style"
local DocView = require "core.docview"

local markers = {}  -- this table contains subtables for each document, each subtable is a set of line numbers
setmetatable(markers, { __mode = 'k' })

local draw_line_gutter = DocView.draw_line_gutter


function DocView:draw_line_gutter(idx, x, y)
  if markers[self.doc] and markers[self.doc][idx] then
    local h = style.code_font:get_height() * 0.8
    renderer.draw_rect(x - 10 * SCALE, y + style.code_font:get_height() * 0.2, 9 * SCALE, h, style.selection)
  end
  draw_line_gutter(self, idx, x, y)
end


command.add("core.docview", {
  ["markers:toggle-marker"] = function()
    local doc = core.active_view.doc
    local line = doc:get_selection()

    markers[doc] = markers[doc] or {}
    local markers = markers[doc]

    if markers[line] then
      markers[line] = nil
    else
      markers[line] = true
    end
  end,

  ["markers:go-to-next-marker"] = function()
    local doc = core.active_view.doc
    local line = doc:get_selection()
    local markers = markers[doc]

    if markers then
      local first_marker = math.huge
      local next_marker = math.huge
      for l, _ in pairs(markers) do
        if l > line and l < next_marker then
          next_marker = l
        end
        first_marker = math.min(first_marker, l)
      end
      if next_marker == math.huge then
        next_marker = first_marker
      end
      if next_marker ~= math.huge then
        doc:set_selection(next_marker, 1)
        core.active_view:scroll_to_line(next_marker, true)
      end
    end
  end,
})


keymap.add {
  ["ctrl+f2"] = "markers:toggle-marker",
  ["f2"] = "markers:go-to-next-marker",
}
