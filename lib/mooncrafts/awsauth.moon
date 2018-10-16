-- derived from https://github.com/paragasu/lua-resty-aws-auth
-- modified to use our own crypto

import sort, concat from table
crypto = require "mooncrafts.crypto"
util   = require "mooncrafts.util"
log    = require "mooncrafts.log"

class AwsAuth
  new: (options={}) =>
    defOpts = {
      timestamp: os.time(), aws_host: "s3.amazonaws.com", aws_region: "us-east-1",
      aws_service: "s3", content_type: "application/x-www-form-urlencoded", request_method: "GET",
      request_path: "/", request_body: "", aws_secret_access_key: "", aws_access_key_id: ""
    }

    util.applyDefaults(options, defOpts)
    options.iso_date        = os.date("!%Y%m%d", options.timestamp)
    options.iso_tz          = os.date("!%Y%m%dT%H%M%SZ", options.timestamp)
    @options = options

  -- create canonical headers
  -- header must be sorted asc
  get_canonical_header: () =>
    concat { "content-type:" .. @options.content_type, "host:" .. @options.aws_host, "x-amz-date:" .. @options.iso_tz }, "\n"

  get_signed_request_body: () =>
    params = @options.request_body
    if type(@options.request_body) == "table"
      sort(params)
      params = util.query_string_encode(params)

    digest = @get_sha256_digest(params or "")
    string.lower(digest) -- hash must be in lowercase hex string

  -- get canonical request
  -- https://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html
  get_canonical_request: () =>
    param  = {
      @options.request_method,
      @options.request_path,
      "", -- canonical query string
      @get_canonical_header(),
      "", -- content body?
      "content-type;host;x-amz-date",
      @get_signed_request_body()
    }
    canonical_request = concat(param, "\n")
    @get_sha256_digest(canonical_request)

  -- generate sha256 from the given string
  get_sha256_digest: (s) => crypto.sha256(s).hex()
  hmac: (secret, message) => crypto.hmac(secret, message, crypto.sha256)

  -- get signing key
  -- https://docs.aws.amazon.com/general/latest/gr/sigv4-calculate-signature.html
  get_signing_key: () =>
    k_date    = @hmac("AWS4" .. @options.aws_secret_access_key, @options.iso_date).digest()
    k_region  = @hmac(k_date, @options.aws_region).digest()
    k_service = @hmac(k_region, @options.aws_service).digest()
    @hmac(k_service, "aws4_request").digest()

  -- get string
  get_string_to_sign: () =>
    param = { @options.iso_date, @options.aws_region, @options.aws_service, "aws4_request" }
    cred  = concat(param, "/")
    req   = @get_canonical_request()
    concat({ "AWS4-HMAC-SHA256", @options.iso_tz, cred, req }, "\n")

  -- generate signature
  get_signature: () => @hmac(@get_signing_key(), @get_string_to_sign()).hex()

  -- get authorization string
  -- x-amz-content-sha256 required by s3
  get_auth_header: () =>
    param = { @options.aws_access_key_id, @options.iso_date, @options.aws_region, @options.aws_service, "aws4_request" }
    concat { "AWS4-HMAC-SHA256 Credential=" .. concat(param, "/"), "SignedHeaders=content-type;host;x-amz-date", "Signature=" .. @get_signature() }, ", "

  get_auth_headers: () =>
    { "Authorization": @get_auth_header(), "x-amz-date": @get_date_header(), "x-amz-content-sha256": @get_content_sha256(), "Content-Type": @options.content_type }

  -- get the current timestamp in iso8601 basic format
  get_date_header: () => @options.iso_tz
  get_content_sha256: () => @get_sha256_digest("")

AwsAuth
