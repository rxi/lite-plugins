local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"

local function listkeybindings()

  local sOut = ''

  for k, v in pairs(keymap.map) do
    sOut = sOut .. k
    for _, x in ipairs(v) do
      sOut = sOut .. ' ' .. x
    end
    sOut = sOut .. '\n'
  end

  core.root_view:open_doc(core.open_doc())
  core.active_view.doc:text_input(sOut)

end

command.add("core.docview", {
  ["listkeybindings:listkeybindings"] = listkeybindings
})

