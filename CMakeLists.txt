cmake_minimum_required(VERSION 3.20)

project(Cm
    DESCRIPTION "Commander's CMake Helper for Qt6"
    VERSION     2.0.0
    LANGUAGES   CXX C
)

option(CM_BUILD_EXAMPLES OFF "Build examples")

include(GNUInstallDirs)
set(CM_INSTALL_PATH ${CMAKE_INSTALL_LIBDIR}/cmake/Cm)
set(CM_ROOT_PATH    ${CMAKE_BINARY_DIR}/${CM_INSTALL_PATH})

add_subdirectory(src)

if (CM_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()
