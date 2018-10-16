aztable = require "mooncrafts.aztable"
util    = require "mooncrafts.util"
log     = require "mooncrafts.log"

import string_connection_parse, string_random, to_json from util

import string_connection_parse from util
describe "mooncrafts.aztable", ->
  it "create table if not exists", ->
    azure_storage = os.getenv("AZURE_STORAGE")

    if (azure_storage)
      azure = string_connection_parse (azure_storage)
      opts = {
        table_name: "del1" .. util.string_random(5),
        account_name: azure.AccountName,
        account_key: azure.AccountKey
      }
      newOpts = aztable.item_list(opts)
      newOpts.account_name = opts.account_name
      newOpts.account_key = opts.account_key
      newOpts.table_name = opts.table_name
      res = aztable.request(newOpts, true)
      -- print to_json(res)
      -- delete table
      assert.same 200, res.code
      newOpts.table_name = "Tables('#{opts.table_name}')"
      newOpts = aztable.table_opts(newOpts, "DELETE")
      res = aztable.request(newOpts)
      -- print to_json(res)
      assert.same 204, res.code

