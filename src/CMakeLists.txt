cmake_minimum_required (VERSION 3.16)

option (USE_CLANG_TIDY "Enable clang-tidy at build time" ON)
if (USE_CLANG_TIDY)
	find_program (CLANG_TIDY 
			NAMES
				"clang-tidy"
				"clang-tidy-9"
				"clang-tidy-10" 
				"clang-tidy-11" 
				"clang-tidy-12" 
				"clang-tidy-13" 
				"clang-tidy-14"
	)
	if (NOT CLANG_TIDY)
		MESSAGE(WARNING "USE_CLANG_TIDY is ON but no clang-tidy executable found.")
		SET (CMAKE_CXX_CLANG_TIDY "")
	else ()
		# '-checks' will be sourced from the .clang-tidy file
		set (CMAKE_CXX_CLANG_TIDY
			"${CLANG_TIDY}"
			-header-filter=ImNodeFlow*.h
			-format-style=file
		)
		MESSAGE(STATUS "USE_CLANG_TIDY is on and CLANG_TIDY is ${CLANG_TIDY}, command line is ${CMAKE_CXX_CLANG_TIDY}")
	endif ()
endif ()

add_library(ImNodeFlow)
target_sources(ImNodeFlow
    PUBLIC
    ImNodeFlow.cpp
    # {CMAKE_SOURCE_DIR}/include/ImNodeFlow.h
	ImNodeFlow.h
)

target_include_directories(
	ImNodeFlow

	SYSTEM PUBLIC

	${CMAKE_CURRENT_SOURCE_DIR}
)

target_include_directories(
	ImNodeFlow

	PRIVATE

	${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(
	ImNodeFlow

	PUBLIC

	imgui
)

if (MSVC)
	string (REGEX REPLACE "/EH[a-z]+-?" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
	set (IMGW_NO_EXCEPTIONS /EHc-)
	set (IMGW_ALL_WARNINGS  /W3)
	set (IMGW_NO_RTTI /GR-)
elseif (CMAKE_CXX_COMPILER_ID MATCHES "Clang|GNU")
	set (IMGW_NO_EXCEPTIONS -fno-exceptions)
	set (IMGW_ALL_WARNINGS  -Wall -Werror -Wextra -Wpedantic)
	set (IMGW_NO_RTTI -fno-rtti)
else ()
	message (WARNING "CMAKE_CXX_FLAGS not set for compiler ${CMAKE_CXX_COMPILER_ID}")
endif ()

#target_compile_options(ImNodeFlow PRIVATE ${IMGW_NO_RTTI} ${IMGW_NO_EXCEPTIONS} ${IMGW_ALL_WARNINGS})
