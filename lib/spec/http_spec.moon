http = require "mooncrafts.http"

describe "mooncrafts.http", ->

  it "correctly phone home", ->
    expected = 200
    opts = {
      url: "https://niiknow.github.io/"
    }
    rsp = http.request opts

    assert.same expected, rsp.code
