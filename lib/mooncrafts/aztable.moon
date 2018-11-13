util          = require "mooncrafts.util"
azureauth     = require "mooncrafts.azauth"
mydate        = require "mooncrafts.date"
http          = require "mooncrafts.http"
log           = require "mooncrafts.log"

string_gsub   = string.gsub
my_max_number = 9007199254740991  -- from javascript max safe int

import sharedkeylite, sign from azureauth
import to_json, applyDefaults, trim, table_clone from util

local *

-- generate opts
opts_name = (opts={ :table_name, :pk, :prefix, :account_key, :account_name }) ->
    -- validate account_name and account_key
    assert(opts, "opts parameter is required")
    assert(opts.account_name, "opts.account_name parameter is required")
    assert(opts.account_key, "opts.account_key parameter is required")

    if (opts.prefix == nil)
        opts.prefix = ""

    -- only set if has not set
    if (opts.table == nil)
      opts.table      = string.lower(opts.table_name)
      opts.table_name = "#{opts.prefix}#{opts.table}"

item_headers = (opts, method="GET") ->
  opts_name(opts)
  sharedkeylite(opts)
  hdrs = {
    ["Authorization"]: "SharedKeyLite #{opts.account_name}:#{opts.sig}",
    ["x-ms-date"]: opts.date,
    ["Accept"]: "application/json;odata=nometadata",
    ["x-ms-version"]: "2018-03-28"
  }

  hdrs["Content-Type"] = "application/json" if method == "PUT" or method == "POST" or method == "MERGE"
  hdrs["If-Match"]     = "*" if (method == "DELETE")

  hdrs

-- get table header to create or delete table
table_opts = (opts={ :table_name, :pk, :rk }, method="GET") ->
  headers = item_headers(opts, method)
  url = "https://#{opts.account_name}.table.core.windows.net/#{opts.table_name}"

  -- remove item headers
  headers["If-Match"] = nil if method == "DELETE"

  {
    method: method,
    url: url,
    headers: headers,
    table_name: opts.table_name,
    account_key: opts.account_key,
    account_name: opts.account_name
  }

-- list items
item_list = (opts={ :table_name }, query={ :filter, :top, :select }) ->
  headers = item_headers(opts, "GET")
  url = "https://#{opts.account_name}.table.core.windows.net/#{opts.table_name}"
  qs = ""
  qs = "#{qs}&$filter=#{query.filter}" if query.filter
  qs = "#{qs}&$top=#{query.top}" if query.top
  qs = "#{qs}&$select=#{query.select}" if query.select
  qs = trim(qs, "&")
  full_path = url
  full_path = "#{url}?#{qs}" if qs

  {
    method: 'GET',
    url: full_path,
    headers: headers,
    table_name: opts.table_name,
    account_key: opts.account_key,
    account_name: opts.account_name
  }

-- create an item
item_create = (opts={ :table_name }) ->
  headers = item_headers(opts, "POST")
  url = "https://#{opts.account_name}.table.core.windows.net/#{opts.table_name}"

  {
    method: "POST",
    url: url,
    headers: headers,
    table_name: opts.table_name,
    account_key: opts.account_key,
    account_name: opts.account_name
  }

-- update an item, method can be MERGE to upsert
item_update = (opts={ :table_name, :pk, :rk }, method="PUT") ->
  opts_name(opts)
  table           = "#{opts.table_name}(PartitionKey='#{opts.pk}',RowKey='#{opts.rk}')"
  opts.table_name = table
  headers         = item_headers(opts, method)
  url             = "https://#{opts.account_name}.table.core.windows.net/#{opts.table_name}"

  {
    method: method,
    url: url,
    headers: headers,
    table_name: opts.table_name,
    account_key: opts.account_key,
    account_name: opts.account_name
  }

-- retrieve an item
item_retrieve = (opts={ :table_name, :pk, :rk }) ->
  item_list(opts, { filter: "(PartitionKey eq '#{opts.pk}' and RowKey eq '#{opts.rk}')", top: 1 })

-- delete an item
item_delete = (opts={ :table_name, :pk, :rk }) -> item_update(opts, "DELETE")

generate_opts = (opts={ :table_name }, format="%Y%m%d", ts=os.time()) ->
  newopts          = util.table_clone(opts)
  newopts.mt_table = newopts.table_name

  -- trim ending number and replace with dt
  newopts.table_name = string_gsub(newopts.mt_table, "%d+$", "") .. os.date(format, ts)
  newopts

-- generate array of daily opts
opts_daily = (opts={ :table_name,  :env_id, :pk, :prefix }, days=1, ts=os.time()) ->
  rst        = {}
  multiplier = days and 1 or -1
  new_ts     = ts
  for i = 1, days
    rst[#rst + 1] = generate_opts(opts, "%Y%m%d", new_ts)
    new_ts = mydate.add_day(new_ts, days)

  rst

-- generate array of monthly opts
opts_monthly = (opts={ :table_name, :env_id, :pk, :prefix }, months=1, ts=os.time()) ->
  rst        = {}
  multiplier = days and 1 or -1
  new_ts     = ts
  for i = 1, days
    rst[#rst + 1] = generate_opts(opts, "%Y%m", new_ts)
    new_ts = mydate.add_month(new_ts, months)

  rst

-- generate array of yearly opts
opts_yearly = (opts={ :table_name, :env_id, :pk, :prefix }, years=1, ts=os.time()) ->
  rst        = {}
  multiplier = days and 1 or -1
  new_ts     = ts
  for i = 1, days
    rst[#rst + 1] = generate_opts(opts, "%Y", new_ts)
    new_ts = mydate.add_year(new_ts, years)

  rst

create_table = (opts) ->
  -- log.error opts.table_name
  tableName       = opts.table_name
  opts.table_name = "Tables"
  opts.url        = ""
  opts.headers    = nil
  opts.method     = "POST"
  opts.body       = nil
  topts           = table_opts(opts, opts.method)
  topts.body      = to_json({TableName: tableName})
  -- log.error topts
  http.request(topts)

-- make azure storage request
request = (opts, createTableIfNotExists=false, retry=2) ->
  --log.error(opts)
  oldOpts = table_clone(opts)
  res     = http.request(opts)
  --log.error(res)

  -- exponential retry
  if (retry < 10 and res and res.code >= 500 and res.body and (res.body\find("retry") ~= nil))
    ngx.sleep(retry)
    oopts = table_clone(oldOpts)
    res = request(oopts, createTableIfNotExists, retry * 2)

  if (createTableIfNotExists and res and res.body and (res.body\find("TableNotFound") ~= nil))
    -- log.error res
    topts = table_clone(oldOpts)
    res  = create_table(topts)
    -- log.info topts
    -- log.error res
    res  = request(oldOpts)

  res

{ :item_create, :item_retrieve, :item_update, :item_delete, :item_list, :table_opts
  :opts_name, :opts_daily, :opts_monthly, :opts_yearly, :request
}
