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

-- choose the proper function based on filename
function run.choose()
  local doc = core.active_view.doc
  for pattern, func in pairs(config.run_files) do
    if common.match_pattern(doc.filename, pattern) then
      return func
    end
  end
end

-- run the currently open doc
function run.run_doc()
  run.choose()()
end

command.add("core.docview", {
  ["run:run-doc"] = run.run_doc,
})

keymap.add {
  ["f5"] = "run:run-doc",
}

return run
