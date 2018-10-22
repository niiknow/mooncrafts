local sort, concat
do
  local _obj_0 = table
  sort, concat = _obj_0.sort, _obj_0.concat
end
local crypto = require("mooncrafts.crypto")
local util = require("mooncrafts.util")
local log = require("mooncrafts.log")
local AwsAuth
do
  local _class_0
  local _base_0 = {
    get_canonical_header = function(self)
      return concat({
        "content-type:" .. self.options.content_type,
        "host:" .. self.options.aws_host,
        "x-amz-date:" .. self.options.iso_tz
      }, "\n")
    end,
    get_signed_request_body = function(self)
      local params = self.options.request_body
      if type(self.options.request_body) == "table" then
        sort(params)
        params = util.query_string_encode(params)
      end
      local digest = self:get_sha256_digest(params or "")
      return string.lower(digest)
    end,
    get_canonical_request = function(self)
      local param = {
        self.options.request_method,
        self.options.request_path,
        "",
        self:get_canonical_header(),
        "",
        "content-type;host;x-amz-date",
        self:get_signed_request_body()
      }
      local canonical_request = concat(param, "\n")
      return self:get_sha256_digest(canonical_request)
    end,
    get_sha256_digest = function(self, s)
      return crypto.sha256(s).hex()
    end,
    hmac = function(self, secret, message)
      return crypto.hmac(secret, message, crypto.sha256)
    end,
    get_signing_key = function(self)
      local k_date = self:hmac("AWS4" .. self.options.aws_secret_access_key, self.options.iso_date).digest()
      local k_region = self:hmac(k_date, self.options.aws_region).digest()
      local k_service = self:hmac(k_region, self.options.aws_service).digest()
      return self:hmac(k_service, "aws4_request").digest()
    end,
    get_string_to_sign = function(self)
      local param = {
        self.options.iso_date,
        self.options.aws_region,
        self.options.aws_service,
        "aws4_request"
      }
      local cred = concat(param, "/")
      local req = self:get_canonical_request()
      return concat({
        "AWS4-HMAC-SHA256",
        self.options.iso_tz,
        cred,
        req
      }, "\n")
    end,
    get_signature = function(self)
      return self:hmac(self:get_signing_key(), self:get_string_to_sign()).hex()
    end,
    get_auth_header = function(self)
      local param = {
        self.options.aws_access_key_id,
        self.options.iso_date,
        self.options.aws_region,
        self.options.aws_service,
        "aws4_request"
      }
      return concat({
        "AWS4-HMAC-SHA256 Credential=" .. concat(param, "/"),
        "SignedHeaders=content-type;host;x-amz-date",
        "Signature=" .. self:get_signature()
      }, ", ")
    end,
    get_auth_headers = function(self)
      return {
        ["Authorization"] = self:get_auth_header(),
        ["x-amz-date"] = self:get_date_header(),
        ["x-amz-content-sha256"] = self:get_content_sha256(),
        ["Content-Type"] = self.options.content_type
      }
    end,
    get_date_header = function(self)
      return self.options.iso_tz
    end,
    get_content_sha256 = function(self)
      return self:get_sha256_digest("")
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self, options)
      if options == nil then
        options = { }
      end
      local defOpts = {
        timestamp = os.time(),
        aws_host = "s3.amazonaws.com",
        aws_region = "us-east-1",
        aws_service = "s3",
        content_type = "application/x-www-form-urlencoded",
        request_method = "GET",
        request_path = "/",
        request_body = "",
        aws_secret_access_key = "",
        aws_access_key_id = ""
      }
      util.applyDefaults(options, defOpts)
      options.iso_date = os.date("!%Y%m%d", options.timestamp)
      options.iso_tz = os.date("!%Y%m%dT%H%M%SZ", options.timestamp)
      self.options = options
    end,
    __base = _base_0,
    __name = "AwsAuth"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  AwsAuth = _class_0
end
return AwsAuth
