util      = require "mooncrafts.util"
httpc     = require "mooncrafts.http"
log       = require "mooncrafts.log"
url       = require "mooncrafts.url"

extension = os.getenv("MOONCRAFTS_EXT") or ".moon"

import trim, path_sanitize, url_build from util

local *

url_parse  = url.parse

loadcode   = (url) ->
  req      = { url: url, method: "GET", capture_url: "/__libpublic", headers: {} }
  res, err = httpc.request(req)

  return res unless err

  { code: 0, body: err }

resolve_remote = (modname) ->
  parsed                = url_parse modname
  parsed.basepath, file = string.match(parsed.path, "^(.*)/([^/]*)$")
  parsed.file           = trim(file, "/*") or ""
  parsed.basepath       = "/" unless parsed.basepath
  parsed

-- attempt to parse and store new basepath
resolve_github = (modname) ->
  modname = modname\gsub("github%.com/", "https://raw.githubusercontent.com/")
  parsed  = resolve_remote(modname)
  user, repo, blobortree, branch, rest = string.match(parsed.basepath, "(/[^/]+)(/[^/]+)(/[^/]+)(/[^/]+)(.*)")
  parsed.basepath = path_sanitize("#{user}#{repo}#{branch}#{rest}")
  parsed.path     = "#{parsed.basepath}/#{parsed.file}"
  parsed.github   = true
  parsed

resolve = (modname, opts={plugins: {}}) ->
  extReg       = "%" .. extension .. "$"
  originalName = tostring(modname)\gsub(extReg, "")
  rst = {}

  -- remote is a url, then parse the url
  rst = resolve_remote(modname) if modname\find("http") == 1

  -- if github, then parse and store new basepath
  rst = resolve_github(modname) if modname\find("github%.com/") == 1

  -- if _remotebase, try to parse relative to it
  remotebase = opts.plugins._remotebase

  if remotebase and rst.path == nil
    -- example: {url}/remote/simpson/homer.moon
    -- _remotebase: {url}/remote/simpson
    -- then: children.bart inside of homer would be -> /remote/simpson/children/bart.moon
    remotemodname   = "#{remotebase}/#{modname}"
    rst             = resolve_remote(remotemodname) if remotemodname\find("http") == 1
    rst._remotebase = remotebase
    rst.isrelative  = true

  return { path: modname } unless rst.path

  -- remove .moon extension to convert period to forward slash
  -- then add back moon extension
  -- reprocess rst path by converting all period to forward slash
  -- keep basepath the way it is
  rst.file = rst.file\gsub(extReg, "")\gsub('%.', "/") .. extension
  rst.path = rst.path\gsub(extReg, "")\gsub('%.', "/") .. extension

  -- save old path
  oldpath        = rst.path
  rst.path       = path_sanitize(rst.basepath)
  rst.basepath   = url_build(rst, false)
  rst.path       = oldpath
  rst.codeloader = loadcode

  -- set new _remotebase, unless it's a relative load
  rst._remotebase = trim(rst.basepath, "%/*") unless rst.isrelative
  rst

{ :resolve, :resolve_github, :resolve_remote, :loadcode }
