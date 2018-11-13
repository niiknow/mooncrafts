util                  = require "mooncrafts.util"

aws_region            = os.getenv("AWS_DEFAULT_REGION")
aws_access_key_id     = os.getenv("AWS_S3_KEY_ID")
aws_secret_access_key = os.getenv("AWS_S3_ACCESS_KEY")
aws_s3_path           = os.getenv("AWS_S3_PATH") -- 'bucket-name/basepath'

base_host             = os.getenv("BASE_HOST")
remote_path           = os.getenv("REMOTE_PATH")

import string_split, table_clone, string_connection_parse from util
import insert from table
import upper from string

class Config
  new: (newOpts={}) =>
    defaultOpts = {
      :remote_path
      :base_host
      aws: { :aws_region, :aws_access_key_id, :aws_secret_access_key, :aws_s3_path }
    }

    util.applyDefaults(newOpts, defaultOpts)
    @__data = newOpts

  get: () => table_clone(@__data, true) -- preserving config through cloning

Config
