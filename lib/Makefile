
.PHONY: test build watch clean

test: build
	busted -c spec

build:
	moonc mooncrafts

watch: build
	moonc -w mooncrafts

clean: build
	rm $$(find ./ | grep \.lua$$)
	rm -rf ./t/localhost
	mkdir -p ./t/localhost

init:
	sudo luarocks install busted
	sudo luarocks install lua-resty-jwt
	sudo luarocks install lua-resty-http
	sudo luarocks install moonscript
	sudo luarocks install luacrypto
	sudo luarocks install basexx
	sudo luarocks install lua-log
	sudo luarocks install lua-cjson
	sudo luarocks install luasocket
	sudo luarocks install --server=http://luarocks.org/dev ltn12
	sudo luarocks install luasec OPENSSL_DIR=/usr/local/opt/openssl
	# uncomment these if require lua "http.server"
	# sudo luarocks install cqueues CRYPTO_DIR=/usr/local/opt/openssl OPENSSL_DIR=/usr/local/opt/openssl
	# sudo luarocks install http CRYPTO_DIR=/usr/local/opt/openssl OPENSSL_DIR=/usr/local/opt/openssl

doc: clean
	ldoc .
