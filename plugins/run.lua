local core = require "core"
local common = require "core.common"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"

local run = {}

-- return a function which will run the current doc
-- as a script for the given language
function run.lang(lang)
  return function()
    local doc = core.active_view.doc
    if doc.filename then
      doc:save()
    else
      core.error("Cannot run an unsaved file")
      return
    end

    core.log "Running a file..."
    local cmd = assert(config.run[lang]):format(
      "\"" .. core.active_view.doc.filename .. "\""
    )

    os.execute(config.run_cmd:format(cmd))
  end
end

-- file extensions and functions
config.run_files = {
  ["%.py$"] = run.lang "python",
  ["%.pyw$"] = run.lang "python",
  ["%.lua$"] = run.lang "lua",
  ["%.c$"] = run.lang "c",
}

-- system commands for running files
-- the filename is already quoted
config.run = {
  python = "python %s",
  lua = "lua %s",
  c = "gcc %s && " .. (PLATFORM == "Windows" and "a.exe" or "./a.out"),
}

-- for systems other than Windows
if PLATFORM == "Windows" then
  config.run_cmd = "start cmd /c \"call %s & pause\""
else
  config.run_cmd = "gnome-terminal -x sh -c \"%s; bash\""
end

local function compare_length(a, b)
  return a.length > b.length
end

-- choose the proper function based on filename
function run.choose()
  local doc = core.active_view.doc
  local res = {}
  for pattern, func in pairs(config.run_files) do
    local s, e = common.match_pattern(doc.filename, pattern)
    if s then
      table.insert(res, { func=func, length=e-s })
    end
  end
  if #res == 0 then return false end
  table.sort(res, compare_length)
  return res[1].func
end

-- run the currently open doc
function run.run_doc()
  local func = run.choose()
  if not func then
    core.error "No matching run configuration was found"
    return
  end
  func()
end

command.add("core.docview", {
  ["run:run-doc"] = run.run_doc,
})

keymap.add {
  ["f5"] = "run:run-doc",
}

return run
