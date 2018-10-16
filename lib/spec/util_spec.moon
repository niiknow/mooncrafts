
util = require "mooncrafts.util"
json = require "cjson"

tests = {
  {
    ->
      util.url_escape "fly me=to"

    "fly%20me%3Dto"
  }

  {
    ->
      util.url_unescape "fly%20me%3dto"

    "fly me=to"
  }

  {
    ->
      util.url_parse "https://hi:ho@example.com:443/hello/?cruel=world#yes"

    {
      "authority": 'example.com:443',
      "fragment": 'yes',
      "user": "hi"
      "password": "ho",
      "host": 'example.com',
      "path": '/hello/',
      "port": '443',
      "query": 'cruel=world',
      "scheme": 'https'
    }
  }

  {
    ->
      util.url_build {
        "authority": 'example.com:443',
        "fragment": 'yes',
        "host": 'example.com',
        "path": '/hello/',
        "port": '443',
        "query": 'cruel=world',
        "scheme": 'https'
      }

    "https://example.com:443/hello/?cruel=world#yes"
  }

  {
    -> util.trim "ho ly    cow"
    "ho ly    cow"
  }

  {
    -> util.trim "
      blah blah          "
    "blah blah"
  }

  {
    -> util.trim "   hello#{" "\rep 20000}world "
    "hello#{" "\rep 20000}world"
  }


  {
    -> util.path_sanitize "tHis//is Some///crazy./../path//?asdf"
    "tHis/isSome/crazy./path/?asdf"
  }

  {
    -> util.slugify "What is going on right now?"
    "what-is-going-on-right-now"
  }

  {
    -> util.slugify "whhaa  $%#$  hooo"
    "whhaa-hooo"
  }

  {
    -> util.slugify "what-about-now"
    "what-about-now"
  }

  {
    -> util.slugify "hello - me"
    "hello-me"
  }

  {
    -> util.slugify "cow _ dogs"
    "cow-dogs"
  }


  {
    ->
      util.from_json '{"color": "blue", "data": { "height": 10 }}'

    {
      color: "blue", data: { height: 10}
    }
  }

  { -- stripping invalid types
    ->
      json.decode util.to_json {
        color: "blue"
        data: {
          height: 10
          fn: =>
        }
      }

    {
      color: "blue", data: { height: 10}
    }
  }

  -- do not handle numerical index, must be key value pair
  {
    ->
      util.query_string_encode {
        {"first", "arg"}
        "hello[cruel]": "wor=ld"
      }

    "1=nil&hello%5Bcruel%5D=wor%3Dld"
  }

  {
    ->
      util.query_string_encode {
        {"cold", "day"}
        "in": true
        "hell": false
      }

    "1=nil&hell=false&in=true"
  }

  {
    ->
      util.query_string_encode {
        "ignore_me": false
      }

    "ignore_me=false"
  }

  {
    ->
      util.query_string_encode {
        "show_me": true
      }

    "show_me=true"
  }
}

describe "mooncrafts.util", ->
  for group in *tests
    it "should match", ->
      input = group[1]!
      if #group > 2
        assert.one_of input, { unpack group, 2 }
      else
        assert.same input, group[2]

  it "should generate random string", ->
    actual = util.string_random(5)
    assert.same 5, string.len(actual)
