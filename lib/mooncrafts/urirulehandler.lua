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
compile_list = function(opts)
  opts.req_rules = { }
  opts.res_rules = { }
  for k, r in pairs(opts.rules) do
    r.pattern = compile_pattern(r.source)
    if r.status == nil then
      r.status = 0
    end
    if (r.type == 'response') then
      table_insert(opts.res_rules, r)
    else
      table_insert(opts.req_rules, r)
    end
  end
  return opts
end
local UriRuleHandler
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
          local status = rst.status or 0
          rst.rules = rst.rules or { }
          table_insert(rst.rules, r)
          if (r.dest) then
            rst.target = url.build_with_splats(r.dest, params)
          end
          rst.isRedir = status > 300
          rst.params = params
          if (status > 0) then
            return rst
          end
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
      local _ = rst
      return {
        handleRequest = function(self, ngx, fallbackDest)
          if fallbackDest == nil then
            fallbackDest = "/__fallback"
          end
          rst = parseRedirects(ngx.req)
          if not (rst.dest) then
            rst.target = fallbackDest
          end
          if not (rst.isRedir) then
            ngx.redirect(rst.target, rst.code)
          else
            local rsp = { }
            rst.code = rsp.code
            rst.headers = rsp.headers
          end
          ngx.say(rst.body)
          return ngx.exit(rst.code or ngx.HTTP_OK)
        end
      }
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      local conf = compile_rules(opts)
      self.conf = conf
    end,
    __base = _base_0,
    __name = "UriRuleHandler"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  UriRuleHandler = _class_0
end
return UriRuleHandler