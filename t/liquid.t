use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

# repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
	lua_package_path "$pwd/lib/?.lua;;;";
	lua_package_cpath "/usr/local/openresty/lualib/?.so;;";
};


no_long_string();
#no_diff();

run_tests();

__DATA__

=== TEST 1: 'if elsif else endif' tag.
--- http_config eval: $::HttpConfig
--- config
	location /t {
		content_by_lua_block {
			local Liquid   = require("mooncrafts.resty.liquid")
			local Remotefs = require("mooncrafts.remotefs")
			local fs = Remotefs({base: "https://raw.githubusercontent.com/niiknow/mooncrafts/master/data/"})
			local engine = Liquid(fs)
			liquid.render("index.liquid")
		}
	}
--- request
GET /t
--- response_body
 abc

--- no_error_log
[error]
