all:
	@echo "Nothing to do"

install:
	install -D -m 644 cmake/FFIWrap.cmake $(DESTDIR)/usr/share/cmake-2.8/Modules/FFIWrap.cmake
	install -D -m 755 make_lua_ffi.pl $(DESTDIR)/usr/bin/make_lua_ffi.pl
