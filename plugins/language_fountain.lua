local syntax = require "core.syntax"
local common = require "core.common"
local style = require "core.style"

style.syntax["header"] = { common.color "#66FF66" }
style.syntax["property"] = { common.color "#888888" }
style.syntax["paren"] = { common.color "#AAAAAA" }
style.syntax["caps"] = { common.color "#6666FF" }

syntax.add {
	files = { "%.fountain$" },
	patterns = {
		{ pattern = { "/%*", "%*/" },       type = "comment"  },
		{ pattern = { "%[%[", "%]%]" },       type = "string"  },
		{ pattern = { "%(", "%)", "\\" },       type = "paren"  },
		{ pattern = "INT[%. ].*\n",       type = "function" },
		{ pattern = "EXT[%. ].*\n",       type = "function" },
		{ pattern = "EST[%. ].*\n",       type = "function" },
		{ pattern = "INT%.?/EXT[%. ].*\n",       type = "function" },
		{ pattern = "I/E[%. ].*\n",       type = "function" },
		{ pattern = "#.*\n",       type = "header" },
		{ pattern = ".*%: .*\n",      type = "property" },
		{ pattern = "[A-Z][^a-z]+\n",      type = "caps" },
	},
	symbols = {
	},
}
