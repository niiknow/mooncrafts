local http = require("mooncrafts.http")
local azt = require("mooncrafts.aztable")
local util = require("mooncrafts.util")
local log = require("mooncrafts.log")
local from_json, to_json, table_clone
from_json, to_json, table_clone = util.from_json, util.to_json, util.table_clone
local BUFFER_COUNT, FLUSH_INTERVAL, myopts, dolog, AsyncLogger
BUFFER_COUNT = 1
FLUSH_INTERVAL = 0.01
myopts = { }
dolog = function(self, rsp)
  local v = { }
  local req = rsp.req
  local logs = req.logs or { }
  req.logs = nil
  local rk = (tostring(req.host) .. " " .. tostring(req.path)):gsub("/", "$")
  local time = os.time()
  local btime = os.date("%Y%m%d%H%m%S", time)
  local rtime = 99999999999999 - btime
  btime = os.date("%Y-%m-%d %H:%m:%S", time)
  local rand = math.random(10, 1000)
  local pk = tostring(rtime) .. "_" .. tostring(btime) .. " " .. tostring(rand)
  btime = os.date("%Y%m", time)
  local table_name = "log" .. tostring(btime)
  local opts = azt.item_create({
    tenant = "a",
    table_name = table_name,
    rk = rk,
    pk = pk,
    account_name = myopts.account_name,
    account_key = myopts.account_key
  })
  v.RowKey = rk
  v.PartitionKey = pk
  v.host = req.host
  v.path = req.path
  v.time = req["end"] - req.start
  v.req = to_json(req)
  v.err = tostring(rsp.err)
  v.code = rsp.code
  v.status = rsp.status
  v.headers = to_json(rsp.headers)
  v.body = rsp.body
  if (#logs > 0) then
    v.logs = to_json(logs)
  end
  opts.body = to_json(v)
  opts.useSocket = true
  local res = azt.request(opts, true)
  return res
end
do
  local _class_0
  local _base_0 = {
    dolog = dolog,
    log = function(self, rsp)
      if (ngx) then
        local myrsp = table_clone(rsp)
        local delay = math.random(10, 100)
        local ok, err = ngx.timer.at(delay / 1000, dolog, self, myrsp)
      end
      return self
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = {
          account_name = account_name,
          account_key = account_key
        }
      end
      if (opts.account_name == nil) then
        error("opts.account_name parameter is required")
      end
      if (opts.account_key == nil) then
        error("opts.account_key parameter is required")
      end
      myopts = opts
    end,
    __base = _base_0,
    __name = "AsyncLogger"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  AsyncLogger = _class_0
end
return AsyncLogger
