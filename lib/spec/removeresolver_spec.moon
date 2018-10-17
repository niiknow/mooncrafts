remoteresolver = require "mooncrafts.remoteresolver"

describe "mooncrafts.remoteresolver", ->

  it "correctly resolve_remote url", ->
    expected = {
      "authority": 'github.com:443'
      "basepath": '/niiknow/moonship/blob/master/lib/moonship'
      "file": 'remoteresolver.moon'
      "host": 'github.com'
      "port": '443'
      "scheme": 'https'
      "fragment": '!yep'
      "query": "hello=worl%20d",
      "authorativeUrl": "https://github.com:443/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep"
      "fullUrl": "https://github.com/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep"
      "original": "https://github.com/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep"
      "path": "/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon"
      "pathAndQuery": "/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep"
    }
    actual = remoteresolver.resolve_remote("https://github.com/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep")
    assert.same expected, actual


  it "correctly resolve_github url", ->
    expected = {
      "authority": 'raw.githubusercontent.com:443'
      "basepath": '/niiknow/moonship/master/lib/moonship'
      "file": 'remoteresolver.moon'
      'fullUrl': 'https://raw.githubusercontent.com/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep'
      "original": 'https://raw.githubusercontent.com/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep'
      "host": 'raw.githubusercontent.com'
      "path": '/niiknow/moonship/master/lib/moonship/remoteresolver.moon'
      "pathAndQuery": '/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep'
      "github": true
      "port": '443'
      "scheme": 'https'
      "fragment": '!yep'
      "query": "hello=worl%20d"
      "authorativeUrl": "https://raw.githubusercontent.com:443/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep"
    }
    actual = remoteresolver.resolve_github("github.com/niiknow/moonship/blob/master/lib/moonship/remoteresolver.moon?hello=worl%20d#!yep")
    assert.same expected, actual


  it "correctly resolve with _remotebase", ->
    expected = {
      "_remotebase": 'http://noogen.net'
      "authority": 'noogen.net:80'
      "basepath": 'http://noogen.net:80/'
      "file": 'remoteresolver.moon'
      "host": 'noogen.net'
      "path": '/remoteresolver.moon'
      "pathAndQuery": '/remoteresolver.moon?hello=worl%20d#!yep'
      "port": '80'
      "isrelative": true
      "scheme": 'http'
      "fragment": '!yep'
      "query": "hello=worl%20d"
      "original": "http://noogen.net/remoteresolver.moon?hello=worl%20d#!yep"
      "authorativeUrl": "http://noogen.net:80/remoteresolver.moon?hello=worl%20d#!yep"
      "fullUrl": "http://noogen.net/remoteresolver.moon?hello=worl%20d#!yep"
    }
    actual = remoteresolver.resolve("remoteresolver.moon?hello=worl%20d#!yep", {plugins: {_remotebase: "http://noogen.net"}})
    actual.codeloader = nil
    assert.same expected, actual
