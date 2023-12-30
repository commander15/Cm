function(cm_init)
    set(SUPPORTS)

    if (Qt6Qml_FOUND)
        list(APPEND SUPPORTS QML_SUPPORT)
    endif()

    if (Qt6Core_FOUND)
        list(APPEND SUPPORTS QT_SUPPORT)
    endif()

    cm_init_project(${CMAKE_PROJECT_NAME} CMAKE_SUPPORT ${SUPPORTS})

    set(CM_GENERATION ON
        CACHE BOOL
        "Enable Install Directory Structure replication in binary dir"
    )
endfunction()

function(cm_init_project name)
    set(options CMAKE_SUPPORT QML_SUPPORT QT_SUPPORT)
    set(oneValueArgs)
    set(multiValueArgs)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (ARG_CMAKE_SUPPORT)
        set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_LIBRARY_OUTPUT_DIRECTORY}/lib)
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
    endif()

    if (ARG_QML_SUPPORT)
        set(CMAKE_AUTORCC ON)
        set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/qml)

        set(ARG_QT_SUPPORT ON)

        qt_policy(SET QTP0001 NEW)
    endif()

    if (ARG_QT_SUPPORT)
        set(CMAKE_AUTOMOC ON)
    endif()

    if (ARG_ANDROID_SUPPORT)
        qt_policy(SET QTP0000 NEW)
    endif()
endfunction()

include(${CMAKE_CURRENT_LIST_DIR}/CmTargetsMacros.cmake)
