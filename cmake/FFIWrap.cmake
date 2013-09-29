
if(NOT MAKE_LUA_FFI)
	set(MAKE_LUA_FFI "/usr/bin/make_lua_ffi.pl")
endif()

macro(ffi_lua_gen target_name in_headers lualib_gen_dir subfolder extra_flags install_dest)

	string(REGEX MATCHALL "[^ ]+" project_compile_flags "${CMAKE_C_FLAGS}")
	get_property(defs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY COMPILE_DEFINITIONS)
	foreach(def ${defs})
		list(APPEND project_compile_flags "-D${def}")
	endforeach()
	get_property(dirs DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} PROPERTY INCLUDE_DIRECTORIES)
	foreach(dir ${dirs})
		list(APPEND project_compile_flags "-I${dir}")
	endforeach()

	set(flags "")
	foreach(flag ${project_compile_flags})
		set(flags "${flags} ${flag}")
	endforeach()

	set(lua_outputs)
	foreach(in_header ${in_headers})
		get_filename_component(header_filename ${in_header} NAME)
		string(REGEX REPLACE "[.]h" "" header_basefilename ${header_filename})
		if(subfolder STREQUAL "")
			set(lua_output "${lualib_gen_dir}/${header_basefilename}_h.lua")
		else()
			set(lua_output "${lualib_gen_dir}/${subfolder}/${header_basefilename}_h.lua")
		endif()
		list(APPEND lua_outputs ${lua_output})
	endforeach()
	add_custom_command(OUTPUT ${lua_outputs}
		COMMAND "${MAKE_LUA_FFI}"
		"-cc" "${CMAKE_C_COMPILER}"
		"-cflags" ${flags}
		"-out_dir" "${lualib_gen_dir}/${subfolder}"
		${extra_flags}
		${in_headers}
		DEPENDS ${in_headers}
		)
	add_custom_target(${target_name} ALL DEPENDS ${lua_outputs})
	if(NOT install_dest STREQUAL "")
		install(FILES ${lua_outputs} DESTINATION ${install_dest})
	endif()
endmacro()

