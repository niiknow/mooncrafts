local liquid = require("mooncrafts.vendor.liquid")
local util = require("mooncrafts.util")
local trim, ends_with
trim, ends_with = util.trim, util.ends_with
local Lexer, Parser, Interpreter, FileSystem, InterpreterContext
Lexer, Parser, Interpreter, FileSystem, InterpreterContext = liquid.Lexer, liquid.Parser, liquid.Interpreter, liquid.FileSystem, liquid.InterpreterContext
local Liquid
do
  local _class_0
  local _base_0 = {
    render = function(self, str, data)
      if data == nil then
        data = { }
      end
      local lexer = Lexer:new(str)
      local parser = Parser:new(lexer)
      local interpreter = Interpreter:new(parser)
      local myfs = self.fs
      local ext = self.ext
      ngx.log(ngx.ERR, 'yo yo yo2 ' .. str)
      local getHandler
      getHandler = function(view)
        if not ends_with(view, ext) then
          view = view .. ext
        end
        ngx.log(ngx.ERR, 'yo yo yo2 ' .. view)
        local rst = myfs:read(view)
        return trim(rst)
      end
      return interpreter:interpret(InterpreterContext:new(data), nil, nil, FileSystem:new(getHandler))
    end,
    renderView = function(self, view, data)
      if data == nil then
        data = { }
      end
      local myfs = self.fs
      if not ends_with(view, self.ext) then
        view = view .. ext
      end
      local rst = myfs:read(view .. ".liquid")
      local file = myfs:read(view)
      return self:render(file, data)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, fs, ext)
      if ext == nil then
        ext = ".liquid"
      end
      self.fs = fs
      self.ext = ext
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
