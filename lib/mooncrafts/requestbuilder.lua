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
        local path = ngx.var.request_uri
        local port = ngx.var.server_port
        local is_args = ngx.var.is_args
        local args = ngx.var.args
        local queryStringParameters = ngx.req.get_uri_args()
        req = {
          body = ngx.req.get_body_data(),
          form = ngx.req.get_post_args(),
          headers = req_headers,
          host = host,
          http_method = ngx.req.get_method(),
          path = path,
          port = server_port,
          args = args,
          is_args = is_args,
          query_string_parameters = queryStringParameters,
          remote_addr = ngx.var.remote_addr,
          referer = ngx.var.http_referer or "-",
          scheme = ngx.var.scheme,
          server_addr = ngx.var.server_addr,
          user_agent = req_headers["User-Agent"],
          full_uri = tostring(scheme) .. "://$host$path$is_args$args",
          sign_uri = tostring(scheme) .. "://$host:$port$path$is_args$args",
          cb = queryStringParameters.cb,
          language = req_headers["Accept-Language"]
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
