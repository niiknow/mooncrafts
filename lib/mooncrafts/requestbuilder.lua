local sandbox = require("mooncrafts.sandbox")
local util = require("mooncrafts.util")
local RequestBuilder
do
  local _class_0
  local _base_0 = {
    build = function(self, opts)
      local req = { }
      if ngx then
        ngx.req.read_body()
        local req_headers = ngx.req.get_headers()
        local scheme = ngx.var.scheme
        local path = trim(ngx.var.request_uri)
        local port = ngx.var.server_port or 80
        local is_args = ngx.var.is_args or ""
        local args = ngx.var.args or ""
        local queryStringParameters = ngx.req.get_uri_args()
        local host = ngx.var.host or "127.0.0.1"
        local url = tostring(scheme) .. "://" .. tostring(host) .. tostring(path) .. tostring(is_args) .. tostring(args)
        local path_parts = string_split(trim(path, "/"))
        local _ = {
          body = ngx.req.get_body_data(),
          form = ngx.req.get_post_args(),
          headers = req_headers,
          host = host,
          http_method = ngx.var.request_method,
          path = path,
          path_parts = split,
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
        self.req = req
      end
      self.req.logs = { }
      return self
    end,
    set = function(self, req)
      self.req = req
      return self
    end,
    log = function(self, obj)
      local logs = self.req.logs
      if (type(obj == "table")) then
        self.req.logs[#logs + 1] = util.to_json(obj)
      else
        self.req.logs[#logs + 1] = tostring(t)
      end
      return self
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, opts)
      if opts == nil then
        opts = { }
      end
      self.req = opts
    end,
    __base = _base_0,
    __name = "RequestBuilder"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  RequestBuilder = _class_0
end
return RequestBuilder
