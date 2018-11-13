VERSION          = 0.4.0
OPENRESTY_PREFIX = /usr/local/openresty
PREFIX          ?= /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR     ?= $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL         ?= install

.PHONY: all install test build local global test-spec clean doc

all: build ;

install: all
	$(INSTALL) -d $(LUA_LIB_DIR)/mooncrafts
	$(INSTALL) lib/mooncrafts/*.* $(LUA_LIB_DIR)/mooncrafts
	$(INSTALL) -d $(LUA_LIB_DIR)/mooncrafts/nginx
	$(INSTALL) lib/mooncrafts/nginx/*.* $(LUA_LIB_DIR)/mooncrafts/nginx
	$(INSTALL) -d $(LUA_LIB_DIR)/mooncrafts/resty
	$(INSTALL) lib/mooncrafts/resty/*.* $(LUA_LIB_DIR)/mooncrafts/resty
	$(INSTALL) -d $(LUA_LIB_DIR)/mooncrafts/vendor
	$(INSTALL) lib/mooncrafts/vendor/*.* $(LUA_LIB_DIR)/mooncrafts/vendor

test-resty: all
	PATH=$(OPENRESTY_PREFIX)/nginx/sbin:$$PATH prove -I../test-nginx/lib -r t

build:
	cd lib && $(MAKE) build

local: build
	luarocks make --force --local mooncrafts-git-1.rockspec

global: build
	sudo luarocks make mooncrafts-git-1.rockspec

test:
	cd lib && $(MAKE) test

clean:
	rm -f *.rock
	rm -f *-0.**.rockspec*
	rm -rf doc/
	rm -rf t/servroot/
	cd lib && $(MAKE) clean

init:
	cd lib && $(MAKE) init

doc:
	cd lib && $(MAKE) doc

upload:
	@rm -f *-0.**.rockspec*
	@sed -e "s/master/$(VERSION)/g" mooncrafts-master-1.rockspec > mooncrafts-$(VERSION)-1.rockspec
	@echo "luarocks upload mooncrafts-$(VERSION)-1.rockspec --api-key=?"
