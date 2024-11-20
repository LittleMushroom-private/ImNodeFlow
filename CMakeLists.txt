cmake_minimum_required(VERSION 3.26)

if (NOT DEFINED CMAKE_CXX_STANDARD)
set (IMNODEFLOW_CXX_STANDARD "20" CACHE STRING "Specify the C++ standard to use (must be 17 or higher")

set (CMAKE_CXX_STANDARD "${IMNODEFLOW_CXX_STANDARD}")
endif()

# strongly encouraged to enable this globally to avoid conflicts between
# -Wpedantic being enabled and -std=c++20 and -std=gnu++20 for example
# when compiling with PCH enabled
set(CMAKE_CXX_EXTENSIONS on)

set (IMNODEFLOW_BACKEND "GL3W" CACHE STRING "Specify the imgui backend")
if (IMNODEFLOW_BACKEND STREQUAL "GL3W")
add_compile_definitions(IMGUI_IMPL_OPENGL_LOADER_GL3W)
endif ()

set (IMGUI_PLATFORM_BACKEND "glfw" CACHE STRING "Specify which imgui platform backend to use")
set (IMGUI_RENDERER_BACKEND "opengl3" CACHE STRING "Specify which imgui renderer backend to use")

project (ImNodeFlow
VERSION 0.1.1
DESCRIPTION ""
HOMEPAGE_URL "https://github.com/LittleMushroom-private/ImNodeFlow"
LANGUAGES CXX C
)

add_compile_definitions(IMGUI_DEFINE_MATH_OPERATORS)

include(cmake/PreventInSourceBuilds.cmake)
include(ProjectOptions.cmake)


ImNodeFlow_setup_options()

ImNodeFlow_global_options()
include(Dependencies.cmake)
ImNodeFlow_setup_dependencies()

ImNodeFlow_local_options()

# Are we standalone?
if ("${CMAKE_SOURCE_DIR}" STREQUAL "${CMAKE_CURRENT_SOURCE_DIR}")
set(IMNODEFLOW_STANDALONE TRUE)
endif()

add_subdirectory(src)
