local util = require("mooncrafts.util")
local httpc = require("mooncrafts.http")
local url = require("mooncrafts.url")
local trim, path_sanitize
trim, path_sanitize = util.trim, util.path_sanitize
local url_parse, Remotefs
url_parse = url.parse
do
  local _class_0
  local _base_0 = {
    readRaw = function(self, location)
      url = location
      if location:find(":") == nil then
        url = self.conf.base .. "/" .. trim(path_sanitize(location), "%/*")
      end
      ngx.log(ngx.ERR, 'remotefs retrieving: ' .. url)
      local req = {
        url = url,
        method = "GET",
        capture_url = self.conf.ngx_path,
        headers = { }
      }
      return httpc.request(req)
    end,
    read = function(self, location, default)
      if default == nil then
        default = ""
      end
      local rst = self:readRaw(location)
      if (rst.err or rst.code < 200 or rst.code > 299) then
        return default
      end
      return rst.body
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, conf)
      if conf == nil then
        conf = { }
      end
      assert(conf, "conf object is required")
      local myConf = { }
      myConf.base = trim(conf.base or "https://raw.githubusercontent.com/", "%/*")
      myConf.ngx_path = conf.ngx_path or "/__mooncrafts"
      self.conf = myConf
    end,
    __base = _base_0,
    __name = "Remotefs"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Remotefs = _class_0
end
return Remotefs
