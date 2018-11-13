use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

# repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';
$ENV{TEST_COVERAGE} ||= 0;

our $HttpConfig = qq{
  	lua_package_path "$pwd/lib/?.lua;/usr/local/opt/openresty/luajit/share/lua/5.1/?.lua;;";
  	lua_package_cpath "/usr/local/opt/openresty/luajit/lib/lua/5.1/?.so;;";
    error_log logs/error.log debug;

    init_by_lua_block {
        if $ENV{TEST_COVERAGE} == 1 then
            jit.off()
            require("luacov.runner").init()
        end
    }

    resolver $ENV{TEST_NGINX_RESOLVER};
};

no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST: 'liquid include remote file' tag.
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local Liquid   = require("mooncrafts.resty.liquid")
			local Remotefs = require("mooncrafts.remotefs")
			local fs = Remotefs({base = "https://raw.githubusercontent.com/niiknow/mooncrafts/master/data/public/"})
			local engine = Liquid(fs)
			-- this is line 47 which is 15 lines too far
      local var = {
        ["aa"] =  "-----",
        ["bb"] = { ["cc"] = "======" }
      }
			ngx.say(engine:renderView("index.liquid", var))
		}
	}

	# proxy pass to user lib
	location /__mooncrafts {
		internal;
		set_unescape_uri               	$clean_url "$arg_target";

		proxy_pass                     	$clean_url;
		proxy_cache_key                	$clean_url;

		# small cache to help prevent hammering of backend
		proxy_cache_valid              	any 10s;
	}

--- request
GET /t
--- response_body
abc-----defg 12345======6789  123456789 bar
--- no_error_log
[error]



=== TEST: 'headers experimental' tag.
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
		  local util   = require("mooncrafts.util")
			ngx.say(util.to_json(ngx.req.get_headers()))
		}
	}

--- raw_request eval
"GET /t  HTTP/1.0
Authorization: Basic asdf:basdf
X-Token: testxyz



"
--- response_body
{"x-token":"testxyz","authorization":"Basic asdf:basdf"}
--- no_error_log
[error]

