use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

# repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';
$ENV{TEST_COVERAGE} ||= 0;

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;/usr/local/share/lua/5.1/?.lua;;";
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

=== TEST: 'handle redirect rule' tag.
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local router = require("mooncrafts.resty.router")
			local rules = {}

			rules[1] = {["for"]= "/t/*", status= 302, dest= "https://example.com/foo/:splat"}
			local r = router({name= "data", base= "https://raw.githubusercontent.com/niiknow/mooncrafts/master/data", rules= rules})
			r:handleRequest(ngx)
		}
	}

	# proxy path
	location /__proxy {
		internal;
		set_unescape_uri               	$clean_url "$arg_target";

		proxy_pass                     	$clean_url;
		proxy_cache_key                	$clean_url;

		# small cache to help prevent hammering of backend
		proxy_cache_valid              	any 10s;
	}

--- request
GET /t/bar
--- response_headers
Location: https://example.com/foo/bar
--- response_body_like: 302 Found
--- error_code: 302
