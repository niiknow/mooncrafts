liquid = require "mooncrafts.vendor.liquid"

import Lexer, Parser, Interpreter, FileSystem, InterpreterContext from liquid


class Liquid
  new: (fs) =>
    @fs = fs

  renderStr: (str) =>
    lexer       = Lexer.new(document)
    parser      = Parser.new(lexer)
    interpreter = Interpreter.new(parser)

    getHandler = (path) ->
      fs\read(path)

    return interpreter.interpret( InterpreterContext.new(str), nil, nil, FileSystem.new(getHandler) )

  render: (view) =>


Liquid
