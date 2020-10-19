local core = require "core"
local command = require "core.command"

command.add("core.docview", {
  ["zeal:search"] = function()
    core.command_view:enter("Search", function(query)
      system.exec("zeal " .. query)
    end)
  end,
})

