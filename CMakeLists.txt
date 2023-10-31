cmake_minimum_required(VERSION 3.20)

project(Cm
    VERSION 1.0.0
)

option(CM_BUILD_EXAMPLES "Build examples" OFF)

add_subdirectory(src)

if (CM_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

