local common = require "core.common"
local config = require "core.config"
local style = require "core.style"
local DocView = require "core.docview"

local draw_line_text = DocView.draw_line_text

local text_color = style.text
local whitespace_color = { text_color[1], text_color[2], text_color[3], 128 }

function DocView:draw_line_text(idx, x, y)
  draw_line_text(self, idx, x, y)

  local cl = self:get_cached_line(idx)
  local tx, ty = x, y + self:get_line_text_y_offset()
  local font = self:get_font()

  for i = 1, #cl.text do
    local char = cl.text:sub(i, i)
    local width = font:get_width(char)
    if char == " " then
      renderer.draw_text(font, ".", tx, ty, whitespace_color)
    elseif char == "\t" then
      renderer.draw_text(font, "›", tx, ty, whitespace_color)
    end
    tx = tx + width
  end
end
