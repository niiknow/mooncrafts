local util = require("mooncrafts.util")
local azureauth = require("mooncrafts.azauth")
local mydate = require("mooncrafts.date")
local http = require("mooncrafts.http")
local log = require("mooncrafts.log")
local string_gsub = string.gsub
local my_max_number = 9007199254740991
local sharedkeylite, sign
sharedkeylite, sign = azureauth.sharedkeylite, azureauth.sign
local to_json, applyDefaults, trim, table_clone
to_json, applyDefaults, trim, table_clone = util.to_json, util.applyDefaults, util.trim, util.table_clone
local opts_name, item_headers, table_opts, item_list, item_create, item_update, item_retrieve, item_delete, generate_opts, opts_daily, opts_monthly, opts_yearly, create_table, request
opts_name = function(opts)
  if opts == nil then
    opts = {
      table_name = table_name,
      pk = pk,
      prefix = prefix,
      account_key = account_key,
      account_name = account_name
    }
  end
  assert(opts, "opts parameter is required")
  assert(opts.account_name, "opts.account_name parameter is required")
  assert(opts.account_key, "opts.account_key parameter is required")
  if (opts.prefix == nil) then
    opts.prefix = ""
  end
  if (opts.table == nil) then
    opts.table = string.lower(opts.table_name)
    opts.table_name = tostring(opts.prefix) .. tostring(opts.table)
  end
end
item_headers = function(opts, method)
  if method == nil then
    method = "GET"
  end
  opts_name(opts)
  sharedkeylite(opts)
  local hdrs = {
    ["Authorization"] = "SharedKeyLite " .. tostring(opts.account_name) .. ":" .. tostring(opts.sig),
    ["x-ms-date"] = opts.date,
    ["Accept"] = "application/json;odata=nometadata",
    ["x-ms-version"] = "2018-03-28"
  }
  if method == "PUT" or method == "POST" or method == "MERGE" then
    hdrs["Content-Type"] = "application/json"
  end
  if (method == "DELETE") then
    hdrs["If-Match"] = "*"
  end
  return hdrs
end
table_opts = function(opts, method)
  if opts == nil then
    opts = {
      table_name = table_name,
      pk = pk,
      rk = rk
    }
  end
  if method == nil then
    method = "GET"
  end
  local headers = item_headers(opts, method)
  local url = "https://" .. tostring(opts.account_name) .. ".table.core.windows.net/" .. tostring(opts.table_name)
  if method == "DELETE" then
    headers["If-Match"] = nil
  end
  return {
    method = method,
    url = url,
    headers = headers,
    table_name = opts.table_name,
    account_key = opts.account_key,
    account_name = opts.account_name
  }
end
item_list = function(opts, query)
  if opts == nil then
    opts = {
      table_name = table_name
    }
  end
  if query == nil then
    query = {
      filter = filter,
      top = top,
      select = select
    }
  end
  local headers = item_headers(opts, "GET")
  local url = "https://" .. tostring(opts.account_name) .. ".table.core.windows.net/" .. tostring(opts.table_name)
  local qs = ""
  if query.filter then
    qs = tostring(qs) .. "&$filter=" .. tostring(query.filter)
  end
  if query.top then
    qs = tostring(qs) .. "&$top=" .. tostring(query.top)
  end
  if query.select then
    qs = tostring(qs) .. "&$select=" .. tostring(query.select)
  end
  qs = trim(qs, "&")
  local full_path = url
  if qs then
    full_path = tostring(url) .. "?" .. tostring(qs)
  end
  return {
    method = 'GET',
    url = full_path,
    headers = headers,
    table_name = opts.table_name,
    account_key = opts.account_key,
    account_name = opts.account_name
  }
end
item_create = function(opts)
  if opts == nil then
    opts = {
      table_name = table_name
    }
  end
  local headers = item_headers(opts, "POST")
  local url = "https://" .. tostring(opts.account_name) .. ".table.core.windows.net/" .. tostring(opts.table_name)
  return {
    method = "POST",
    url = url,
    headers = headers,
    table_name = opts.table_name,
    account_key = opts.account_key,
    account_name = opts.account_name
  }
end
item_update = function(opts, method)
  if opts == nil then
    opts = {
      table_name = table_name,
      pk = pk,
      rk = rk
    }
  end
  if method == nil then
    method = "PUT"
  end
  opts_name(opts)
  local table = tostring(opts.table_name) .. "(PartitionKey='" .. tostring(opts.pk) .. "',RowKey='" .. tostring(opts.rk) .. "')"
  opts.table_name = table
  local headers = item_headers(opts, method)
  local url = "https://" .. tostring(opts.account_name) .. ".table.core.windows.net/" .. tostring(opts.table_name)
  return {
    method = method,
    url = url,
    headers = headers,
    table_name = opts.table_name,
    account_key = opts.account_key,
    account_name = opts.account_name
  }
end
item_retrieve = function(opts)
  if opts == nil then
    opts = {
      table_name = table_name,
      pk = pk,
      rk = rk
    }
  end
  return item_list(opts, {
    filter = "(PartitionKey eq '" .. tostring(opts.pk) .. "' and RowKey eq '" .. tostring(opts.rk) .. "')",
    top = 1
  })
end
item_delete = function(opts)
  if opts == nil then
    opts = {
      table_name = table_name,
      pk = pk,
      rk = rk
    }
  end
  return item_update(opts, "DELETE")
end
generate_opts = function(opts, format, ts)
  if opts == nil then
    opts = {
      table_name = table_name
    }
  end
  if format == nil then
    format = "%Y%m%d"
  end
  if ts == nil then
    ts = os.time()
  end
  local newopts = util.table_clone(opts)
  newopts.mt_table = newopts.table_name
  newopts.table_name = string_gsub(newopts.mt_table, "%d+$", "") .. os.date(format, ts)
  return newopts
end
opts_daily = function(opts, days, ts)
  if opts == nil then
    opts = {
      table_name = table_name,
      env_id = env_id,
      pk = pk,
      prefix = prefix
    }
  end
  if days == nil then
    days = 1
  end
  if ts == nil then
    ts = os.time()
  end
  local rst = { }
  local multiplier = days and 1 or -1
  local new_ts = ts
  for i = 1, days do
    rst[#rst + 1] = generate_opts(opts, "%Y%m%d", new_ts)
    new_ts = mydate.add_day(new_ts, days)
  end
  return rst
end
opts_monthly = function(opts, months, ts)
  if opts == nil then
    opts = {
      table_name = table_name,
      env_id = env_id,
      pk = pk,
      prefix = prefix
    }
  end
  if months == nil then
    months = 1
  end
  if ts == nil then
    ts = os.time()
  end
  local rst = { }
  local multiplier = days and 1 or -1
  local new_ts = ts
  for i = 1, days do
    rst[#rst + 1] = generate_opts(opts, "%Y%m", new_ts)
    new_ts = mydate.add_month(new_ts, months)
  end
  return rst
end
opts_yearly = function(opts, years, ts)
  if opts == nil then
    opts = {
      table_name = table_name,
      env_id = env_id,
      pk = pk,
      prefix = prefix
    }
  end
  if years == nil then
    years = 1
  end
  if ts == nil then
    ts = os.time()
  end
  local rst = { }
  local multiplier = days and 1 or -1
  local new_ts = ts
  for i = 1, days do
    rst[#rst + 1] = generate_opts(opts, "%Y", new_ts)
    new_ts = mydate.add_year(new_ts, years)
  end
  return rst
end
create_table = function(opts)
  local tableName = opts.table_name
  opts.table_name = "Tables"
  opts.url = ""
  opts.headers = nil
  opts.method = "POST"
  opts.body = nil
  local topts = table_opts(opts, opts.method)
  topts.body = to_json({
    TableName = tableName
  })
  return http.request(topts)
end
request = function(opts, createTableIfNotExists, retry)
  if createTableIfNotExists == nil then
    createTableIfNotExists = false
  end
  if retry == nil then
    retry = 2
  end
  local oldOpts = table_clone(opts)
  local res = http.request(opts)
  if (retry < 10 and res and res.code >= 500 and res.body and (res.body:find("retry") ~= nil)) then
    ngx.sleep(retry)
    local oopts = table_clone(oldOpts)
    res = request(oopts, createTableIfNotExists, retry * 2)
  end
  if (createTableIfNotExists and res and res.body and (res.body:find("TableNotFound") ~= nil)) then
    local topts = table_clone(oldOpts)
    res = create_table(topts)
    res = request(oldOpts)
  end
  return res
end
return {
  item_create = item_create,
  item_retrieve = item_retrieve,
  item_update = item_update,
  item_delete = item_delete,
  item_list = item_list,
  table_opts = table_opts,
  opts_name = opts_name,
  opts_daily = opts_daily,
  opts_monthly = opts_monthly,
  opts_yearly = opts_yearly,
  request = request
}
