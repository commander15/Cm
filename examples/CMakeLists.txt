set(Cm_DIR ${CM_ROOT_PATH} CACHE STRING "" FORCE)

find_package(Cm REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Core)

cm_add_package(examples
    NAME         CmExamples
    VERSION      1.2
    CONFIG_FILE  CmExamplesConfig.cmake
    EXPORTS      CmExamplesTargets CmExamplesTargets2
)

cm_add_library(hello hello.cpp)
cm_install(TARGETS hello
    EXPORT  CmExamplesTargets
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
    RUNTIME DESTINATION bin
)

cm_add_executable(hello1 hello.cpp)
cm_add_executable(hello2 hello)
cm_install(TARGETS hello1 hello2
    EXPORT  CmExamplesTargets2
    RUNTIME DESTINATION bin
)

cm_install(PACKAGES examples DESTINATION lib/cmake)
