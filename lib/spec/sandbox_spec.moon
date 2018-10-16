sandbox = require "mooncrafts.sandbox"

describe "mooncrafts.sandbox", ->

  it "correctly load good function", ->
    expected = "hello world"
    fn = sandbox.loadstring "return \"hello world\""
    actual = fn!
    assert.same expected, actual

  it "fail to load bad function", ->
    expected = nil
    actual = sandbox.loadstring "asdf"
    assert.same expected, actual

  it "fail to execute restricted function", ->
    expected = "ffail"
    data = "local function hi()\n"
    data ..= "  return 'hello world'\n"
    data ..= "end\nreturn string.dump(hi)"
    ignore, actual = sandbox.exec_code data, expected
    hasMatch = actual\match(expected)

    -- actual is error message
    assert.same expected, hasMatch

  it "correctly execute good function", ->
    expected = "hello world"
    fn = sandbox.loadstring_safe "return string.gsub('hello cruel world', 'cruel ', '')"
    actual = fn!
    assert.same expected, actual


  it "correctly pass in global variables", ->
    expected = "hello world"
    env = sandbox.build_env(_G, {test: expected }, sandbox.whitelist)
    fn = sandbox.loadstring "return _G.test", "test", env
    actual = fn!
    assert.same expected, actual

