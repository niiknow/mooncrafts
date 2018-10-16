[![Build Status](https://travis-ci.org/niiknow/mooncrafts.svg?branch=master)](https://travis-ci.org/niiknow/mooncrafts)
# mooncrafts
> Network http utilities (crafts) written in moonscript 

Utilities written in moonscript that can be use independently with lua http.server, moonscript, and/or openresty.

# usage
A set of classes from [moonship](https://github.com/niiknow/moonship) for re-usability.  Originally inspired by webscript.io provided utility functions.

# build and test
osx, install lua/luarocks and openssl then:
```sh
sudo luarocks install luasec OPENSSL_DIR=/usr/local/opt/openssl
make init
make test
```

# MIT
