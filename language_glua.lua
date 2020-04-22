local syntax = require("core.syntax")
--[[
    GLUA Highlighter
    Written by github.com/orionman

    To install replace language_lua.lua with this file, make sure to delete it (:
]]--

local sym = {
    ["if"]       = "keyword",
    ["then"]     = "keyword",
    ["else"]     = "keyword",
    ["elseif"]   = "keyword",
    ["end"]      = "keyword",
    ["do"]       = "keyword",
    ["function"] = "keyword",
    ["repeat"]   = "keyword",
    ["until"]    = "keyword",
    ["while"]    = "keyword",
    ["for"]      = "keyword",
    ["break"]    = "keyword",
    ["return"]   = "keyword",
    ["local"]    = "keyword",
    ["in"]       = "keyword",
    ["not"]      = "keyword",
    ["and"]      = "keyword",
    ["or"]       = "keyword",
    ["self"]     = "keyword2",
    ["true"]     = "literal",
    ["false"]    = "literal",
    ["nil"]      = "literal",
    ------------------------------------ CLASSNAMES
    ["ENT"]         = "keyword2",
    ["SWEP"]        = "keyword2",
    ["EFFECT"]      = "keyword2",
    ["GM"]          = "keyword2",
    ["PANEL"]       = "keyword2",
    ["NEXTBOT"]     = "keyword2",
    ["PLAYER"]      = "keyword2",
    ["SANDBOX"]     = "keyword2",
    ["TOOL"]        = "keyword2",
    ------------------------------------ DERMA (Only common elements since im lazy (: )
    ["DPanel"]          = "keyword2",
    ["DFrame"]          = "keyword2",
    ["DLabel"]          = "keyword2",
    ["DButton"]         = "keyword2",
    ["DCheckBox"]       = "keyword2",
    ["DCheckBoxLabel"]  = "keyword2",
    ["DTextEntry"]      = "keyword2",
    ["AvatarImage"]     = "keyword2",

    ------------------------------------ SHADERS
    ["g_bloom"]             = "keyword2",
    ["g_blurx"]             = "keyword2",
    ["g_blury"]             = "keyword2",
    ["g_bokehblur"]         = "keyword2",
    ["g_colourmodify"]      = "keyword2",
    ["g_downsample"]        = "keyword2",
    ["g_premultiplied"]     = "keyword2",
    ["g_refract"]           = "keyword2",
    ["g_sharpen"]           = "keyword2",
    ["g_sky"]               = "keyword2",
    ["g_sunbeams"]          = "keyword2",
    ["g_texturize"]         = "keyword2",
    ["gmodscreenspace"]     = "keyword2",
    ["sobel"]               = "keyword2",
    
}

local pat = {
    { pattern = {'"', '"', '\\' },         type = "string"   },
    { pattern = {"'", "'", '\\' },         type = "string"   },
    { pattern = {"%[%[", "%]%]" },         type = "string"   },
    { pattern = {"--%[%[", "%]%]"},        type = "comment"  },
    { pattern = {"%/%*", "%*%/"},          type = "comment"  },
    { pattern = "%-%-.-\n",                type = "comment"  },
    { pattern = "-?0x%x+",                 type = "number"   },
    { pattern = "-?%d+[%d%.eE]*",          type = "number"   },
    { pattern = "-?%.?%d+",                type = "number"   },
    { pattern = "[%a_][%w_]*%s*[:(\"{]",   type = "operator" },
    { pattern = "%.%.%.?",                 type = "operator" },
    { pattern = "[<>~=]=",                 type = "operator" },
    { pattern = "[%+%-=/%*%^%%#<>!]",      type = "operator" },
    { pattern = "[%a_][%w_]*%s*[(\"{]+",   type = "function" },
    { pattern = "[%a_][%w_]*",             type = "symbol"   },
}







syntax.add({
  files = "%.lua$",
  comment = "//",
  patterns = pat,
  symbols = sym
})

