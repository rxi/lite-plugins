local core = require "core"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"
local style = require "core.style"
local rootview = require "core.rootview"

config.scale_mode = "code"

local font_cache = setmetatable({}, { __mode = "k" })

-- the following should be kept in sync with core.style's default font settings
font_cache[style.font]      = { EXEDIR .. "/data/fonts/font.ttf",      14   * SCALE }
font_cache[style.big_font]  = { EXEDIR .. "/data/fonts/font.ttf",      34   * SCALE }
font_cache[style.icon_font] = { EXEDIR .. "/data/fonts/icons.ttf",     14   * SCALE }
font_cache[style.code_font] = { EXEDIR .. "/data/fonts/monospace.ttf", 13.5 * SCALE }


local load_font = renderer.font.load
function renderer.font.load(...)
  local res = load_font(...)
  font_cache[res] = { ... }
  return res
end


local function scale_font(font, s)
  local fc = font_cache[font]
  return renderer.font.load(fc[1], fc[2] * s)
end


local current_scale = SCALE
local default = current_scale

local function set_scale(scale)
  local s = scale / current_scale
  current_scale = scale

  if config.scale_mode == "ui" then
    style.padding.x      = style.padding.x      * s
    style.padding.y      = style.padding.y      * s
    style.divider_size   = style.divider_size   * s
    style.scrollbar_size = style.scrollbar_size * s
    style.caret_width    = style.caret_width    * s
    style.tab_width      = style.tab_width      * s

    style.big_font  = scale_font(style.big_font,  s)
    style.icon_font = scale_font(style.icon_font, s)
    style.font      = scale_font(style.font,      s)
    SCALE = current_scale
  end

  style.code_font = scale_font(style.code_font, s)

  core.redraw = true
end


command.add(nil, {
  ["scale:reset"   ] = function() set_scale(default)             end,
  ["scale:decrease"] = function() set_scale(current_scale * 0.9) end,
  ["scale:increase"] = function() set_scale(current_scale * 1.1) end,
})

keymap.add {
  ["ctrl+0"] = "scale:reset",
  ["ctrl+-"] = "scale:decrease",
  ["ctrl+="] = "scale:increase",
}

-- Modify mouse scroll behavior for ctrl key
rootview.on_mouse_wheel = function(self, ...)
  local x, y = self.mouse.x, self.mouse.y
  local node = self.root_node:get_child_overlapping_point(x, y)
  if keymap.modkeys["ctrl"] then
    -- Check if we have enough arguments
    if select('#', ...) > 0 then
      -- Zoom in or out
      if (select(1, ...) == 1) then
        command.perform('scale:increase')
      else
        command.perform('scale:decrease')
      end
    end
  else
    -- Handle mouse wheel normally
    node.active_view:on_mouse_wheel(...)
  end
end

return { set_scale = set_scale }
