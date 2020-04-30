local View = require "core.view"
local config = require "core.config"

function View:on_mouse_wheel(y)
  if self.scrollable then
    self.scroll.to.y = self.scroll.to.y + y * -config.mouse_wheel_scroll
     local x1, y1, x2, y2 = self:get_content_bounds()
     self.scroll.to.y = math.max(math.min(self.scroll.to.y, math.max(self:get_scrollable_size() - (y2 - y1), 0) + config.scrolloff), -config.scrolloff)
   end
end

config.scrolloff = 100
