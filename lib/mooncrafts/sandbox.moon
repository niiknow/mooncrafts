-- allow sandbox for execution of both lua and moonscript
-- this is done in best effort
-- during testing with openresty, I find that there are ways
-- you can get out of the sandbox:
-- 1. such as sloppy code that expose global variables on ngx object
-- 2. bad handling of environment variables
-- 3. bad handling of script static in framework

parse   = require "moonscript.parse"
compile = require "moonscript.compile"
util    = require "mooncrafts.util"
log     = require "mooncrafts.log"

table_pack = table.pack or (...) -> { n: select("#", ...), ... }
has_52_compatible_load = _VERSION ~= "Lua 5.1" or tostring(assert)\match "builtin"
pack_1 = (first, ...) -> first, table_pack(...)

loads = has_52_compatible_load and load or (code, name, mode, env) ->
  return nil, "can't load binary chunk" if code.byte(code, 1) == 27

  chunk, err = loadstring(code, name)
  setfenv(chunk, env) if chunk and env
  chunk, err

readfile = (file) ->
  f = io.open(file, "rb")
  content = f\read("*all")
  f\close()
  content

--- List of safe library methods (5.1 to 5.3)
whitelist = [[
_VERSION assert error ipairs next pairs pcall select tonumber tostring type unpack xpcall

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


opts = {plugins: {}}

local *

-- Builds the environment table for a sandbox.
build_env = (src_env, dest_env={}, wl=whitelist) ->
  env = {}
  for name in wl\gmatch "%S+"
    t_name, field = name\match "^([^%.]+)%.([^%.]+)$"
    if t_name
      tbl = env[t_name]
      env_t = src_env[t_name]
      if tbl == nil and env_t
        tbl = {}
        env[t_name] = tbl

      if env_t
        t_tbl = type(tbl)
        assert(t_tbl == "table", "field '" .. t_name .. "' already added as " .. t_tbl)
        tbl[field] = env_t[field]

    else
      val = src_env[name]
      assert(type(val) ~= "table", "can't copy table reference")
      env[name] = val

  env._G = dest_env

  setmetatable(dest_env, { __index: env })

loadstring = (code, name, env=_G) ->
  assert(type(code) == "string", "code must be a string")
  assert(type(env) == "table", "env is required")

  loads(code, name or "sandbox", "t", env)

--- Executes Lua code in a sandbox.
--
-- @param code      Lua source code string.
-- @param name      Name of the chunk (for errors, default "sandbox").
-- @param env       Table used as environment (default a new empty table).
-- @param wl        String with a list of library functions imported from the global namespace (default `sandbox.whitelist`).
-- @return          The `env` where the code was ran, or `nil` in case of error.
-- @return          The chunk return values, or an error message.
loadstring_safe = (code, name, env={}, wl) ->
  env = build_env(_G, env, wl)
  loadstring(code, name, env)

loadfile = (file, env=_G) ->
  assert(type(file) == "string", "file name is required")
  assert(type(env) == "table", "env is required")

  code = readfile(file)
  loadstring(code, file, env)

loadfile_safe = (file, env={}, wl) ->
  env = build_env(_G, env, wl)
  loadfile(file, env)

exec = (fn) ->
  ok, ret = pcall(fn)
  return if ok then ret else nil, ret

exec_code = (code, name, env={}, wl) ->
  fn = loadstring_safe(code, name, env, wl)
  exec(fn)

-- compile moonscript code to lua source, load and execute
-- lua_src = sandbox.compile_moon(rsp.body)
-- fn = sandbox.loadstring_safe(lua_src, 'file name', function_vars)
-- rst, err = sandbox.exec(fn)
compile_moon = (moon_code) ->
  tree, err = parse.string moon_code
  return nil, "Parse error: " .. err unless tree

  lua_code, err, pos = compile.tree tree
  return nil, compile.format_error err, pos, moon_code unless lua_code

  lua_code

{ :build_env, :whitelist, :loadstring, :loadstring_safe, :loadfile, :loadfile_safe, :exec, :exec_code, :compile_moon }
