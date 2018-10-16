-- implement async or bulk logging

http    = require "mooncrafts.http"
azt     = require "mooncrafts.aztable"
util    = require "mooncrafts.util"
log     = require "mooncrafts.log"

import from_json, to_json, table_clone from util

local *

-- number of items when flush
  -- currently set to 1 until we get azure bulk to work
BUFFER_COUNT = 1

-- time between flush
  -- currently set to very low until we get azure bulk to work
FLUSH_INTERVAL = 0.01

class AsyncLogger
  new: (opts={:account_name, :account_key}) =>
    if (opts.account_name == nil)
        error("opts.account_name parameter is required")

    if (opts.account_key == nil)
        error("opts.account_key parameter is required")

    @opts = opts

  dolog: (rsp) =>
    v = {}
    req = rsp.req
    logs = req.logs
    req.logs= nil

    -- replace illegal forward slash char
    rk = "#{req.host} #{req.path}"\gsub("/", "$")
    time = os.time()
    btime = os.date("%Y%m%d%H%m%S",time)
    rtime = 99999999999999 - btime
    btime = os.date("%Y-%m-%d %H:%m:%S", time)
    rand = math.random(10, 1000)
    pk = "#{rtime}_#{btime} #{rand}"
    btime = os.date("%Y%m", time)
    table_name = "log#{btime}"

    opts = azt.item_create({
      tenant: "a",
      table_name: table_name,
      rk: rk,
      pk: pk,
      account_name: @opts.account_name,
      account_key: @opts.account_key
    })

    v.RowKey = rk
    v.PartitionKey = pk
    v.host = req.host
    v.path = req.path
    v.time = req.end - req.start
    v.req = to_json(req)
    v.err = tostring(rsp.err)
    v.code = rsp.code
    v.status = rsp.status
    v.headers = to_json(rsp.headers)
    v.body = rsp.body

    if (#logs > 0)
      v.logs = to_json(logs)

    opts.body = to_json(v)
    opts.useSocket = true
    res = azt.request(opts, true)
    res

  log: (rsp) =>
    if (ngx)
      myrsp = table_clone(rsp)
      delay = math.random(10, 100)
      ok, err = ngx.timer.at(delay / 1000, @dolog, self, myrsp)

AsyncLogger
