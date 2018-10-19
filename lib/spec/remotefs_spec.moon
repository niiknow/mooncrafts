remotefs = require "mooncrafts.remotefs"

describe "mooncrafts.remotefs", ->

  it "can download remote file with relative url", ->
    fs = remotefs()
    content = fs\read("/niiknow/mooncrafts/master/dist.ini")

    assert.same true, content\find("repo_link") > 1

  it "return default on error", ->
    fs = remotefs()
    content = fs\read("/niiknow/mooncrafts/master/error", "empty")

    assert.same "empty", content

  it "can return remote file with absolute url", ->
    fs = remotefs()
    content = fs\read("https://raw.githubusercontent.com/niiknow/mooncrafts/master/dist.ini")

    assert.same true, content\find("repo_link") > 1
