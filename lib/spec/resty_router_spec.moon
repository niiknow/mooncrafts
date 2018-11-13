crypto  = require "mooncrafts.crypto"
util    = require "mooncrafts.util"
rrouter = require "mooncrafts.resty.router"

base64_encode   = crypto.base64_encode

describe "mooncrafts.resty.router", ->

  it "correctly parse redirects", ->
    expected = {
        'test': 1
    }

    opts = {
        "rules": {
            {
                "for": '/hello/world'
                "dest": '/go/team'
                "status": 302
                "headers": {
                    'test': 1
                }
            }
            {
                "for": 'http://test.com:80/hello/world'
                "dest": '/never/get/here'
                "status": 302
                "headers": {
                    'X-Token': 'fake'
                }
            }
            {
                "for": '/hello'
                "dest": '/go/team3'
                "status": 200
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

    router = rrouter(opts)
    actual = router\parseRedirects(req)
    assert.same '/go/team', actual.target
    assert.same true, actual.isRedir

    req = {
        "url": 'http://test.com:80/hello/world',
        headers: {}
    }

    router = rrouter(opts)
    actual = router\parseRedirects(req)
    assert.same '/go/team', actual.target
    assert.same true, actual.isRedir

    req = {
        "url": '/hello',
        headers: {}
    }
    router = rrouter(opts)
    actual = router\parseRedirects(req)
    assert.same '/go/team3', actual.target
    assert.same true, actual.isRedir


    req = {
        "url": '/hi',
        headers: {}
    }
    router = rrouter(opts)
    actual = router\parseRedirects(req)
    assert.same false, actual.isRedir
