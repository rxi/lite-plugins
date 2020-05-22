local command   = require "core.command"
local common    = require "core.common"
local config    = require "core.config"
local style     = require "core.style"
local DocView   = require "core.docview"

-- General plugin settings
local minimap_width        = 100 * SCALE
local instant_click_scroll = false
local show_minimap         = true
local syntax_highlight     = true
local minimap_scale        = 1

-- Configure size for rendering each char in the minimap
local char_w = 1 * SCALE * minimap_scale
local char_h = 1 * SCALE * minimap_scale
local char_spacing = 0.75 * SCALE * minimap_scale
local line_spacing = 2 * SCALE * minimap_scale

-- Overloaded since the default implementation adds a extra x3 size of hotspot for the mouse to hit the scrollbar.
local prev_scrollbar_overlaps_point = DocView.scrollbar_overlaps_point
DocView.scrollbar_overlaps_point = function(self, x, y)
  if not show_minimap then return prev_scrollbar_overlaps_point(self, x, y) end

  local sx, sy, sw, sh = self:get_scrollbar_rect()
  return x >= sx and x < sx + sw and y >= sy and y < sy + sh
end

-- Overloaded with an extra check if the user clicked inside the minimap to automatically scroll to that line.
local prev_on_mouse_pressed = DocView.on_mouse_pressed
DocView.on_mouse_pressed = function(self, button, x, y, clicks)
  if not show_minimap then return prev_on_mouse_pressed(self, button, x, y, clicks) end

  -- check if user clicked in the minimap area and jump directly to that line
  -- unless they are actually trying to perform a drag
  local minimap_hit = self:scrollbar_overlaps_point(x, y)
  if minimap_hit then
    local line_count = #self.doc.lines
    local dy = y - self.position.y
    local h = line_count * line_spacing
    local line = math.floor((dy / h) * line_count) + 1

    -- If the click is on the currently visible line numbers,
    -- ignore it since then they probably want to initiate a drag instead.
    local _, cy, _, cy2 = self:get_content_bounds()
    local lh = self:get_line_height()
    local visible_lines_count = math.max(1, (cy2 - cy) / lh)
    local visible_lines_start = math.max(1, math.floor(cy / lh))
    if line < visible_lines_start or line > visible_lines_start + visible_lines_count then
      self:scroll_to_line(line, false, instant_click_scroll)
      return
    end
  end

  return prev_on_mouse_pressed(self, button, x, y, clicks)
end

-- Overloaded with pretty much the same logic as original DocView implementation,
-- with the exception of the dragging scrollbar delta. We want it to behave a bit snappier
-- since the "scrollbar" essentially represents the lines visible in the content view.
local prev_on_mouse_moved = DocView.on_mouse_moved
DocView.on_mouse_moved = function(self, x, y, dx, dy)
  if not show_minimap then return prev_on_mouse_moved(self, x, y, dx, dy) end

  if self.dragging_scrollbar then
    local line_count = #self.doc.lines
    local lh = self:get_line_height()
    local delta = lh / line_spacing * dy
    self.scroll.to.y = self.scroll.to.y + delta
  end
  self.hovered_scrollbar = self:scrollbar_overlaps_point(x, y)

  if self:scrollbar_overlaps_point(x, y) or self.dragging_scrollbar then
    self.cursor = "arrow"
  else
    self.cursor = "ibeam"
  end

  if self.mouse_selecting then
    local _, _, line2, col2 = self.doc:get_selection()
    local line1, col1 = self:resolve_screen_position(x, y)
    self.doc:set_selection(line1, col1, line2, col2)
  end
end

-- Overloaded since we want the mouse to interact with the full size of the minimap area,
-- not juse the scrollbar.
local prev_get_scrollbar_rect = DocView.get_scrollbar_rect
DocView.get_scrollbar_rect = function (self)
  if not show_minimap then return prev_get_scrollbar_rect(self) end

  return
    self.position.x + self.size.x - minimap_width,
    self.position.y,
    minimap_width,
    self.size.y
end

-- Overloaded so we can render the minimap in the "scrollbar area".
local prev_draw_scrollbar = DocView.draw_scrollbar
DocView.draw_scrollbar = function (self)
  if not show_minimap then return prev_draw_scrollbar(self) end

  local x, y, w, h = self:get_scrollbar_rect()

  local highlight = self.hovered_scrollbar or self.dragging_scrollbar
  local color = highlight and style.scrollbar2 or style.scrollbar

  local _, cy, _, cy2 = self:get_content_bounds()
  local lh = self:get_line_height()
  local visible_lines_count = math.max(1, (cy2 - cy) / lh)
  local visible_lines_start = math.max(1, math.floor(cy / lh))
  local scroller_height = visible_lines_count * line_spacing

  local visible_y_offset = self.position.y + (visible_lines_start-1) * line_spacing

  -- draw visual rect
  renderer.draw_rect(x, visible_y_offset, w, scroller_height, color)

  -- time to draw the actual code, setup some local vars that are used in both highlighted and plain renderind.
  local line_count = #self.doc.lines
  local line_y = y

  -- when not using syntax highlighted rendering, just use the normal color but dim it 50%.
  local color = style.syntax["normal"]
  color = { color[1],color[2],color[3],color[4] * 0.5 }

  -- we try to "batch" characters so that they can be rendered as just one rectangle instead of one for each.
  local batch_width = 0
  local batch_start = x

  -- render lines with syntax highlighting
  if syntax_highlight then

    -- keep track of the highlight type, since this needs to break batches as well
    local batch_syntax_type = nil

    local function flush_batch(type)
      if batch_width > 0 then
        -- fetch and dim colors
        color = style.syntax[batch_syntax_type]
        color = { color[1], color[2], color[3], color[4] * 0.5 }
        renderer.draw_rect(batch_start, line_y, batch_width, char_h, color)
      end
      batch_syntax_type = type
      batch_start = batch_start + batch_width
      batch_width = 0
    end

    -- per line
    for idx=1,line_count-1 do
      batch_syntax_type = nil
      batch_start = x
      batch_width = 0

      -- per token
      for _, type, text in self.doc.highlighter:each_token(idx) do
        -- flush prev batch
        if not batch_syntax_type then batch_syntax_type = type end
        if batch_syntax_type ~= type then
          flush_batch(type)
        end

        -- per character
        for char in common.utf8_chars(text) do
          if char == " " or char == "\n" then
            flush_batch(type)
            batch_start = batch_start + char_spacing
          else
            batch_width = batch_width + char_spacing
          end

        end
      end
      flush_batch(nil)
      line_y = line_y + line_spacing
    end

  else  -- render lines without syntax highlighting

    local function flush_batch()
      if batch_width > 0 then
        renderer.draw_rect(batch_start, line_y, batch_width, char_h, color)
      end
      batch_start = batch_start + batch_width
      batch_width = 0
    end

    for idx=1,line_count-1 do
      batch_start = x
      batch_width = 0

      for char in common.utf8_chars(self.doc.lines[idx]) do
        if char == " " or char == "\n" then
          flush_batch()
          batch_start = batch_start + char_spacing
        else
          batch_width = batch_width + char_spacing
        end
      end
      flush_batch()
      line_y = line_y + line_spacing
    end

  end

end

command.add(nil, {
  ["minimap:toggle-visibility"] = function()
    show_minimap = not show_minimap
  end,
  ["minimap:toggle-syntax-highlighting"] = function()
    syntax_highlight = not syntax_highlight
  end,
})

