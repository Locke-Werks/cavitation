cmake_minimum_required(VERSION 3.24)

project(cavitation
    VERSION 0.1.0
    DESCRIPTION "Cavitation - a native Windows iMessage client"
    LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Qt6 does not ship module interface units; leaving the scanner on makes every
# translation unit pay for a dependency scan that finds nothing.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT WIN32)
    message(FATAL_ERROR "Cavitation currently only builds on Windows.")
endif()

if(MSVC)
    add_compile_options(/W4 /permissive- /utf-8 /Zc:__cplusplus)
    add_compile_definitions(UNICODE _UNICODE NOMINMAX WIN32_LEAN_AND_MEAN)
endif()

include(FetchContent)

FetchContent_Declare(
    Corrosion
    GIT_REPOSITORY https://github.com/corrosion-rs/corrosion.git
    GIT_TAG v0.5.0
    GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(Corrosion)

corrosion_import_crate(
    MANIFEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/rust/Cargo.toml
    PROFILE release
    CRATES whatbubbles_core)

corrosion_add_cxxbridge(whatbubbles_cxx
    CRATE whatbubbles_core
    FILES ffi.rs)

add_subdirectory(app)
