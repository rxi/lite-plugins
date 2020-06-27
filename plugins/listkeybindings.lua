local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"

local function gatherLists()

  local lKeys = {}
  local lBindings = {}
  local iLongestKey = 0
  local iLongestBinding = 0
  local iIndex = 0

  for k, v in pairs(keymap.map) do
    if iLongestKey < #k then iLongestKey = #k end
    for _, x in ipairs(v) do
      iIndex = iIndex + 1
      if iLongestBinding < #x then iLongestBinding = #x end
      lKeys[iIndex] = k
      lBindings[iIndex] = x
    end
  end

  return lKeys, lBindings, iLongestKey, iLongestBinding

end -- gatherLists

local function listBindingsKey()

  local sOut = ''
  local lKeys, lBindings, iLongestKey, iLongestBinding = gatherLists()

  -- format pretty output
  local sSpace, k, v
  local iLongest = iLongestBinding + 1
  for i = 1, #lKeys, 1 do
    k = lBindings[i]
    v = lKeys[i]
    sSpace = string.rep(' ', iLongest - #k)
    sOut = sOut .. k .. sSpace .. v .. '\n'
  end

  core.root_view:open_doc(core.open_doc())
  core.active_view.doc:text_input(sOut)

end

local function listKeyBindings()

  local sOut = ''
  local lKeys, lBindings, iLongestKey, iLongestBinding = gatherLists()

  -- format pretty output
  local sSpace, k, v
  local iLongest = iLongestKey + 1
  for i = 1, #lKeys, 1 do
    v = lBindings[i]
    k = lKeys[i]
    sSpace = string.rep(' ', iLongest - #k)
    sOut = sOut .. k .. sSpace .. v .. '\n'
  end

  core.root_view:open_doc(core.open_doc())
  core.active_view.doc:text_input(sOut)

end

command.add("core.docview", {
  ["listkeybindings:show-key-binding"] = listKeyBindings,
  ["listkeybindings:show-binding-key"] = listBindingsKey,
})

