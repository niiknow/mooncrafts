use Test::Nginx::Socket;
use Cwd qw(cwd);

plan tests => repeat_each() * (blocks() * 3);

my $pwd = cwd();

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';
$ENV{TEST_COVERAGE} ||= 0;
$ENV{LETSENCRYPT_URL} = 'https://acme-staging.api.letsencrypt.org/directory';
$ENV{AWS_DEFAULT_REGION} = 'us-east-2';

our $HttpConfig = qq{
	  lua_package_path "$pwd/lib/?.lua;/usr/local/opt/openresty/luajit/share/lua/5.1/?.lua;;";
	  lua_package_cpath "/usr/local/opt/openresty/luajit/lib/lua/5.1/?.so;;";
	  error_log logs/error.log debug;

	  init_by_lua_block {
	      if $ENV{TEST_COVERAGE} == 1 then
	          jit.off()
	          require("luacov.runner").init()
	      end
	      router_cache = require "mooncrafts.resty.routercache"
	  }

	  resolver $ENV{TEST_NGINX_RESOLVER};
};

no_long_string();

run_tests();

__DATA__
=== TEST 1: fail website setup
--- main_config
env LETSENCRYPT_URL;
env AWS_DEFAULT_REGION;
env AWS_S3_KEY_ID;
env AWS_S3_ACCESS_KEY;
env AWS_S3_PATH;

--- http_config eval: $::HttpConfig
--- config

				set $__sitename '';

			  location = /err {
						content_by_lua_block {
							local engine = require "mooncrafts.nginx.contentblock"
							engine.engage("test")
						}
			  }

			  location /__proxy {
						internal;
						set_unescape_uri               	$clean_url "$arg_target";

						proxy_pass                     	$clean_url;
						proxy_cache_key                	$clean_url;

						# small cache to help prevent hammering of backend
						proxy_cache_valid              	any 10s;
						proxy_pass_request_headers      off;
				}
--- request
GET /err
--- response_body
failed to fetch website configuration file, status: 404
--- error_code: 500
--- no_error_log
[error]


=== TEST 2: successful hello content
--- main_config
env LETSENCRYPT_URL;
env AWS_DEFAULT_REGION;
env AWS_S3_KEY_ID;
env AWS_S3_ACCESS_KEY;
env AWS_S3_PATH;

--- http_config eval: $::HttpConfig
--- config

				set $__sitename '';

			  location = /hello {
						content_by_lua_block {
							local engine = require "mooncrafts.nginx.contentblock"
							engine.engage("localhost")
						}
			  }

			  location /__proxy {
						internal;
						set_unescape_uri               	$clean_url "$arg_target";

						proxy_pass                     	$clean_url;
						proxy_cache_key                	$clean_url;

						# small cache to help prevent hammering of backend
						proxy_cache_valid              	any 10s;
						proxy_pass_request_headers      off;
				}
--- request
GET /hello
--- response_body
abcdefg
--- no_error_log
[error]
