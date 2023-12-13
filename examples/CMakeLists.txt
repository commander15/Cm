set(Cm_DIR ${CMAKE_BINARY_DIR}/lib/cmake/Cm)

find_package(Cm REQUIRED COMPONENTS QtWidgets QtQuick QtLinguist)

find_package(Qt5 REQUIRED COMPONENTS ${CmQtModules})

cm_add_package(exp
    NAME    CmExample
    VERSION 1.0
)

#add_subdirectory(widgetapp)
add_subdirectory(qmlapp)
add_subdirectory(coreapp)

add_subdirectory(qmlplugin)

cm_install(PACKAGE exp DESTINATION lib/cmake)

macro(show_prop prop target)
    get_target_property(val ${target} ${prop})
    message("${target}[${prop}] = ${val}")
endmacro()

show_prop(TYPE qmlapp)
