local crypto = require("mooncrafts.crypto")
local util = require("mooncrafts.util")
local log = require("mooncrafts.log")
local url = require("mooncrafts.url")
local Liquid = require("mooncrafts.resty.liquid")
local Remotefs = require("mooncrafts.remotefs")
local url_parse, compile_pattern, match_pattern, build_with_splats, base64_decode, strlen, string_upper, string_match, trim, string_split, table_extend, table_clone, table_remove, join, table_insert, compile_rules, Router
url_parse = url.parse
compile_pattern = url.compile_pattern
match_pattern = url.match_pattern
build_with_splats = url.build_with_splats
base64_decode = crypto.base64_decode
strlen = string.len
string_upper = string.upper
string_match = string.match
trim = util.trim
string_split = util.string_split
table_extend = util.table_extend
table_clone = util.table_clone
table_remove = table.remove
join = table.concat
table_insert = table.insert
compile_rules = function(opts)
  local req_rules = { }
  local res_rules = { }
  if (opts.rules) then
    for k, rr in pairs(opts.rules) do
      local r = table_clone(rr, true)
      r.pattern = compile_pattern(r["for"])
      if not r.status then
        r.status = 0
      end
      if not r.type then
        r.type = 'request'
      end
      if (r.type == 'response') then
        table_insert(res_rules, r)
      else
        table_insert(req_rules, r)
      end
      if r.dest then
        r.dest = trim(r.dest)
      else
        r.dest = ""
      end
      if not r.headers then
        r.headers = { }
      end
      if r.http_methods then
        r.http_methods = string_upper(r.http_methods)
      else
        r.http_methods = "*"
      end
      if (r.status <= 300 or r.status >= 400) and r.dest:find("/") == 1 then
        r.status = 302
      end
    end
  end
  opts.req_rules = req_rules
  opts.res_rules = res_rules
  return opts
end
do
  local _class_0
  local _base_0 = {
    parseNginxRequest = function(self, ngx)
      if not ngx then
        return { }
      end
      ngx.req.read_body()
      local req_headers = ngx.req.get_headers()
      local scheme = ngx.var.scheme
      local path = trim(ngx.var.request_uri)
      local port = ngx.var.server_port or 80
      local is_args = ngx.var.is_args or ""
      local args = ngx.var.args or ""
      local queryStringParameters = ngx.req.get_uri_args()
      local host = ngx.var.host or "127.0.0.1"
      url = tostring(scheme) .. "://" .. tostring(host) .. tostring(path) .. tostring(is_args) .. tostring(args)
      local path_parts = string_split(trim(path, "/"))
      return {
        body = ngx.req.get_body_data(),
        form = ngx.req.get_post_args(),
        headers = req_headers,
        host = host,
        http_method = ngx.var.request_method,
        path = path,
        path_parts = path_parts,
        port = server_port,
        args = args,
        is_args = is_args,
        query_string_parameters = queryStringParameters,
        remote_addr = ngx.var.remote_addr,
        referer = ngx.var.http_referer or "-",
        scheme = ngx.var.scheme,
        server_addr = ngx.var.server_addr,
        user_agent = ngx.var.http_user_agent,
        url = url,
        sign_url = tostring(scheme) .. "://" .. tostring(host) .. ":" .. tostring(port) .. tostring(path) .. tostring(is_args) .. tostring(args),
        cb = queryStringParameters.cb,
        cookies = ngx.var.http_cookie,
        language = ngx.var.http_accept_language,
        authorization = ngx.var.http_authorization
      }
    end,
    parseBasicAuth = function(self, req)
      assert(req, "request object is required")
      assert(req.headers, "request headers parameter is required")
      local rst = {
        code = 0,
        headers = { },
        rules = { }
      }
      local bauth = self.conf.basic_auth or ""
      if strlen(bauth) > 0 then
        req.headers['authorization'] = nil
        if not req.authorization then
          rst.code = 401
          rst.headers = {
            ["Content-Type"] = "text/plain",
            ["WWW-Authenticate"] = 'realm="Access to site.", charset="UTF-8"'
          }
          rst.body = "Please auth!"
          return rst
        end
        local userpass_b64 = string_match(trim(req.authorization), "Basic%s+(.*)")
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
      if (rst.code > 0) then
        return rst
      end
      local myRules = self.conf.req_rules
      local reqUrl = req.url
      rst.isRedir = false
      for i = 1, #myRules do
        local r = myRules[i]
        if (r.http_methods == "*" or r.http_methods:find(req.http_method)) then
          local match, params = match_pattern(reqUrl, r.pattern)
          if match then
            local status = r.status or 0
            table_insert(rst.rules, r)
            rst.template_data = r.template_data
            if #params > 0 then
              rst.pathParameters = params
            end
            if (strlen(r.dest) > 0) then
              rst.target = r.dest
              if rst.pathParameters then
                rst.target = build_with_splats(r.dest, params)
              end
            end
            rst.isRedir = status > 300
            rst.code = status
            if r.template then
              rst.template = r.template
            end
            if (rst.code > 0) then
              return rst
            end
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
      local myRules = self.conf.res_rules
      local reqUrl = req.url
      for i = 1, #myRules do
        local r = myRules[i]
        if (r.http_methods == "*" or r.http_methods:find(req.http_method)) then
          local match = match_pattern(reqUrl, r.pattern)
          if match then
            table_insert(rst.rules, r)
            table_extend(rst.headers, r.headers)
          end
        end
      end
      return rst
    end,
    handlePage = function(self, ngx, req, rst, proxyPath)
      if proxyPath == nil then
        proxyPath = '/__proxy'
      end
      local path = req.path
      if req.path == "/" then
        path = "/index"
      end
      local base = self.conf.base
      if path ~= "/index" then
        rst.template = "page"
      end
      if not rst.ext then
        rst.ext = "liquid"
      end
      local urls = {
        {
          proxyPath,
          {
            args = {
              target = tostring(base) .. "/templates/" .. tostring(rst.template) .. "." .. tostring(rst.ext)
            }
          }
        },
        {
          proxyPath,
          {
            args = {
              target = tostring(base) .. "/contents" .. tostring(path) .. ".json"
            }
          }
        }
      }
      local page, data = ngx.location.capture_multi(urls)
      if (data and data.status == ngx.HTTP_NOT_FOUND and not rst.template_data) then
        return data
      end
      if rst.template_data then
        req.page = rst.template_data
      else
        req.page = { }
      end
      if (data and data.status < 300) then
        req.page = util.from_json(data.body)
      end
      return {
        code = 200,
        headers = { },
        body = trim(self.viewEngine:render(page.body, req.page))
      }
    end,
    handleProxy = function(self, req, rst, proxyPath)
      if proxyPath == nil then
        proxyPath = '/__proxy'
      end
      req = {
        url = rst.target,
        method = "GET",
        capture_url = proxyPath,
        headers = rst.headers,
        body = rst.body
      }
      return httpc.request(req)
    end,
    handleRequest = function(self, ngx, proxyPath)
      if proxyPath == nil then
        proxyPath = '/__proxy'
      end
      local req = self:parseNginxRequest(ngx)
      local rst = self:parseRedirects(req)
      if req.path == "/" then
        rst.template = "index"
      end
      if not rst.template then
        rst.template = "page"
      end
      if not rst.ext then
        rst.ext = "liquid"
      end
      if rst.isRedir then
        return ngx.redirect(rst.target, rst.code)
      end
      local rules = rst.rules
      for i = 1, #rules do
        local r = rules[i]
        for k, v in pairs(r.headers) do
          if not (k == 'content-length') then
            rst.headers[k] = v
          end
        end
      end
      local page_rst = nil
      if (rst.target) then
        page_rst = self:handleProxy(req, rst, proxyPath)
      else
        page_rst = self:handlePage(ngx, req, rst, proxyPath)
      end
      if (page_rst.code >= 200 or page_rst.code < 300) then
        local headers = page_rst.headers
        local new_headers = self:parseHeaders(req)
        for k, v in pairs(new_headers) do
          if not (k == 'content-length') then
            headers[k] = v
          end
        end
        for k, v in pairs(headers) do
          ngx.header[k] = v
        end
      end
      if (page_rst.body) then
        ngx.say(page_rst.body)
      end
      if (page_rst.code) then
        return ngx.exit(page_rst.code)
      end
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      local conf = compile_rules(opts)
      local fs = Remotefs({
        base = conf.base
      })
      self.viewEngine = Liquid(fs)
      self.conf = conf
    end,
    __base = _base_0,
    __name = "Router"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Router = _class_0
end
return Router
