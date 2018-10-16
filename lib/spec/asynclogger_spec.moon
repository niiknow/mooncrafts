aztable     = require "mooncrafts.aztable"
util        = require "mooncrafts.util"
log         = require "mooncrafts.log"
asynclogger = require "mooncrafts.asynclogger"

import string_connection_parse, string_random, to_json from util

import string_connection_parse from util

describe "mooncrafts.asynclogger", ->
  it "dolog should successfully write remote log", ->
    azure_storage = os.getenv("AZURE_STORAGE")

    if (azure_storage)
      azure = string_connection_parse (azure_storage)
      opts = {
        account_name: azure.AccountName,
        account_key: azure.AccountKey
      }
      logger = asynclogger(opts)
      -- do async logger
      rsp = {code: 0, body: 'test', req: { start: 0, end: 0, host: 'unit.test', path: "/asynclogger", logs: {"unit", "test"} }}
      res = logger\dolog(rsp)
      assert.same 201, res.code

