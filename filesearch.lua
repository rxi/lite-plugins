local core = require "core"
local common = require "core.common"
local keymap = require "core.keymap"
local command = require "core.command"
local style = require "core.style"
local View = require "core.view"


local ResultsView = View:extend()


function ResultsView:new(text, fn)
  ResultsView.super.new(self)
  self.scrollable = true
  self:begin_search(text, fn)
end


function ResultsView:get_name()
  return "File Search Results"
end


function ResultsView:begin_search(text, fn)
  self.results = {}
  self.last_file_idx = 1
  self.query = text
  self.searching = true
  self.selected_idx = 0

  core.add_thread(function()
    for i, file in ipairs(core.project_files) do
      if file.type == "file" then
        if fn(file.filename) then
          table.insert(self.results, { file = file.filename, text = file.filename, line = 0, col = 0 })
          core.redraw = true
        end
      end

      self.last_file_idx = i
    end

    self.searching = false
    core.redraw = true
  end, self)
end


function ResultsView:on_mouse_moved(mx, my, ...)
  ResultsView.super.on_mouse_moved(self, mx, my, ...)
  self.selected_idx = 0
  for i, item, x,y,w,h in self:each_visible_result() do
    if mx >= x and my >= y and mx < x + w and my < y + h then
      self.selected_idx = i
      break
    end
  end
end

function ResultsView:on_mouse_pressed(...)
  local caught = ResultsView.super.on_mouse_pressed(self, ...)
  if not caught then
    self:open_selected_result()
  end
end


function ResultsView:open_selected_result()
  local res = self.results[self.selected_idx]
  if not res then
    return
  end
  core.try(function()
    local dv = core.root_view:open_doc(core.open_doc(res.file))
    core.root_view.root_node:update_layout()
    dv.doc:set_selection(res.line, res.col)
    dv:scroll_to_line(res.line, false, true)
  end)
end


function ResultsView:update()
  self.scroll.to.y = math.max(0, self.scroll.to.y)
  ResultsView.super.update(self)
end


function ResultsView:get_results_yoffset()
  return style.font:get_height() + style.padding.y * 3
end


function ResultsView:get_line_height()
  return style.padding.y + style.font:get_height()
end


function ResultsView:get_scrollable_size()
  local rh = style.padding.y + style.font:get_height()
  return self:get_results_yoffset() + #self.results * self:get_line_height()
end


function ResultsView:get_visible_results_range()
  local lh = self:get_line_height()
  local oy = self:get_results_yoffset()
  local min = math.max(1, math.floor((self.scroll.y - oy) / lh))
  return min, min + math.floor(self.size.y / lh) + 1
end


function ResultsView:each_visible_result()
  return coroutine.wrap(function()
    local lh = self:get_line_height()
    local x, y = self:get_content_offset()
    local min, max = self:get_visible_results_range()
    y = y + self:get_results_yoffset() + lh * (min - 1)
    for i = min, max do
      local item = self.results[i]
      if not item then break end
      coroutine.yield(i, item, x, y, self.size.x, lh)
      y = y + lh
    end
  end)
end


function ResultsView:scroll_to_make_selected_visible()
  local h = self:get_line_height()
  local y = self:get_results_yoffset() + h * (self.selected_idx - 1)
  self.scroll.to.y = math.min(self.scroll.to.y, y)
  self.scroll.to.y = math.max(self.scroll.to.y, y + h - self.size.y)
end


function ResultsView:draw()
  self:draw_background(style.background)

  -- status
  local ox, oy = self:get_content_offset()
  local x, y = ox + style.padding.x, oy + style.padding.y
  local per = self.last_file_idx / #core.project_files
  local text
  if self.searching then
    text = string.format("Searching %d%% (%d of %d files, %d matches) for %q...",
      per * 100, self.last_file_idx, #core.project_files,
      #self.results, self.query)
  else
    text = string.format("Found %d matches for %q",
      #self.results, self.query)
  end
  renderer.draw_text(style.font, text, x, y, style.text)

  -- horizontal line
  local yoffset = self:get_results_yoffset()
  local x = ox + style.padding.x
  local w = self.size.x - style.padding.x * 2
  local h = style.divider_size
  renderer.draw_rect(x, oy + yoffset - style.padding.y, w, h, style.dim)
  if self.searching then
    renderer.draw_rect(x, oy + yoffset - style.padding.y, w * per, h, style.text)
  end

  -- results
  local y1, y2 = self.position.y, self.position.y + self.size.y
  for i, item, x,y,w,h in self:each_visible_result() do
    local color = style.text
    if i == self.selected_idx then
      color = style.accent
      renderer.draw_rect(x, y, w, h, style.line_highlight)
    end
    x = x + style.padding.x
    local text = string.format("%s", item.file)
    x = common.draw_text(style.code_font, color, item.text, "left", x, y, w, h)
  end

  self:draw_scrollbar()
end


local function begin_search(text, fn)
  if text == "" then
    core.error("Expected non-empty string")
    return
  end
  local rv = ResultsView(text, fn)
  core.root_view:get_active_node():add_view(rv)
end


command.add(nil, {
  ["project-file-search:find-file"] = function()
    core.command_view:enter("Find File In Project", function(text)
      text = text:lower()
      begin_search(text, function(filename)
        return filename:lower():find(text, nil, true)
      end)
    end)
  end,
})


command.add(ResultsView, {
  ["project-file-search:select-previous"] = function()
    local view = core.active_view
    view.selected_idx = math.max(view.selected_idx - 1, 1)
    view:scroll_to_make_selected_visible()
  end,

  ["project-file-search:select-next"] = function()
    local view = core.active_view
    view.selected_idx = math.min(view.selected_idx + 1, #view.results)
    view:scroll_to_make_selected_visible()
  end,

  ["project-file-search:open-selected"] = function()
    core.active_view:open_selected_result()
  end,
})

keymap.add {
  ["ctrl+t"] = "project-file-search:find-file",
  ["up"]     = "project-file-search:select-previous",
  ["down"]   = "project-file-search:select-next",
  ["return"] = "project-file-search:open-selected",
}
