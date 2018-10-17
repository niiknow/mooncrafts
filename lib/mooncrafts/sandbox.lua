local parse = require("moonscript.parse")
local compile = require("moonscript.compile")
local util = require("mooncrafts.util")
local log = require("mooncrafts.log")
local table_pack = table.pack or function(...)
  return {
    n = select("#", ...),
    ...
  }
end
local has_52_compatible_load = _VERSION ~= "Lua 5.1" or tostring(assert):match("builtin")
local pack_1
pack_1 = function(first, ...)
  return first, table_pack(...)
end
local loads = has_52_compatible_load and load or function(code, name, mode, env)
  if code.byte(code, 1) == 27 then
    return nil, "can't load binary chunk"
  end
  local chunk, err = loadstring(code, name)
  if chunk and env then
    setfenv(chunk, env)
  end
  return chunk, err
end
local readfile
readfile = function(file)
  local f = io.open(file, "rb")
  local content = f:read("*all")
  f:close()
  return content
end
local whitelist = [[_VERSION assert error ipairs next pairs pcall select tonumber tostring type unpack xpcall

bit32.arshift bit32.band bit32.bnot bit32.bor bit32.btest bit32.bxor bit32.extract bit32.lrotate
bit32.lshift bit32.replace bit32.rrotate bit32.rshift

coroutine.create coroutine.isyieldable coroutine.resume coroutine.running coroutine.status
coroutine.wrap coroutine.yield

math.abs math.acos math.asin math.atan math.atan2 math.ceil math.cos math.cosh math.deg math.exp
math.floor math.fmod math.frexp math.huge math.ldexp math.log math.log10 math.max math.maxinteger
math.min math.mininteger math.mod math.modf math.pi math.pow math.rad math.random math.sin
math.sinh math.sqrt math.tan math.tanh math.tointeger math.type math.ult

os.clock os.difftime os.time

string.byte string.char string.find string.format string.gmatch string.gsub string.len string.lower
string.match string.pack string.packsize string.rep string.reverse string.sub string.unpack
string.upper

table.concat table.insert table.maxn table.pack table.remove table.sort table.unpack

utf8.char utf8.charpattern utf8.codepoint utf8.codes utf8.len utf8.offset
]]
local opts = {
  plugins = { }
}
local build_env, loadstring, loadstring_safe, loadfile, loadfile_safe, exec, exec_code, compile_moon
build_env = function(src_env, dest_env, wl)
  if dest_env == nil then
    dest_env = { }
  end
  if wl == nil then
    wl = whitelist
  end
  local env = { }
  for name in wl:gmatch("%S+") do
    local t_name, field = name:match("^([^%.]+)%.([^%.]+)$")
    if t_name then
      local tbl = env[t_name]
      local env_t = src_env[t_name]
      if tbl == nil and env_t then
        tbl = { }
        env[t_name] = tbl
      end
      if env_t then
        local t_tbl = type(tbl)
        assert(t_tbl == "table", "field '" .. t_name .. "' already added as " .. t_tbl)
        tbl[field] = env_t[field]
      end
    else
      local val = src_env[name]
      assert(type(val) ~= "table", "can't copy table reference")
      env[name] = val
    end
  end
  env._G = dest_env
  return setmetatable(dest_env, {
    __index = env
  })
end
loadstring = function(code, name, env)
  if env == nil then
    env = _G
  end
  assert(type(code) == "string", "code must be a string")
  assert(type(env) == "table", "env is required")
  return loads(code, name or "sandbox", "t", env)
end
loadstring_safe = function(code, name, env, wl)
  if env == nil then
    env = { }
  end
  env = build_env(_G, env, wl)
  return loadstring(code, name, env)
end
loadfile = function(file, env)
  if env == nil then
    env = _G
  end
  assert(type(file) == "string", "file name is required")
  assert(type(env) == "table", "env is required")
  local code = readfile(file)
  return loadstring(code, file, env)
end
loadfile_safe = function(file, env, wl)
  if env == nil then
    env = { }
  end
  env = build_env(_G, env, wl)
  return loadfile(file, env)
end
exec = function(fn)
  local ok, ret = pcall(fn)
  if ok then
    return ret
  else
    return nil, ret
  end
end
exec_code = function(code, name, env, wl)
  if env == nil then
    env = { }
  end
  local fn = loadstring_safe(code, name, env, wl)
  return exec(fn)
end
compile_moon = function(moon_code)
  local tree, err = parse.string(moon_code)
  if not (tree) then
    return nil, "Parse error: " .. err
  end
  local lua_code, pos
  lua_code, err, pos = compile.tree(tree)
  if not (lua_code) then
    return nil, compile.format_error(err, pos, moon_code)
  end
  return lua_code
end
return {
  build_env = build_env,
  whitelist = whitelist,
  loadstring = loadstring,
  loadstring_safe = loadstring_safe,
  loadfile = loadfile,
  loadfile_safe = loadfile_safe,
  exec = exec,
  exec_code = exec_code,
  compile_moon = compile_moon
}
