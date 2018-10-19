-- resolve remote file like it's local file
--
-- remotefs = require("mooncrafts.remotefs")
-- fs = remotefs({ngx_path: '/proxy'})
-- content = fs.read("/niiknow/mooncrafts/master/dist.ini")
--

util      = require "mooncrafts.util"
httpc     = require "mooncrafts.http"
url       = require "mooncrafts.url"

import trim, path_sanitize from util

local *

url_parse  = url.parse

class Remotefs
  new: (conf={}) =>
    assert(conf, "conf object is required")
    myConf = {}

    -- default base to github
    myConf.base     = trim(conf.base or "https://raw.githubusercontent.com/", "%/*")
    myConf.ngx_path = conf.ngx_path or "/__mooncrafts"

    @conf = myConf

  readRaw: (location) =>
    -- build location
    url = location
    url = @conf.base .. "/" .. trim(path_sanitize(location), "%/*") if location\find(":") == nil
    ngx.log(ngx.ERR, 'remotefs retrieving: ' .. url)
    req = { url: url, method: "GET", capture_url: @conf.ngx_path, headers: {} }
    httpc.request(req)

  read: (location, default="") =>
    rst = @readRaw(location)

    return default if (rst.err or rst.code < 200 or rst.code > 299)

    rst.body

Remotefs
