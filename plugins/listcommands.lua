--[[
    listcommands.lua
    creates a new document and lists commands available to current context
    version: 20200627_151604
    originally by SwissalpS

    The list will be different if, for example log view is active opposed
    to a document.
    If sort plugin is installed, the list will also be sorted.
--]]
local core = require "core"
local command = require "core.command"

local function pasteAndSort(sOut)
  core.root_view:open_doc(core.open_doc())
  core.active_view.doc:text_input(sOut)
  if command.map['sort:sort'] then
    command.perform('doc:select-all')
    command.perform('sort:sort')
    command.perform('doc:select-none')
  end
end

local function listCommands()

  local tCommands = command.get_all_valid()
  local sOut = ''
  for _, sCommand in ipairs(tCommands) do
    sOut = sOut .. sCommand .. '\n'
  end

  pasteAndSort(sOut)

end

command.add(nil, {
  ["listcommands:listcommands"] = listCommands,
})

