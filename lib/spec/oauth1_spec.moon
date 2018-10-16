oauth1 = require "mooncrafts.oauth1"

describe "mooncrafts.oauth1", ->

  it "correctly generate signature", ->
    expected = 'OAuth oauth_consumer_key="consumerkey",oauth_nonce="8ccc8816600bbdfa706f80c087d59fe2",oauth_signature="EPNT6V4q0NGb%2FrUf6ANxQCVobww%3D",oauth_signature_method="HMAC-SHA1",oauth_timestamp="1499097288",oauth_token="accesstoken",oauth_version="1.0"'
    opts = {
        url: 'https://example.com/hello?world'
    }
    oauth = {
        consumerkey: 'consumerkey',
        consumersecret: 'consumersecret',
        accesstoken: 'accesstoken',
        tokensecret: 'tokensecret',
        timestamp: 1499097288
    }
    actual = oauth1.create_signature opts, oauth
    assert.same expected, actual

