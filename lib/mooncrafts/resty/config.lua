local util = require("mooncrafts.util")
local aws_region = os.getenv("AWS_DEFAULT_REGION")
local aws_access_key_id = os.getenv("AWS_S3_KEY_ID")
local aws_secret_access_key = os.getenv("AWS_S3_ACCESS_KEY")
local aws_s3_path = os.getenv("AWS_S3_PATH")
local base_host = os.getenv("BASE_HOST")
local remote_path = os.getenv("REMOTE_PATH")
local string_split, table_clone, string_connection_parse
string_split, table_clone, string_connection_parse = util.string_split, util.table_clone, util.string_connection_parse
local insert
insert = table.insert
local upper
upper = string.upper
local Config
do
  local _class_0
  local _base_0 = {
    get = function(self)
      return table_clone(self.__data, true)
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, newOpts)
      if newOpts == nil then
        newOpts = { }
      end
      local defaultOpts = {
        remote_path = remote_path,
        base_host = base_host,
        aws = {
          aws_region = aws_region,
          aws_access_key_id = aws_access_key_id,
          aws_secret_access_key = aws_secret_access_key,
          aws_s3_path = aws_s3_path
        }
      }
      util.applyDefaults(newOpts, defaultOpts)
      self.__data = newOpts
    end,
    __base = _base_0,
    __name = "Config"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  Config = _class_0
end
return Config
