local core = require "core"
local command = require "core.command"


if system.list_dir(EXEDIR .. "/data/user") then
  core.error("You must remove " .. EXEDIR .. "/data/user before using this plugin.")
  print("You must remove " .. EXEDIR .. "/data/user before using this plugin.")
  core.error("Tip: Move its to ~/.lite, but do not forget to rename init.lua to user.lua")
  print("Tip: Move its to ~/.lite, but do not forget to rename init.lua to user.lua")
  return
end

local home = os.getenv("HOME")
local user_config_dir

if home then
  user_config_dir = home .. "/.lite/"
  if os.getenv("XDG_CONFIG_HOME") then
    if system.list_dir(os.getenv("XDG_CONFIG_HOME") .. "/lite/") then
      user_config_dir = os.getenv("XDG_CONFIG_HOME") .. "/lite/"
    end
  end
  if system.list_dir(home .. "/.config/lite/") then
    user_config_dir = home .. "/.config/lite/"
  end
else
  home = os.getenv("HOME")
  user_config_dir = home .. "\\lite\\"
end

if not system.list_dir(user_config_dir) then
  os.execute("mkdir " .. user_config_dir)
  io.open(user_config_dir .. "user.lua", "w"):write([[
-- put user settings here
-- this module will be loaded after everything else when the application starts
-- before loading a plugin or theme, you must put the files in the suitable places
-- ex: put all themes in ]] .. user_config_dir .. [[colors

local keymap = require "core.keymap"
local config = require "core.config"
local style = require "core.style"

-- set theme:
-- require "colors.summer"

-- key binding:
-- keymap.add { ["ctrl+escape"] = "core:quit" }

-- load plugin:
-- require "plugins_loader"
]]):close()
end

package.path = package.path .. ";" .. user_config_dir .. "/?.lua"

command.map["core:open-user-module"] = {
  predicate = function() return true end,
  perform = function()
    core.root_view:open_doc(core.open_doc(user_config_dir .. "user.lua"))
  end
}

return { user_config_dir = user_config_dir }
