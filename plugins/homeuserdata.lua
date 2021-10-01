local core = require "core"
local command = require "core.command"
local CommandView = require "core.commandview"

-- don't execute plugin on windows
if package.cpath:match("%p[\\|/]?%p(%a+)") == "dll" then
  return
end

-- check if home directory is set
local home_dir = os.getenv("HOME")

if not home_dir then
  return
end

-- user configurations path in order of preference
local configs = {
  home_dir .. "/.config/lite",
  home_dir .. "/.lite"
}

-- load user settings
for i,dir in ipairs(configs) do
  if system.get_file_info(dir) then
    package.path = package.path .. ";" .. dir .. "/?/init.lua"
    package.path = package.path .. ";" .. dir .. "/?.lua"

    if system.get_file_info(dir .. "/init.lua") then
      local init = loadfile(dir .. "/init.lua")
      init()
    end

    break
  end
end

command.add(nil, {
  ["core:open-home-user-module"] = function()
    local directory = nil
    for i,dir in ipairs(configs) do
      if system.get_file_info(dir) then
        directory = dir
      end
    end
    if not directory then
      directory = home_dir .. "/.config/lite"
      os.execute("mkdir -p " .. directory)
    end

    local filename = directory .. "/init.lua"

    if system.get_file_info(filename) then
      core.root_view:open_doc(core.open_doc(filename))
    else
      local doc = core.open_doc()
      core.root_view:open_doc(doc)

      local content = "-- put user settings here\n\n"
        .. "local keymap = require \"core.keymap\"\n"
        .. "local config = require \"core.config\"\n"
        .. "local style = require \"core.style\"\n\n"
        .. "-- load plugins from " .. directory .. "/plugins:\n"
        .. "-- require \"plugins.myplugin\"\n\n"
        .. "-- load themes from " .. directory .. "/colors:\n"
        .. "-- require \"colors.mytheme\"\n\n"
        .. "-- key binding:\n"
        .. "-- keymap.add { [\"ctrl+escape\"] = \"core:quit\" }\n"

      doc:insert(1, 1, content)
      doc:save(filename)
    end
  end,
})
