local core = require "core"
local command = require "core.command"

command.add(nil, {
  ["core:open-settings"] = function()
    core.root_view:open_doc(core.open_doc(_EXEDIR .. _PATHSEP .. "data" .. _PATHSEP .. "user" .. _PATHSEP .. "init.lua"))
  end
})
