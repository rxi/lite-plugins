local core = require "core"
local command = require "core.command"

command.add("core.docview", {
  ["zeal:search"] = function()
    -- Make current selected text appear in the search bar
    local dv = core.active_view
    local sel = { dv.doc:get_selection() }
    local text = dv.doc:get_text(table.unpack(sel))
    core.command_view:set_text(text, true)

    -- Ask for user input
    core.command_view:enter("Search", function(query)
      system.exec("zeal " .. query)
    end)
  end,

})

