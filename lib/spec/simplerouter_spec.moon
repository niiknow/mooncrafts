crypto = require "mooncrafts.crypto"
simplerouter = require "mooncrafts.simplerouter"

base64_encode   = crypto.base64_encode

describe "mooncrafts.simplerouter", ->

  it "correctly parse with no basic auth", ->
    expected = {headers: {}}

    opts = {}

    req = {
        "url": 'http://test.com:80/hello/world',
        "headers": {
          "authorization": ""
        }
    }

    router = simplerouter(opts)
    actual = router\parseBasicAuth(req)
    assert.same expected, actual

  it "correctly parse with basic auth", ->
    expected = {
      code: 401,
      headers: {["Content-Type"]: "text/plain", ["WWW-Authenticate"]: 'realm="Access to site.", charset="UTF-8"'},
      body: "Please auth!"
    }

    opts = {
      basic_auth: "john:doe"
    }

    req = {
        "url": 'http://test.com:80/hello/world',
        "headers": {}
    }

    router = simplerouter(opts)
    actual = router\parseBasicAuth(req)
    assert.same expected, actual

    -- test bad auth
    expected = {
      code: 401,
      headers: {["Content-Type"]: "text/plain"},
      body: "Your browser sent a bad Authorization HTTP header!"
    }

    req = {
        "url": 'http://test.com:80/hello/world',
        "headers": {
          "authorization": "asdf"
        }
    }

    router = simplerouter(opts)
    actual = router\parseBasicAuth(req)
    assert.same expected, actual

    -- test bad auth2
    expected = {
      code: 403,
      headers: {["Content-Type"]: "text/plain", ["WWW-Authenticate"]: 'realm="Access to site.", charset="UTF-8"'},
      body: "Auth failed!"
    }

    req = {
        "url": 'http://test.com:80/hello/world',
        "headers": {
          "authorization": "Basic " .. base64_encode('john:asdf')
        }
    }

    router = simplerouter(opts)
    actual = router\parseBasicAuth(req)
    assert.same expected, actual

    -- test good auth
    expected = {headers: {}}

    req = {
        "url": 'http://test.com:80/hello/world',
        "headers": {
          "authorization": "Basic " .. base64_encode('john:doe')
        }
    }

    router = simplerouter(opts)
    actual = router\parseBasicAuth(req)
    assert.same expected, actual

  it "correctly parse headers of path only", ->
    expected = {
        'test': 1
    }

    opts = {
        "headers": {
            {
                "source": '/hello/world',
                "headers": {
                    'test': 1
                }
            }
            {
                "source": 'http://test.com:80/hello/world',
                "headers": {
                    'X-Token': 'fake'
                }
            }
            {
                "source": '/hello',
                "headers": {
                    'X-TokenReal': true
                }
            }
        }
    }

    req = {
        "url": '/hello/world'
    }

    router = simplerouter(opts)
    actual = router\parseHeaders(req)
    assert.same expected, actual.headers

  it "correctly parse headers of full url", ->
    expected = {
        'X-Token': 'fake',
        'test': 1
    }

    opts = {
        "headers": {
            {
                "source": '/hello/world',
                "headers": {
                    'test': 1
                }
            }
            {
                "source": 'http://test.com:80/hello/world',
                "headers": {
                    'X-Token': 'fake'
                }
            }
            {
                "source": '/hello',
                "headers": {
                    'X-TokenReal': true
                }
            }
        }
    }

    req = {
        "url": 'http://test.com:80/hello/world'
    }

    router = simplerouter(opts)
    actual = router\parseHeaders(req)
    assert.same expected, actual.headers

  it "correctly parse headers of path only", ->
    expected = {
        'test': 1
    }

    opts = {
        "headers": {
            {
                "source": '/hello/world',
                "headers": {
                    'test': 1
                }
            }
            {
                "source": 'http://test.com:80/hello/world',
                "headers": {
                    'X-Token': 'fake'
                }
            }
            {
                "source": '/hello',
                "headers": {
                    'X-TokenReal': true
                }
            }
        }
    }

    req = {
        "url": '/hello/world'
    }

    router = simplerouter(opts)
    actual = router\parseHeaders(req)
    assert.same expected, actual.headers

  it "correctly parse redirects", ->
    expected = {
        'test': 1
    }

    opts = {
        "redirects": {
            {
                "source": '/hello/world',
                "dest": '/go/team',
                "status": 302,
                "headers": {
                    'test': 1
                }
            }
            {
                "source": 'http://test.com:80/hello/world',
                "dest": '/go/team2',
                "status": 302,
                "headers": {
                    'X-Token': 'fake'
                }
            }
            {
                "source": '/hello',
                "dest": '/go/team3',
                "status": 200,
                "headers": {
                    'X-TokenReal': true
                }
            }
        },
        headers: {}
    }

    req = {
        "url": '/hello/world',
        headers: {}
    }

    router = simplerouter(opts)
    actual = router\parseRedirects(req)
    assert.same '/go/team', actual.target
    assert.same true, actual.isRedir

    req = {
        "url": 'http://test.com:80/hello/world',
        headers: {}
    }

    router = simplerouter(opts)
    actual = router\parseRedirects(req)
    assert.same '/go/team', actual.target
    assert.same true, actual.isRedir

    req = {
        "url": '/hello',
        headers: {}
    }
    router = simplerouter(opts)
    actual = router\parseRedirects(req)
    assert.same '/go/team3', actual.target
    assert.same false, actual.isRedir
