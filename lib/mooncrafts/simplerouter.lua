local crypto = require("mooncrafts.crypto")
local util = require("mooncrafts.util")
local log = require("mooncrafts.log")
local url = require("mooncrafts.url")
local compile_pattern = url.compile_pattern
local base64_decode = crypto.base64_decode
local trim = util.trim
local strlen = string.len
local table_insert = table.insert
local table_extend = util.table_extend
local string_match = string.match
local compile_list
compile_list = function(myList)
  for k, r in pairs(myList) do
    r.pattern = compile_pattern(r.source)
    if r.status == nil then
      r.status = 0
    end
  end
  return myList
end
local SimpleRouter
do
  local _class_0
  local _base_0 = {
    parseBasicAuth = function(self, req)
      assert(req, "request object is required")
      assert(req.headers, "request headers parameter is required")
      local rst = {
        headers = { }
      }
      local bauth = self.conf.basic_auth
      if strlen(bauth) > 0 then
        local authorization = req.headers.authorization
        if not authorization then
          rst.code = 401
          rst.headers = {
            ["Content-Type"] = "text/plain",
            ["WWW-Authenticate"] = 'realm="Access to site.", charset="UTF-8"'
          }
          rst.body = "Please auth!"
          return rst
        end
        local userpass_b64 = string_match(trim(authorization), "Basic%s+(.*)")
        if not (userpass_b64) then
          rst.code = 401
          rst.headers = {
            ["Content-Type"] = "text/plain"
          }
          rst.body = "Your browser sent a bad Authorization HTTP header!"
          return rst
        end
        local userpass = base64_decode(userpass_b64)
        if not (userpass) then
          rst.code = 401
          rst.headers = {
            ["Content-Type"] = "text/plain"
          }
          rst.body = "Your browser sent a bad Authorization HTTP header!"
          return rst
        end
        if not (bauth == userpass) then
          rst.code = 403
          rst.headers = {
            ["Content-Type"] = "text/plain",
            ["WWW-Authenticate"] = 'realm="Access to site.", charset="UTF-8"'
          }
          rst.body = "Auth failed!"
          return rst
        end
      end
      return rst
    end,
    parseRedirects = function(self, req)
      assert(req, "request object is required")
      assert(req.url, "request url is required")
      local rst = self:parseBasicAuth(req)
      local myRules = self.conf.redirects
      local reqUrl = req.url
      for i = 1, #myRules do
        local r = myRules[i]
        local match, params = url.match_pattern(reqUrl, r.pattern)
        if match then
          rst.rules = rst.rules or { }
          table_insert(rst.rules, r)
          rst.target = url.build_with_splats(r.dest, params)
          rst.isRedir = r.status > 300
          rst.params = params
          return rst
        end
      end
      return rst
    end,
    parseHeaders = function(self, req)
      assert(req, "request object is required")
      assert(req.url, "request url is required")
      local rst = {
        rules = { },
        headers = { }
      }
      local myRules = self.conf.headers
      local reqUrl = req.url
      for i = 1, #myRules do
        local r = myRules[i]
        local match = url.match_pattern(reqUrl, r.pattern)
        if match then
          table_insert(rst.rules, r)
          table_extend(rst.headers, r.headers)
        end
      end
      return rst
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, conf)
      assert(conf, "config object is required")
      local myConf = { }
      myConf.redirects = compile_list(conf.redirects or { })
      myConf.headers = compile_list(conf.headers or { })
      myConf.basic_auth = trim(conf.basic_auth or "")
      self.conf = myConf
    end,
    __base = _base_0,
    __name = "SimpleRouter"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  SimpleRouter = _class_0
end
return SimpleRouter
