local util = require("mooncrafts.util")
local log = require("mooncrafts.log")
local url = require("mooncrafts.url")
local crypto = require("mooncrafts.crypto")
local table_sort = table.sort
local compile_pattern = url.compile_pattern
local base64_decode = crypto.base64_decode
local trim = util.trim
local strlen = string.len
local table_extend = util.table_extend
local table_insert = table.insert
local compile_list
compile_list = function(self, myList)
  if myList == nil then
    return { }
  end
  for i = 1, #myList do
    local r = myList[i]
    r.pattern = compile_pattern(v.source)
    if r.status == nil then
      r.status = 0
    end
  end
end
local SimpleRouter
do
  local _class_0
  local _base_0 = {
    parseBasicAuth = function(self, req)
      assert(req, "request object is required")
      assert(req.headers, "request headers parameter is required")
      local rst = {
        code = 0,
        headers = { }
      }
      local bauth = self.conf.basic_auth
      if strlen(bauth) > 0 then
        local authorization = trim(req.headers.authorization or "")
        if strlen(authorization) < 0 then
          rst.code = 401
          rst.headers = {
            ["Content-Type"] = "text/plain",
            ["WWW-Authenticate"] = 'realm="Access to site.", charset="UTF-8"'
          }
          rst.body = "Please auth!"
          return rst
        end
        local userpass_b64 = authorization.match("Basic%s+(.*)")
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
      local rst = { }
      local myRules = self.conf.redirects
      for i = 1, #myRules do
        local r = myRules[i]
        local match, params = url.match(r.pattern, req.url)
        if match then
          rst.rule = r
          rst.target = url.build_with_splats(r.dest, params)
          rst.isRedir = r.status > 300
          return rst
        end
      end
      return rst
    end,
    parseHeaders = function(self, req)
      assert(req, "request object is required")
      assert(req.url, "request url is required")
      local matches = { }
      local myRules = self.conf.redirects
      for i = 1, #myRules do
        local r = myRules[i]
        local match = url.match(r.pattern, req.url)
        if match then
          table_insert(matches, r)
        end
      end
      return matches
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, name, conf)
      if conf == nil then
        conf = { }
      end
      local myConf = conf or { }
      myConf.redirects = compile_list(myConf.redirects)
      myConf.headers = compile_list(myConf.headers)
      myConf.basic_auth = trim(myConf.basic_auth or "")
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
