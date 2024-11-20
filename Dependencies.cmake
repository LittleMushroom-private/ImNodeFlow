include(cmake/CPM.cmake)

# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other
# targets
function(ImNodeFlow_setup_dependencies)
  # For each dependency, see if it's
  # already been provided to us by a parent project
  
  set(BUILD_SHARED_LIBS OFF)
  set(GLFW_BUILD_DOCS OFF)
  set(GLFW_INSTALL OFF)

  if(NOT TARGET glfw)
    # cpmaddpackage("gh:glfw/glfw#3.4")
    CPMAddPackage(
      NAME glfw
      GIT_TAG 3.4
      GITHUB_REPOSITORY "glfw/glfw"
      OPTIONS
      "GLFW_BUILD_WAYLAND=1"
      "GLFW_BUILD_X11=1"
    )
  endif()

  if(NOT TARGET imgui)
    find_package(OpenGL REQUIRED)

    # https://github.com/ocornut/imgui.git
    CPMAddPackage(
      NAME imgui
      VERSION 1.91.5
      GITHUB_REPOSITORY "ocornut/imgui"
      OPTIONS
      "GLFW_BUILD_WAYLAND=1"
      "GLFW_BUILD_X11=1"
      "IMGUI_DEFINE_MATH_OPERATORS=1"

      # "CPM_DISABLE_BUILD=ON"
    )
    set(
      IMGUI_SOURCES

      ${imgui_SOURCE_DIR}/imgui.cpp
      ${imgui_SOURCE_DIR}/imgui.h
      ${imgui_SOURCE_DIR}/imconfig.h
      ${imgui_SOURCE_DIR}/imgui_demo.cpp
      ${imgui_SOURCE_DIR}/imgui_draw.cpp
      ${imgui_SOURCE_DIR}/imgui_internal.h
      ${imgui_SOURCE_DIR}/imgui_tables.cpp
      ${imgui_SOURCE_DIR}/imgui_widgets.cpp
    )
    set(
      IMGUI_PLATFORM_SOURCES

      ${imgui_SOURCE_DIR}/backends/imgui_impl_${IMGUI_PLATFORM_BACKEND}.cpp
      ${imgui_SOURCE_DIR}/backends/imgui_impl_${IMGUI_PLATFORM_BACKEND}.h
    )
    set(
      IMGUI_RENDERER_SOURCES

      ${imgui_SOURCE_DIR}/backends/imgui_impl_${IMGUI_RENDERER_BACKEND}.cpp
      ${imgui_SOURCE_DIR}/backends/imgui_impl_${IMGUI_RENDERER_BACKEND}.h
    )

    add_library(
      imgui

      ${IMGUI_SOURCES}
      ${IMGUI_PLATFORM_SOURCES}
      ${IMGUI_RENDERER_SOURCES}
    )
    add_library(imgui::imgui ALIAS imgui)

    target_include_directories(
      imgui

      SYSTEM PUBLIC

      ${imgui_SOURCE_DIR}
      ${imgui_SOURCE_DIR}/backends
      $<$<BOOL:${IMGUI_GLFW_PATH}>:${IMGUI_GLFW_PATH}/include>
    )

    target_link_libraries(
      imgui

      PUBLIC

      glfw
      OpenGL::GL
    )
  endif()
endfunction()
