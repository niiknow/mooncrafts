remoteresolver = require "mooncrafts.remoteresolver"

describe "mooncrafts.remoteresolver", ->

  it "correctly resolve_remote url", ->
    expected = {
      "authority": 'github.com:443'
      "basepath": '/niiknow/mooncrafts/blob/master/lib/mooncrafts'
      "file": 'remoteresolver.moon'
      "host": 'github.com'
      "port": '443'
      "scheme": 'https'
      "fragment": '#!yep'
      "query": "hello=worl%20d",
      "sign_url": "https://github.com:443/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep"
      "full_url": "https://github.com/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep"
      "original": "https://github.com/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep"
      "path": "/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon"
      "path_and_query": "/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep"
    }
    actual = remoteresolver.resolve_remote("https://github.com/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep")
    assert.same expected, actual


  it "correctly resolve_github url", ->
    expected = {
      "authority": 'raw.githubusercontent.com:443'
      "basepath": '/niiknow/mooncrafts/master/lib/mooncrafts'
      "file": 'remoteresolver.moon'
      'full_url': 'https://raw.githubusercontent.com/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep'
      "original": 'https://raw.githubusercontent.com/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep'
      "host": 'raw.githubusercontent.com'
      "path": '/niiknow/mooncrafts/master/lib/mooncrafts/remoteresolver.moon'
      "path_and_query": '/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep'
      "github": true
      "port": '443'
      "scheme": 'https'
      "fragment": '#!yep'
      "query": "hello=worl%20d"
      "sign_url": "https://raw.githubusercontent.com:443/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep"
    }
    actual = remoteresolver.resolve_github("github.com/niiknow/mooncrafts/blob/master/lib/mooncrafts/remoteresolver.moon?hello=worl%20d#!yep")
    assert.same expected, actual


  it "correctly resolve with _remotebase", ->
    expected = {
      "_remotebase": 'http://noogen.net'
      "authority": 'noogen.net:80'
      "basepath": 'http://noogen.net:80/'
      "file": 'remoteresolver.moon'
      "host": 'noogen.net'
      "path": '/remoteresolver.moon'
      "path_and_query": '/remoteresolver.moon?hello=worl%20d#!yep'
      "port": '80'
      "isrelative": true
      "scheme": 'http'
      "fragment": '#!yep'
      "query": "hello=worl%20d"
      "original": "http://noogen.net/remoteresolver.moon?hello=worl%20d#!yep"
      "sign_url": "http://noogen.net:80/remoteresolver.moon?hello=worl%20d#!yep"
      "full_url": "http://noogen.net/remoteresolver.moon?hello=worl%20d#!yep"
    }
    actual = remoteresolver.resolve("remoteresolver.moon?hello=worl%20d#!yep", {plugins: {_remotebase: "http://noogen.net"}})
    actual.codeloader = nil
    assert.same expected, actual
