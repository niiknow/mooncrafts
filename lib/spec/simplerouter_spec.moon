simplerouter = require "mooncrafts.simplerouter"

describe "mooncrafts.simplerouter", ->

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
