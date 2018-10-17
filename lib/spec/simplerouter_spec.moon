simplerouter = require "mooncrafts.simplerouter"

describe "mooncrafts.simplerouter", ->

  it "correctly parse headers", ->
    expected = {
        'X-Token': 'fake'
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

