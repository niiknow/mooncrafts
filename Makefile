VERSION          = 0.3.1
OPENRESTY_PREFIX = /usr/local/openresty
PREFIX          ?= /usr/local
LUA_INCLUDE_DIR ?= $(PREFIX)/include
LUA_LIB_DIR     ?= $(PREFIX)/lib/lua/$(LUA_VERSION)
INSTALL         ?= install

.PHONY: all install test build local global test-spec clean doc

all: build ;

install: all
	$(INSTALL) -d $(DESTDIR)/$(LUA_LIB_DIR)/mooncrafts
	$(INSTALL) lib/mooncrafts/*.* $(DESTDIR)/$(LUA_LIB_DIR)/mooncrafts
	$(INSTALL) lib/mooncrafts/nginx/*.* $(DESTDIR)/$(LUA_LIB_DIR)/mooncrafts/nginx

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
	rm -rf doc/
	rm -rf t/servroot/

init:
	cd lib && $(MAKE) init

doc:
	cd lib && $(MAKE) doc

upload:
	@rm -f *-0.**.rockspec*
	@sed -e "s/git\-1/$(VERSION)\-1/g" mooncrafts-git-1.rockspec > mooncrafts-$(VERSION)-1.rockspec
	@echo "luarocks upload mooncrafts-$(VERSION)-1.rockspec --api-key=?"
