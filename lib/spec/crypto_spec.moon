crypto = require "mooncrafts.crypto"

describe "mooncrafts.crypto", ->

  it "correctly encode base64", ->
    expected = "aGVsbG8gd29ybGQ="
    actual = crypto.base64_encode("hello world")

    assert.same expected, actual

  it "correctly decode base64", ->
    expected = "hello world"
    actual = crypto.base64_decode("aGVsbG8gd29ybGQ=")

    assert.same expected, actual

  it "correctly hash md5", ->
    expected = "XrY7u+Ae7tCTyyK7j1rNww=="
    actual = crypto.base64_encode(crypto.md5("hello world").digest())

    assert.same expected, actual

    actual = crypto.md5("hello world").hex()
    expected = "5eb63bbbe01eeed093cb22bb8f5acdc3"
    assert.same expected, actual

  it "correctly hash sha1", ->
    expected = "Kq5sNclPz7QV2+lfQIuc6R7oRu0="
    actual = crypto.base64_encode(crypto.sha1("hello world").digest())

    assert.same expected, actual

    actual = crypto.sha1("hello world").hex()
    expected = "2aae6c35c94fcfb415dbe95f408b9ce91ee846ed"
    assert.same expected, actual

  it "correctly hash sha256", ->
    expected = "uU0nuZNNPgilLlLX2n2r+sSE7+N6U4DukIj3rOLvzek="
    actual = crypto.base64_encode(crypto.sha256("hello world").digest())

    assert.same expected, actual

    actual = crypto.sha256("hello world").hex()
    expected = "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
    assert.same expected, actual

it "correctly encrypt md5", ->
    expected = "rpLPUa35ETATCu/Cs5p1lQ=="
    actual = crypto.base64_encode(crypto.hmac("key", "hello world", crypto.md5).digest())

    assert.same expected, actual

    actual = crypto.hmac("key", "hello world", crypto.md5).hex()
    expected = "ae92cf51adf91130130aefc2b39a7595"
    assert.same expected, actual

it "correctly encrypt sha1", ->
    expected = "NN0jS5JoNZNWBSj2GT6mjIAF9hU="
    actual = crypto.base64_encode(crypto.hmac("key", "hello world", crypto.sha1).digest())

    assert.same expected, actual

    actual = crypto.hmac("key", "hello world", crypto.sha1).hex()
    expected = "34dd234b92683593560528f6193ea68c8005f615"
    assert.same expected, actual

it "correctly encrypt sha256", ->
    expected = "C6BvH5pjAEYeQ0VFNdw8QiPkex01cHPXU26ukOwJW+E="
    actual = crypto.base64_encode(crypto.hmac("key", "hello world", crypto.sha256).digest())

    assert.same expected, actual

    actual = crypto.hmac("key", "hello world", crypto.sha256).hex()
    expected = "0ba06f1f9a6300461e43454535dc3c4223e47b1d357073d7536eae90ec095be1"
    assert.same expected, actual
