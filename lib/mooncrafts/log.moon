-- implement singleton log

logger           = require "log"
list_writer      = require "log.writer.list"
console_color    = require "log.writer.console.color"
util             = require "mooncrafts.util"
to_json          = util.to_json

doformat = (p) ->
  if type(p) == "table"
    return to_json p

  if p == nil
    return "nil"

  tostring(p)

sep = ' '

formatter = (...) ->
  params = [doformat(v) for v in *{...}]

  table.concat(params, sep)

local *

log = logger.new( "info", list_writer.new( console_color.new() ), formatter )

log
