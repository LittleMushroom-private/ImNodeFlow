include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(ImNodeFlow_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(ImNodeFlow_setup_options)
  option(ImNodeFlow_ENABLE_HARDENING "Enable hardening" ON)
  option(ImNodeFlow_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    ImNodeFlow_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    ImNodeFlow_ENABLE_HARDENING
    OFF)

  ImNodeFlow_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR ImNodeFlow_PACKAGING_MAINTAINER_MODE)
    option(ImNodeFlow_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(ImNodeFlow_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(ImNodeFlow_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(ImNodeFlow_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(ImNodeFlow_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(ImNodeFlow_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(ImNodeFlow_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(ImNodeFlow_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(ImNodeFlow_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(ImNodeFlow_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(ImNodeFlow_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(ImNodeFlow_ENABLE_PCH "Enable precompiled headers" OFF)
    option(ImNodeFlow_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(ImNodeFlow_ENABLE_IPO "Enable IPO/LTO" ON)
    # produce warning: optimization flag '-fno-fat-lto-objects' is not supported
    # option(ImNodeFlow_ENABLE_IPO "Enable IPO/LTO" OFF)
    # option(ImNodeFlow_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    # suppress warning as error above
    option(ImNodeFlow_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(ImNodeFlow_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(ImNodeFlow_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(ImNodeFlow_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(ImNodeFlow_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(ImNodeFlow_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(ImNodeFlow_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(ImNodeFlow_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(ImNodeFlow_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(ImNodeFlow_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(ImNodeFlow_ENABLE_PCH "Enable precompiled headers" OFF)
    option(ImNodeFlow_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      ImNodeFlow_ENABLE_IPO
      ImNodeFlow_WARNINGS_AS_ERRORS
      ImNodeFlow_ENABLE_USER_LINKER
      ImNodeFlow_ENABLE_SANITIZER_ADDRESS
      ImNodeFlow_ENABLE_SANITIZER_LEAK
      ImNodeFlow_ENABLE_SANITIZER_UNDEFINED
      ImNodeFlow_ENABLE_SANITIZER_THREAD
      ImNodeFlow_ENABLE_SANITIZER_MEMORY
      ImNodeFlow_ENABLE_UNITY_BUILD
      ImNodeFlow_ENABLE_CLANG_TIDY
      ImNodeFlow_ENABLE_CPPCHECK
      ImNodeFlow_ENABLE_COVERAGE
      ImNodeFlow_ENABLE_PCH
      ImNodeFlow_ENABLE_CACHE)
  endif()

  ImNodeFlow_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (ImNodeFlow_ENABLE_SANITIZER_ADDRESS OR ImNodeFlow_ENABLE_SANITIZER_THREAD OR ImNodeFlow_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(ImNodeFlow_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(ImNodeFlow_global_options)
  if(ImNodeFlow_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    ImNodeFlow_enable_ipo()
  endif()

  ImNodeFlow_supports_sanitizers()

  if(ImNodeFlow_ENABLE_HARDENING AND ImNodeFlow_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR ImNodeFlow_ENABLE_SANITIZER_UNDEFINED
       OR ImNodeFlow_ENABLE_SANITIZER_ADDRESS
       OR ImNodeFlow_ENABLE_SANITIZER_THREAD
       OR ImNodeFlow_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${ImNodeFlow_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${ImNodeFlow_ENABLE_SANITIZER_UNDEFINED}")
    ImNodeFlow_enable_hardening(ImNodeFlow_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(ImNodeFlow_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(ImNodeFlow_warnings INTERFACE)
  add_library(ImNodeFlow_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  ImNodeFlow_set_project_warnings(
    ImNodeFlow_warnings
    ${ImNodeFlow_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(ImNodeFlow_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    ImNodeFlow_configure_linker(ImNodeFlow_options)
  endif()

  include(cmake/Sanitizers.cmake)
  ImNodeFlow_enable_sanitizers(
    ImNodeFlow_options
    ${ImNodeFlow_ENABLE_SANITIZER_ADDRESS}
    ${ImNodeFlow_ENABLE_SANITIZER_LEAK}
    ${ImNodeFlow_ENABLE_SANITIZER_UNDEFINED}
    ${ImNodeFlow_ENABLE_SANITIZER_THREAD}
    ${ImNodeFlow_ENABLE_SANITIZER_MEMORY})

  set_target_properties(ImNodeFlow_options PROPERTIES UNITY_BUILD ${ImNodeFlow_ENABLE_UNITY_BUILD})

  if(ImNodeFlow_ENABLE_PCH)
    target_precompile_headers(
      ImNodeFlow_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(ImNodeFlow_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    ImNodeFlow_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(ImNodeFlow_ENABLE_CLANG_TIDY)
    ImNodeFlow_enable_clang_tidy(ImNodeFlow_options ${ImNodeFlow_WARNINGS_AS_ERRORS})
  endif()

  if(ImNodeFlow_ENABLE_CPPCHECK)
    ImNodeFlow_enable_cppcheck(${ImNodeFlow_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(ImNodeFlow_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    ImNodeFlow_enable_coverage(ImNodeFlow_options)
  endif()

  if(ImNodeFlow_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(ImNodeFlow_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(ImNodeFlow_ENABLE_HARDENING AND NOT ImNodeFlow_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR ImNodeFlow_ENABLE_SANITIZER_UNDEFINED
       OR ImNodeFlow_ENABLE_SANITIZER_ADDRESS
       OR ImNodeFlow_ENABLE_SANITIZER_THREAD
       OR ImNodeFlow_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    ImNodeFlow_enable_hardening(ImNodeFlow_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
