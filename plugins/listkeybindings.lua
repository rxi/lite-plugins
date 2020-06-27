--[[
    listkeybindings.lua
    creates a new document and lists all key-bindings
    version: 20200627_152637
    originally by SwissalpS

    show-key-binding will list key first then binding
    show-binding-key will list binding first then key

    If sort plugin is installed, the list will also be sorted.
--]]
local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"

local function pasteAndSort(sOut)
  core.root_view:open_doc(core.open_doc())
  core.active_view.doc:text_input(sOut)
  if command.map['sort:sort'] then
    command.perform('doc:select-all')
    command.perform('sort:sort')
    command.perform('doc:select-none')
  end
end

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

  pasteAndSort(sOut)

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

  pasteAndSort(sOut)

end

command.add("core.docview", {
  ["listkeybindings:show-key-binding"] = listKeyBindings,
  ["listkeybindings:show-binding-key"] = listBindingsKey,
})

