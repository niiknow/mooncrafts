
url = require "mooncrafts.url"
json = require "cjson"

tests = {
  {
    "simple '/'"
    ->
      url.compile_pattern '/'

    {
      original: '/',
      params: { },
      pattern: "^/?$"
    }
  }
  {
    "simple splat '/*'"
    ->
      url.compile_pattern '/*'

    {
      original: "/*",
      params: { "splat" },
      pattern: "^/(.-)/?$"
    }
  }
  {
    "complex splat '/:foo/:bar'"
    ->
      url.compile_pattern '/:foo/:bar'

    {
      original: '/:foo/:bar',
      params: { "foo", "bar" },
      pattern: "^/([^/?&#]+)/([^/?&#]+)/?$"
    }
  }
  {
    "complex splat '/foo/bar/:baz'"
    ->
      url.compile_pattern '/foo/bar/:baz'

    {
      original: '/foo/bar/:baz',
      params: { "baz" },
      pattern: "^/foo/bar/([^/?&#]+)/?$"
    }
  }
  {
    "match '/say/:msg/to/:to?who=:friend'"
    ->
      url.compile_pattern '/say/:msg/to/:to?who=:friend'

    {
      original: '/say/:msg/to/:to?who=:friend',
      params: { "msg", "to", "friend" },
      pattern: "^/say/([^/?&#]+)/to/([^/?&#]+)%?who=([^/?&#]+)/?$"
    }

    ->
      rst = url.compile_pattern('/say/:msg/to/:to?who=:friend')
      url.match(rst, "/say/hello/to/my?who=little-friend")

    {
      friend: 'little-friend',
      msg: 'hello',
      to: 'my'
    }
  }
  {
    "match '/say/*/to/*'"
    ->
      url.compile_pattern '/say/*/to/*'

    {
      original: '/say/*/to/*',
      params: { "splat", "splat" },
      pattern: "^/say/(.-)/to/(.-)/?$"
    }
  }
  {
    "match '/:foo.:bar'"
    ->
      url.compile_pattern '/:foo.:bar'

    {
      original: '/:foo.:bar',
      params: { "foo", "bar" },
      pattern: "^/([^/?&#]+)%.([^/?&#]+)/?$"
    }

    ->
      rst = url.compile_pattern('/:foo.:bar')
      url.match(rst, "/tom@example.com")

    {
      bar: 'com',
      foo: 'tom@example'
    }
  }

  {
    "parsing url 'https://hi:ho@example.com:443/hello/?cruel=world#yes'"
    ->
      url.parse 'https://hi:ho@example.com:443/hello/?cruel=world#yes'

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
}

describe "mooncrafts.url #only", ->
  for group in *tests
    it "should match " .. group[1], ->
      input = group[2]!
      assert.same input, group[3]
      if #group > 4
        -- test
        match, data = group[4]!
        assert.same data, group[5]
        assert.same match, true
