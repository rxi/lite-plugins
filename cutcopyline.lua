local core = require "core"
local command = require "core.command"

local function doc()
  return core.active_view.doc
end

local cut_command = command.map["doc:cut"]
local copy_command = command.map["doc:copy"]

command.map["doc:cut"] = nil
command.map["doc:copy"] = nil

command.add(nil, {
  ["doc:cut"] = function()
    local line1, col1, line2, col2 = doc():get_selection(true)
    if line1 == line2 and col1 == col2 then
      if line1 == #doc().lines then
        system.set_clipboard(doc():get_text(line1 - 1, math.huge, line1, math.huge))
        doc():remove(line1 - 1, math.huge, line1, math.huge)
        doc():set_selection(line1 - 1, math.huge, line1 - 1, math.huge)
      else
        system.set_clipboard(doc():get_text(line1, 1, line1 + 1, 1))
        doc():remove(line1, 1, line1 + 1, 1)
        doc():set_selection(line1, 1, line1, 1)
      end
    else
      cut_command.perform()
    end
  end,
  ["doc:copy"] = function()
    local line1, col1, line2, col2 = doc():get_selection(true)
    if line1 == line2 and col1 == col2 then
      system.set_clipboard(doc():get_text(line1, 1, line1, math.huge) .. '\n')
    else
      copy_command.perform()
    end
  end,
})

