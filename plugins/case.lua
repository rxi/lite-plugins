local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"

command.add("core.docview", {
  ["case:title"] = function()
    core.active_view.doc:replace(function(text)
      text = string.lower(text)
      return text:gsub("%f[%w](%w)", string.upper)
    end)
  end,
})

command.add("core.docview", {
  ["case:upper"] = function()
    core.active_view.doc:replace(function(text)
      return string.upper(text)
    end)
  end,
})

command.add("core.docview", {
  ["case:lower"] = function()
    core.active_view.doc:replace(function(text)
      return string.lower(text)
    end)
  end,
})

command.add("core.docview", {
  ["case:invert"] = function()
    core.active_view.doc:replace(function(text)
      local inverted = ""
      for i = 1, #text do
        if text:sub(i,i):upper() == text:sub(i,i) then
          inverted = inverted .. text:sub(i,i):lower()
        else -- if text:sub(i,i):lower() == text:sub(i,i) then
          inverted = inverted .. text:sub(i,i):upper()
        -- else
          -- inverted = inverted .. text:sub(i,i)
        end
      end
      return inverted
    end)
  end,
})

command.add("core.docview", {
  ["case:sentence"] = function()
    core.active_view.doc:replace(function(text)
      text = text:lower()
      return text:gsub("%.%s%w", string.upper)
    end)
  end,
})

keymap.add { ["alt+u"] = "case:upper" }
keymap.add { ["alt+l"] = "case:lower" }
keymap.add { ["alt+t"] = "case:title" }
keymap.add { ["alt+i"] = "case:invert" }
keymap.add { ["alt+s"] = "case:sentence" }

