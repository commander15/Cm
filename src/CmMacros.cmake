if (NOT CM_PLATFORM OR NOT EXISTS ${CMAKE_CURRENT_LIST_DIR}/Cm${CM_PLATFORM}Support.cmake)
    set(CM_PLATFORM Default)
    message(WARNING "Cm couldn't find support platform scripts, fallback to default")
else()
    include(${CMAKE_CURRENT_LIST_DIR}/Cm${CM_PLATFORM}Support.cmake)
endif()

include(${CMAKE_CURRENT_LIST_DIR}/CmDefaultSupport.cmake)

string(TOLOWER ${CM_PLATFORM} platform)

function(cm_add_package name)
    set(options)
    set(oneValueArgs NAME VERSION EXPORT)
    set(multiValueArgs)

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    set(DIR ${CMAKE_CURRENT_BINARY_DIR}/${name}_pkg)
    cm_generate_package_config_file(${DIR}/${ARG_NAME}Config.cmake NAME ${ARG_NAME})
    cm_generate_package_version_file(${DIR}/${ARG_NAME}ConfigVersion.cmake VERSION ${ARG_VERSION})

    add_custom_target(${name}
        SOURCES ${ARG_UNPARSED_ARGUMENTS}
    )

    if (NOT ARG_EXPORT)
        set(ARG_EXPORT ${ARG_NAME}Targets)
    endif()

    set_target_properties(${name} PROPERTIES
        EXPORT_NAME ${ARG_EXPORT}
    )

    cm_register_target(${name} PACKAGE)
endfunction()

function(cm_add_executable name)
    cmake_language(CALL cm_add_${platform}_executable ${name} ${ARGN})
    cm_register_target(${name} EXECUTABLE)
endfunction()

function(cm_add_plugin name)
    set(options QML)
    set(oneValueArgs NAME VERSION GROUP)
    set(multiValueArgs QML_SOURCES CPP_SOURCES EXTRA_FILES)

    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    cmake_language(CALL cm_add_${platform}_plugin ${name}
        ${ARG_QML_SOURCES} ${ARG_CPP_SOURCES}
        ${ARG_EXTRA_FILES} ${ARG_UNPARSED_ARGUMENTS}
    )

    if (NOT ARG_NAME)
        set(ARG_NAME ${name})
    endif()

    if (NOT ARG_VERSION)
        set(ARG_VERSION ${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR})
    endif()

    set(QML_PLUGIN FALSE)
    if (ARG_QML OR ARG_QML_SOURCES)
        set(DIR qml/${ARG_NAME})
        list(APPEND ARG_EXTRA_FILES ${ARG_QML_SOURCES})
        source_group(Qml/files FILES ${ARG_QML_FILES})
        set(QML_PLUGIN TRUE)

        set(QMLDIR ${CMAKE_CURRENT_SOURCE_DIR}/qmldir)
        if (EXISTS ${QMLDIR})
            list(PREPEND ARG_QML_SOURCES ${QMLDIR})
        endif()
    elseif (ARG_GROUP)
        set(DIR plugins/${ARG_GROUP}/${ARG_NAME})
    else()
        set(DIR plugins/${ARG_NAME})
    endif()

    set_target_properties(${name} PROPERTIES
        PLUGIN_NAME    ${ARG_NAME}
        PLUGIN_VERSION ${ARG_VERSION}
        PLUGIN_DIR     "${DIR}"
        PLUGIN_FILES   "${ARG_EXTRA_FILES}"
        QML_PLUGIN     "${QML_PLUGIN}"
        QML_SOURCES    "${ARG_QML_SOURCES}"
    )

    cm_register_target(${name} PLUGIN)
endfunction()

function(cm_add_library name)
    cmake_language(CALL cm_add_${platform}_library ${name} ${ARGN})

    target_include_directories(${name}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/include>
            $<INSTALL_INTERFACE:include>
    )

    cm_register_target(${name} LIBRARY)
endfunction()

function(cm_add_translation name)
    add_custom_target(${name} ALL SOURCES ${ARGN})

    cm_register_target(${name} TRANSLATION)
endfunction()

function(target_headers target)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs PUBLIC PRIVATE)
    cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (ARG_PUBLIC)
        list(TRANSFORM ARG_PUBLIC PREPEND ${CMAKE_CURRENT_SOURCE_DIR}/)

        get_target_property(HEADERS ${target} PUBLIC_HEADER)
        if (NOT HEADERS)
            set_target_properties(${target} PROPERTIES PUBLIC_HEADER "${ARG_PUBLIC}")
        else()
            set_target_properties(${target} PROPERTIES PUBLIC_HEADER "${HEADERS};${ARG_PUBLIC}")
        endif()
    endif()

    if (ARG_PRIVATE)
        list(TRANSFORM ARG_PRIVATE PREPEND ${CMAKE_CURRENT_SOURCE_DIR}/)

        get_target_property(HEADERS ${target} PRIVATE_HEADER)
        if (NOT HEADERS)
            set_target_properties(${target} PROPERTIES PRIVATE_HEADER "${ARG_PRIVATE}")
        else()
            set_target_properties(${target} PROPERTIES PRIVATE_HEADER "${HEADERS};${ARG_PRIVATE}")
        endif()
    endif()
endfunction()
