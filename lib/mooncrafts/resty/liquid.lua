local liquid = require("mooncrafts.vendor.liquid")
local Lexer, Parser, Interpreter, FileSystem, InterpreterContext
Lexer, Parser, Interpreter, FileSystem, InterpreterContext = liquid.Lexer, liquid.Parser, liquid.Interpreter, liquid.FileSystem, liquid.InterpreterContext
local Liquid
do
  local _class_0
  local _base_0 = {
    renderStr = function(self, str)
      local lexer = Lexer.new(document)
      local parser = Parser.new(lexer)
      local interpreter = Interpreter.new(parser)
      local getHandler
      getHandler = function(path)
        return fs:read(path)
      end
      return interpreter.interpret(InterpreterContext.new(str), nil, nil, FileSystem.new(getHandler))
    end,
    render = function(self, view) end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, fs)
      self.fs = fs
    end,
    __base = _base_0,
    __name = "Liquid"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Liquid = _class_0
end
return Liquid
