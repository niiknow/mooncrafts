liquid  = require "mooncrafts.vendor.liquid"
util    = require "mooncrafts.util"

import trim, ends_with from util
import Lexer, Parser, Interpreter, FileSystem, InterpreterContext from liquid


class Liquid
  new: (fs, ext=".liquid") =>
    -- ngx.log(ngx.ERR, 'yo yo yo1 ' .. util.to_json(fs.conf))
    @fs  = fs
    @ext = ext

  render: (str, data={}) =>
    lexer       = Lexer\new(str)
    parser      = Parser\new(lexer)
    interpreter = Interpreter\new(parser)
    myfs        = @fs
    ext         = @ext

    -- ngx.log(ngx.ERR, 'yo yo yo2 ' .. str)
    getHandler = (view) ->
      view ..= ext if not ends_with(view, ext)
      -- ngx.log(ngx.ERR, 'yo yo yo2 ' .. view)
      rst = trim(myfs\read(view))
      ngx.log(ngx.ERR, 'yo yo yo2 ' .. rst)
      rst

    interpreter\interpret( InterpreterContext\new(data), nil, nil, FileSystem\new(getHandler) )

  renderView: (view, data={}) =>
    myfs = @fs
    -- ngx.log(ngx.ERR, 'yo yo yo2 ' .. util.to_json(myfs.conf))
    view ..= ext if not ends_with(view, @ext)

    rst = myfs\read(view .. ".liquid")
    file = myfs\read(view)
    @render(file, data)

Liquid
