CMAKE_ROOT=$(shell cmake --system-information | grep CMAKE_ROOT | cut -d' ' -f2 | tr -d '"')

all:
	@echo "Nothing to do"

install:
	install -D -m 644 cmake/FFIWrap.cmake $(DESTDIR)$(CMAKE_ROOT)/Modules/FFIWrap.cmake
	install -D -m 755 make_lua_ffi.pl $(DESTDIR)/usr/bin/make_lua_ffi.pl
