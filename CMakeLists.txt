set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

cmake_minimum_required(VERSION 2.6)
project(lua-ffi-generator C)

set(CMAKE_EXPORT_COMPILE_COMMANDS 1)

include(CheckIncludeFiles)
include(CheckLibraryExists)
include(FindPkgConfig)

find_package(LibClang REQUIRED)

add_executable(ffigen ffigen.c)
target_link_libraries(ffigen ${LIBCLANG_LDFLAGS})
