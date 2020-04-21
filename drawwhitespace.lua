local common = require "core.common"
local config = require "core.config"
local style = require "core.style"
local DocView = require "core.docview"

local draw_line_text = DocView.draw_line_text

local whitespace_color

function DocView:draw_line_text(idx, x, y)
  whitespace_color = whitespace_color or { style.text[1], style.text[2], style.text[3], 128 }

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

