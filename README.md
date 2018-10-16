[![Build Status](https://travis-ci.org/niiknow/mooncrafts.svg?branch=master)](https://travis-ci.org/niiknow/mooncrafts)
# mooncrafts
> Network utilities (crafts) written in moonscript 

Utilities written in moonscript that can be use independently with lua http.server, moonscript, and/or openresty.

# usage
I use it for network stuff.  You can even use it as common util in Function as a Service *FaaS* platform.

TODO

# build and test
osx, install lua/luarocks:
```sh
brew update
brew install lua

sudo luarocks install busted
sudo luarocks install lua-resty-jwt
sudo luarocks install lua-resty-http
sudo luarocks install moonscript
sudo luarocks install luacrypto
sudo luarocks install basexx
sudo luarocks install lua-log

make install
make test
```

# MIT
