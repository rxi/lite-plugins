local core = require "core"
local command = require "core.command"
local common = require "core.common"
local syntax = require "core.syntax"

local function dv()
  return core.active_view
end

command.add(nil, {
  ["doc:change-syntax"] = function()
    local files = {}
    for _, item in ipairs(syntax.items) do
      if type(item.files) == "table" then
        for _, file in ipairs(item.files) do
          table.insert(files, file)
        end
      else
        table.insert(files, item.files)
      end
    end

    core.command_view:enter("Change Syntax", function(text, item)
      dv().syntax = syntax.get(item.text)
      dv().cache = { last_valid = 1 }
    end, function(text)
      local res = common.fuzzy_match(files, text)
      for i, file in ipairs(res) do
        res[i] = { text = file:match("%.%w+") }
      end
      return res
    end)
  end,
})
