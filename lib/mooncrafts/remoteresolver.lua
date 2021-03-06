local util = require("mooncrafts.util")
local httpc = require("mooncrafts.http")
local log = require("mooncrafts.log")
local url = require("mooncrafts.url")
local extension = os.getenv("MOONCRAFTS_EXT") or ".moon"
local trim, path_sanitize, url_build
trim, path_sanitize, url_build = util.trim, util.path_sanitize, util.url_build
local url_parse, loadcode, resolve_remote, resolve_github, resolve
url_parse = url.parse
loadcode = function(url)
  local req = {
    url = url,
    method = "GET",
    capture_url = "/__mooncrafts",
    headers = { }
  }
  local res, err = httpc.request(req)
  if not (err) then
    return res
  end
  return {
    body = err
  }
end
resolve_remote = function(modname)
  local parsed = url_parse(modname)
  local file
  parsed.basepath, file = string.match(parsed.path, "^(.*)/([^/]*)$")
  parsed.file = trim(file, "/*") or ""
  if not (parsed.basepath) then
    parsed.basepath = "/"
  end
  return parsed
end
resolve_github = function(modname)
  modname = modname:gsub("github%.com/", "https://raw.githubusercontent.com/")
  local parsed = resolve_remote(modname)
  local user, repo, blobortree, branch, rest = string.match(parsed.basepath, "(/[^/]+)(/[^/]+)(/[^/]+)(/[^/]+)(.*)")
  parsed.basepath = path_sanitize(tostring(user) .. tostring(repo) .. tostring(branch) .. tostring(rest))
  parsed.path = tostring(parsed.basepath) .. "/" .. tostring(parsed.file)
  parsed.github = true
  return parsed
end
resolve = function(modname, opts)
  if opts == nil then
    opts = {
      plugins = { }
    }
  end
  local extReg = "%" .. extension .. "$"
  local originalName = tostring(modname):gsub(extReg, "")
  local rst = { }
  if modname:find("http") == 1 then
    rst = resolve_remote(modname)
  end
  if modname:find("github%.com/") == 1 then
    rst = resolve_github(modname)
  end
  local remotebase = opts.plugins._remotebase
  if remotebase and rst.path == nil then
    local remotemodname = tostring(remotebase) .. "/" .. tostring(modname)
    if remotemodname:find("http") == 1 then
      rst = resolve_remote(remotemodname)
    end
    rst._remotebase = remotebase
    rst.isrelative = true
  end
  if not (rst.path) then
    return {
      path = modname
    }
  end
  rst.file = rst.file:gsub(extReg, ""):gsub('%.', "/") .. extension
  rst.path = rst.path:gsub(extReg, ""):gsub('%.', "/") .. extension
  local oldpath = rst.path
  rst.path = path_sanitize(rst.basepath)
  rst.basepath = url_build(rst, false)
  rst.path = oldpath
  rst.codeloader = loadcode
  if not (rst.isrelative) then
    rst._remotebase = trim(rst.basepath, "%/*")
  end
  return rst
end
return {
  resolve = resolve,
  resolve_github = resolve_github,
  resolve_remote = resolve_remote,
  loadcode = loadcode
}
