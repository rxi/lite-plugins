local syntax = require "core.syntax"

local keywords = {
  "ARRAY", "BEGIN", "CASE", "CONST", "DO", "DOWNTO", "ELSE", "END", "FILE", "FOR",
  "FUNCTION", "GOTO", "IF", "LABEL", "NOT", "OF", "PACKED", "PROCEDURE", "PROGRAM",
  "RECORD", "REPEAT", "SET", "THEN", "TO", "TYPE", "UNTIL", "VAR", "WHILE", "WITH",

  "NOT", "DIV", "MOD", "AND", "OR", "IN", "XOR", "SHL", "SHR"
}

local types = {
  "BYTE", "SHORTINT", "SMALLINT", "WORD", "INTEGER", "CARDINAL", "LONGINT", "LONGWORD",
  "INT64", "QWORD", "REAL", "SINGLE", "EXTENDED", "COMP", "CURRENCY", "BOOLEAN",
  "BYTEBOOL", "WORDBOOL", "LONGBOOL"
}

local literals = {
  "TRUE", "FALSE", "NIL"
}

local symbols = {}

for _, keyword in ipairs(keywords) do
  symbols[keyword:lower()] = "keyword"
  symbols[keyword] = "keyword"
  symbols[keyword:sub(1, 1)..keyword:sub(2):lower()] = "keyword"
end

for _, keyword2 in ipairs(types) do
  symbols[keyword2:lower()] = "keyword2"
  symbols[keyword2] = "keyword2"
  symbols[keyword2:sub(1, 1)..keyword2:sub(2):lower()] = "keyword2"
end

for _, literal in ipairs(literals) do
  symbols[literal:lower()] = "literal"
  symbols[literal] = "literal"
  symbols[literal:sub(1, 1)..literal:sub(2):lower()] = "literal"
end

syntax.add {
  files = "%.pas$",
  comment = "{.-}",
  patterns = {
    { pattern = "{.-}",                  type = "comment"  },
    { pattern = { "(%*", "%*)" },        type = "comment"  },
    { pattern = { '"', '"', '\\' },      type = "string"   },
    { pattern = { "'", "'", '\\' },      type = "string"   },
    { pattern = { "`", "`" },            type = "string"   },
    { pattern = "-?0x%x+",               type = "number"   },
    { pattern = "-?%d+[%d%.eE]*[f]F?",   type = "number"   },
    { pattern = "-?%.?%d+f?",            type = "number"   },
    { pattern = "[%+%-=/%*%^%%<>!~|&:]", type = "operator" },
    { pattern = "[%a_][%w_]*%f[(]",      type = "function" },
    { pattern = "[%a_][%w_]*",           type = "symbol"   },
  },

  symbols = symbols
}
