
url = require "mooncrafts.url"
json = require "cjson"

tests = {

  {
    "parsing url 'https://hi:ho@example.com:443/hello/?cruel=world#yes'"
    ->
      url.parse 'https://hi:ho@example.com:443/hello/?cruel=world#yes'

    {
      "authority": 'example.com:443',
      "fragment": 'yes',
      "user": "hi",
      "password": "ho",
      "host": 'example.com',
      "path": '/hello/',
      "pathAndQuery": '/hello/?cruel=world#yes',
      "port": '443',
      "query": 'cruel=world',
      "scheme": 'https',
      "fullUrl": 'https://example.com/hello/?cruel=world#yes',
      "original": 'https://hi:ho@example.com:443/hello/?cruel=world#yes',
      "authorativeUrl": 'https://example.com:443/hello/?cruel=world#yes'
    }
  }

  {
    "parsing url '/hello/?cruel=world#yes'"
    ->
      url.parse '/hello/?cruel=world#yes', true

    {
      "fragment": 'yes'
      "path": '/hello/'
      "pathAndQuery": '/hello/?cruel=world#yes'
      "query": 'cruel=world'
      "port": '443'
      "original": '/hello/?cruel=world#yes'
    }
  }

  {
    "simple '/'"
    ->
      url.compile_pattern '/'

    {
      original: '/',
      params: { },
      pattern: "/$"
    }
  }

  {
    "simple splat '/*'"
    ->
      url.compile_pattern '/*'

    {
      original: "/*",
      params: { "splat" },
      pattern: "/(.-)"
    }
  }

  {
    "complex splat '/:foo/:bar'"
    ->
      url.compile_pattern '/:foo/:bar'

    {
      original: '/:foo/:bar',
      params: { "foo", "bar" },
      pattern: "/([^/?&#]+)/([^/?&#]+)$"
    }
  }

  {
    "complex full splat 'https://www.example.com:443/foo/bar/*'"
    ->
      url.compile_pattern 'https://www.example.com:443/foo/bar/*'

    {
      original: 'https://www.example.com:443/foo/bar/*',
      params: { "splat" },
      pattern: "https://www%.example%.com:443/foo/bar/(.-)"
    }
  }

  {
    "complex splat '/foo/bar/:baz'"
    ->
      url.compile_pattern '/foo/bar/:baz'

    {
      original: '/foo/bar/:baz',
      params: { "baz" },
      pattern: "/foo/bar/([^/?&#]+)$"
    }
  }
  {
    "splat in query '/say/:msg/to/:to?who=:friend'"
    ->
      url.compile_pattern '/say/:msg/to/:to?who=:friend'

    {
      original: '/say/:msg/to/:to?who=:friend',
      params: { "msg", "to", "friend" },
      pattern: "/say/([^/?&#]+)/to/([^/?&#]+)%?who=([^/?&#]+)$"
    }

    ->
      rst = url.compile_pattern('/say/:msg/to/:to?who=:friend')
      url.match_pattern("/say/hello/to/my?who=little-friend", rst)

    {
      friend: 'little-friend',
      msg: 'hello',
      to: 'my'
    }
  }
  {
    "multiple splat '/say/*/to/*'"
    ->
      url.compile_pattern '/say/*/to/*'

    {
      original: '/say/*/to/*',
      params: { "splat", "splat" },
      pattern: "/say/(.-)/to/(.-)"
    }
  }

  {
    "replacement '/:foo.:bar'"
    ->
      url.compile_pattern '/:foo.:bar'

    {
      original: '/:foo.:bar',
      params: { "foo", "bar" },
      pattern: "/([^/?&#]+)%.([^/?&#]+)$"
    }

    ->
      rst = url.compile_pattern('/:foo.:bar')
      url.match_pattern("/tom@example.com", rst)

    {
      bar: 'com',
      foo: 'tom@example'
    }
  }

  {
    "build_with_splats '/:foo.:bar'"
    ->
      rst = url.compile_pattern('/:foo.:bar')
      match, params = url.match_pattern("/tom@example.com", rst)
      url.build_with_splats('https://example.com:443/hi/:bar.:foo', params)

    "https://example.com:443/hi/com.tom@example"
  },

  {
    "path only matching '/:foo.:bar?hi=you'"
    ->
      url.compile_pattern '/:foo.:bar?hi=you'

    {
      original: '/:foo.:bar?hi=you',
      params: { "foo", "bar" },
      pattern: "/([^/?&#]+)%.([^/?&#]+)%?hi=you$"
    }
    ->
      rst = url.compile_pattern('/:foo.:bar?hi=you')
      url.match_pattern("https://www.google.com:443/tom@example.com?hi=you", rst)

    {
      bar: 'com',
      foo: 'tom@example'
    }
  }
}

describe "mooncrafts.url #only", ->
  for group in *tests
    it "should match " .. group[1], ->
      input = group[2]!
      assert.same group[3], input
      if #group > 4
        -- test
        match, data = group[4]!
        assert.same group[5], data
        assert.same true, match
